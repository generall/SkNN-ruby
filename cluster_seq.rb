require 'rubygems'
require 'bundler/setup'

require 'rgl/adjacency'
require 'rgl/dot'
require 'set'
require 'json'
require 'k_means'

require_relative 'reader.rb'
require_relative 'dataset.rb'

# Clusterisation of sequences 
# TODO: Hierarchical clustering
module SkNN
  class SeqClusterer

    attr_accessor :datasets 
    def initialize()
      @state = :init
      @datasets = Hash.new { |hash, key| hash[key] = Dataset.new }
      @seq_id = 0
      @distance_function = :euclidean_distance
      @sequences = []
      @last_seq_obj = nil
      @schema = Set.new
    end

    def load(fname)
      CSVReader.new(fname).read_stream.each{ |x| process_row(x) }
    end

    def process_row(row)
      if row
        tag    = row[:tag]
        values = row[:features]
        values.each do |field, val|
          @schema.add field
        end

        @last_seq_obj = @datasets[@state].add_obj(@state, tag, values, @seq_id, @last_seq_obj)
        @sequences.push @last_seq_obj if @state == :init
        @state = tag
      else
        @last_seq_obj = nil
        @seq_id += 1
        @state = :init
      end
    end

    def dump(fname, additional_mapping = [:cluster, :tag])
      mapping = @schema.to_a + additional_mapping
      CSV.open(fname, "wb") do |csv|
        @sequences.each do |sequence_start|
          si = sequence_start
          while si != nil do
            csv << mapping.map { |idx| si.props[idx] }
            si = si.next
          end
          csv << []
        end
      end
    end

    def cluster_array(dataset, vertex = nil, centroids = 2)

      vertex = vertex || dataset.vertex_objects.first.first;
      data = dataset.enum().map(&:itself)
      objects = dataset.vertex_objects[vertex]

      kmeans = KMeans.new(data, :centroids => centroids, :distance_measure => @distance_function)

      clusters = kmeans.view
      clusters.each.with_index do |cluster, cluster_id|
        cluster.each do |object_id|
          objects[object_id].props.merge!( {:cluster => cluster_id } )
        end
      end

    end

    def cluster(fname)
    end

  end
end

