require 'rubygems'
require 'bundler/setup'

require 'rgl/adjacency'
require 'rgl/dot'
require 'set'
require 'json'
require 'k_means'


require_relative 'reader.rb'
require_relative 'dataset.rb'

# module for model of Structured kNN sequence tagger
module SkNN
  # TODO remove
  # Graph of the model
  class ModelGraph
    attr_accessor :graph, :rev_graph
    def initialize
      @graph = RGL::DirectedAdjacencyGraph.new
      @rev_graph = RGL::DirectedAdjacencyGraph.new
    end

    def render(fname = "graph.png")
      @graph.write_to_graphic_file('png')
    end

    def add_edge(a, b)
      graph.add_edge(a, b)
      rev_graph.add_edge(b, a)
    end

  end

  # Model class
  class Model
    attr_accessor :label_vertex_map ,:output_vertex_map, :vertex_output_map ,:vertex_dataset ,:graph ,:curr_vertex ,:seq_n, :seq_objects


    def dump()
      @label_vertex_map.default_proc = nil
      @output_vertex_map.default_proc = nil
      @vertex_output_map.default_proc = nil
      @vertex_dataset.default_proc = nil
      @seq_objects.default_proc = nil
      @vertex_dataset.values.each {|ds| ds.remove_default_proc!}
      return Marshal.dump(self)
    end

    def self.load(dump)
      return Marshal.load(dump)
    end

    def initialize
      @label_vertex_map = Hash.new { |hash, key| hash[key] = hash.size }
      @output_vertex_map = Hash.new { |hash, key| hash[key] = Set.new }
      @vertex_output_map = Hash.new { |hash, key| hash[key] = Set.new }
      @vertex_dataset = Hash.new { |hash, key| hash[key] = Dataset.new }
      @seq_objects = Hash.new { |hash, key| hash[key] = Array.new }
      @graph = ModelGraph.new

      @graph.graph.add_vertex(0)
      @graph.graph.add_vertex(1)
      @label_vertex_map[:end]
      @label_vertex_map[:init]
      @vertex_output_map[:init]
      @curr_vertex = 1
      @seq_n = 0
    end

    def get_vertex(label)
      return @label_vertex_map[label]
    end

    def get_label(vertex)
      return @label_vertex_map.select {|a,b| b == vertex}.first.first
    end


    def enum(selector = nil)
      return Enumerator.new do |y|
        if selector == nil
          @vertex_dataset.values.uniq.each do |dataset|
            dataset.enum().to_a.uniq.each do |row|
              y << row
            end
          end
        else
          raise "Not implemented"
        end
      end
    end

    def get_graph_map
      nodes = @graph.graph.vertices.map do |vert|
        {
          id: vert,
          name: get_label(vert),
          value: 1
        }
      end
      links = @graph.graph.edges.map do |edge|
        {
          source: edge.source,
          target: edge.target
        }
      end
      return { nodes: nodes,
               edges: links.select{ |x| x[:source] != x[:target] },
               loops: links.select{ |x| x[:source] == x[:target] }
               }
    end

    def cluster_loops(vertex, centroids = 2)
      dataset = @vertex_dataset[vertex]
      data = dataset.enum(vertex: vertex).map{|x| x}

      objects = dataset.vertex_objects[vertex]

      # customize clusters here
      kmeans = KMeans.new(data, :centroids => centroids, :distance_measure => :euclidean_distance)

      clusters = kmeans.view
      # create #{centroids} new vertexes, which will have same external links as original one
      # rewrite dataset
      # => rewrite vertexes
      # => repack
      # assign dataset and links

      adj_vert = graph.graph.adjacent_vertices(0) - [vertex]
      output = @vertex_output_map[vertex]
      label = get_label(vertex)

      vertices = []
      datasets = {}

      clusters.each.with_index do |cluster, idx|
        cl_label  = "#{label}_#{idx}"
        cl_vertex = @graph.graph.vertices.count
        @label_vertex_map[cl_label] = cl_vertex
        output.each do |tag|
          @output_vertex_map[tag].add cl_vertex
          @vertex_output_map[cl_vertex].add tag
        end
        @vertex_output_map[vertex] = output
        vertices.push cl_vertex

        # naive separation, make better in future

        cluster.each do |elem_idx|
          objects[elem_idx].props[:vertex] = cl_vertex
        end
        vertices.push cl_vertex
        cl_dataset = Dataset.new
        cl_dataset.schema = dataset.schema
        datasets[cl_vertex] = cl_dataset
        @graph.graph.add_vertex(cl_vertex)
      end


      # initial A translation is not in dataset

      # -> A
      # => A_0
      # => A_0
      # => A_1
      # => B
      dataset.objects.each do |obj|
        if obj.prev
          prev_vertex = obj.prev.props[:vertex]
          cl_vertex = obj.props[:vertex]

          if vertices.include?(prev_vertex)
            # arived from new vertex
            cl_dataset = datasets[prev_vertex]
            cl_dataset.objects.push(obj)
            cl_dataset.vertex_objects[cl_vertex].push(obj)
            cl_dataset.sequence_objects[obj.props[:seq]].push(obj)
            dataset.vertex_objects[cl_vertex].push(obj)
            @graph.add_edge(prev_vertex, cl_vertex)
          end

          if prev_vertex == vertex
            @graph.add_edge(prev_vertex, cl_vertex)
          end

        end
      end

      vertices.each do |vert|
        @vertex_dataset[vert] = datasets[vert]
      end

      # do not link to self anymore
      dataset.vertex_objects.delete(vertex)
      graph.graph.remove_edge(vertex, vertex)

    end

    def learn(fname)
      @curr_vertex = 1
      CSVReader.new(fname).read_stream.each { |x| process_row(x) }
      @curr_vertex = 1
      @seq_n += 1
    end

    def process_row(row)
      if row == nil
        @graph.add_edge(@curr_vertex, 0)
        # add go-to-end signal
        @vertex_dataset[@curr_vertex].add_obj(0, :end, {}, @seq_n)
        @curr_vertex = 1
        @seq_n += 1
      else
        tag    = row[:tag]
        values = row[:features]

        vertex = @label_vertex_map[tag]

        # vertex to output is many to many
        @output_vertex_map[tag   ].add vertex
        @vertex_output_map[vertex].add tag

        @graph.add_edge(@curr_vertex, vertex)
        obj = @vertex_dataset[@curr_vertex].add_obj(vertex, tag, values, @seq_n)
        @seq_objects[@seq_n].push obj
        @curr_vertex = vertex
      end
    end
  end

end
