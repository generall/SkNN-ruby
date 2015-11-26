require 'rubygems'
require 'bundler/setup'
require 'knn'


require_relative 'model.rb'
require_relative 'preprocessor.rb'

require 'ruby-prof'

module SkNN
  class Tagger

    attr_accessor :model

    def initialize
      @model = Model.new
    end

    def learn(fname)
      @model.learn(fname)
    end

    def viretbi(sequence, k = 1)
      # TODO: Add path saving
      v = []
      path = []

      v << Hash.new { |hash, key| hash[key] = Float::INFINITY }

      v.last[1] = 0 # at fitst step only :init (1) vertex is accessible with dist = 0

      sequence.each.with_index do |object, idx|
        prev = v.last
        curr = Hash.new { |hash, key| hash[key] = Float::INFINITY }
        curr_path = Hash.new { |hash, key| hash[key] = nil }
        nearest_v = Hash.new { |hash, key| hash[key] = nil }

        # determine all accesible vertex on step idx
        accesible_vertecies = Set.new
        prev.each do |vertex, dist|
          if dist != Float::INFINITY
            ds = @model.vertex_dataset[vertex]
            @model.graph.graph.adjacent_vertices(vertex).each do |next_vertex|
              nearest_object = nil
              #p "#{vertex} -> #{next_vertex}"
              if object.class == Symbol
                case object
                when :init
                  obj_dist = 0
                when :end
                  obj_dist = @model.get_label(next_vertex) == :end ? 0 : Float::INFINITY
                end
              else
                knn = KNN.new(ds.enum(vertex: next_vertex))
                nearest = knn.nearest_neighbours(object, k)
                if nearest.size == 0
                  next
                else
                  nearest_object = ds.vertex_objects[next_vertex][nearest[0][0]]
                  obj_dist = nearest.reduce(0){ |sum, x| sum + x[1]} / nearest.size.to_f # calc average dist
                end
              end
              if !obj_dist
                binding.pry # something goes wrong
              end
              next if obj_dist == Float::INFINITY
              d = dist + obj_dist
              if d < curr[next_vertex]
                curr[next_vertex] = d
                curr_path[next_vertex] = [vertex, nearest_object]
              end
            end
          end
        end


        v << curr
        path << curr_path
      end

      return [v, path]
    end


    def tagg(data, k)
      v, path = viretbi([:init] + data + [:end], k)
      curr_node = 0
      output   = []
      vertices = []
      nearest  = []
      path.reverse.each do |l|
        curr_node, near = l[curr_node]
        vertices.push curr_node
        nearest.push near
        output.push @model.vertex_output_map[curr_node].first rescue "wtf"
      end
      vertices.reverse!
      nearest.reverse!
      output.reverse!
      return [output, vertices, nearest]
    end

    def tag(data, k = 1)
      output, vertices, nearest = tagg(data, k)
      return output[1..-2]
    end


    def make_model(files, model_file = "model.dat", do_norm = true, centroids = 5)
      
      files.each do |fname|
        learn(fname)
      end

      if do_norm
        pp = Preproc.new
        pp.seq_normalization(@model)
      end

      nodes = @model.vertex_dataset.keys.sort

      if centroids
        nodes[1..-1].each do |vertex|
          @model.cluster_loops(vertex , centroids)
        end
      end

      #@model.graph.render

      dump = @model.dump

      File.write(model_file, dump)

    end

    def classify(test_file, model_file = "model.dat", do_norm = true, k = 1)
      @model = Model.load( File.read( model_file ) )
      td = TargetData.new(test_file)

      if do_norm
        pp = Preproc.new
        pp.td_norm(td)
      end

      #@model.graph.render


      td.data.map do |num, td_seq|
        tag(td_seq, k)
      end

    end

  end


  if __FILE__ == $PROGRAM_NAME


    tagger = Tagger.new
    #tagger.learn(ARGV[0])
    #model = tagger.model
    #model.cluster_loops(2)
    #td = TargetData.new("data/pen_test.csv")
    #v, vertices, nearest = tagger.tagg(td.data[0])
    #pp = Preproc.new
    #tagger.make_model(ARGV, "model.dat", true, 36)
    #tagger.model.graph.render

    #exit 0
    res = tagger.classify(ARGV[0], "model.dat", true, 3).map{|x| x[0]}


    ethalon = ["s0", "s0", "s0", "s0", "s1", "s1", "s1", "s1", "s2", "s2", "s2", "s2", "s3", "s3", "s3", "s3", "s4", "s4", "s4", "s4", "s5", "s5", "s5", "s5", "s6", "s6", "s6", "s6", "s7", "s7", "s7", "s7", "s8", "s8", "s8", "s8", "s9", "s9"]
    
    p res

    err = res.zip(ethalon).select{|x, y| x != y}

    binding.pry
  end

end
