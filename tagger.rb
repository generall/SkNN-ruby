require 'rubygems'
require 'bundler/setup'
require 'knn'

require_relative 'model.rb'

module SkNN
  class Tagger

    attr_accessor :model

    def initialize
      @model = Model.new
    end

    def learn(fname)
      @model.learn(fname)
    end

    def viretbi(sequence)
      v = []
      v << Hash.new { |hash, key| hash[key] = Float::INFINITY }
      v.last[1] = 0 # at fitst step only :init (1) vertex is accessible with dist = 0

      sequence.each.with_index do |object, idx|
        prev = v.last
        curr = Hash.new { |hash, key| hash[key] = Float::INFINITY }

        # determine all accesible vertex on step idx
        accesible_vertecies = Set.new
        prev.each do |vertex, dist|
          if dist != Float::INFINITY
            ds = @model.vertex_dataset[vertex]
            @model.graph.graph.adjacent_vertices(vertex).each do |next_vertex|

              p "#{vertex} -> #{next_vertex}"
              if object.class == Symbol
                case object
                when :init
                  obj_dist = 0
                when :end
                  obj_dist = @model.get_label(next_vertex) == :end ? 0 : Float::INFINITY
                end
              else
                knn = KNN.new(ds.enum(vertex: next_vertex))
                nearest = knn.nearest_neighbours(object, 1)
                if nearest.size == 0
                  next
                else
                  obj_dist = nearest[0][1]
                end
              end
              if !obj_dist
                binding.pry
              end
              d = dist + obj_dist
              if d < curr[next_vertex]
                curr[next_vertex] = d
              end
            end
          end
        end


        v << curr
      end

      return v
    end

  end

  if __FILE__ == $PROGRAM_NAME
    tagger = Tagger.new
    tagger.learn(ARGV[0])
    model = tagger.model
    model.cluster_loops(2)
    binding.pry
  end

end
