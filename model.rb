require 'rgl/adjacency'
require 'rgl/dot'
require 'set'
require 'json'
require_relative 'reader.rb'

# module for model of Structured kNN sequense tagger
module SkNN
  # Graph of the model
  class ModelGraph
    attr_accessor :graph
    def initialize
      @graph = RGL::DirectedAdjacencyGraph.new
    end

    def render(fname = "graph.png")
      @graph.write_to_graphic_file('png')
    end

  end

  # Model class
  class Model
    attr_accessor :label_vertex_map ,:output_vertex_map, :vertex_output_map ,:vertex_dataset ,:graph ,:curr_vertex ,:seq_n


    def dump()
      @label_vertex_map.default_proc = nil
      @output_vertex_map.default_proc = nil
      @vertex_output_map.default_proc = nil
      @vertex_dataset.default_proc = nil
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
      @graph = ModelGraph.new
      @curr_vertex = 0
      @seq_n = 0
    end



    def get_graph_map
      nodes = @graph.graph.vertices.map do |vert|
        {
          id: vert,
          name: @vertex_output_map[vert].to_a.join("|"),
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



    def learn(fname)
      @curr_vertex = 0
      CSVReader.new(fname).read_stream.each { |x| process_row(x) }
      @curr_vertex = 0
    end

    def process_row(row)
      if row == nil
        @curr_vertex = 0
        @seq_n += 1
      else
        tag    = row[:tag]
        values = row[:features]
        vertex = @label_vertex_map[tag]
        @output_vertex_map[tag].add vertex
        @vertex_output_map[vertex].add tag
        @graph.graph.add_edge(@curr_vertex, vertex)
        @vertex_dataset[@curr_vertex].add_obj(vertex, values, @seq_n)
        @curr_vertex = vertex
      end
    end
  end

  # stores data per class
  class Dataset
    attr_accessor :vertex_objects, :vertex_values


    include Enumerable
    def initialize
      @vertex_objects = Hash.new { |hash, key| hash[key] = Array.new }
      @vertex_values = Hash.new { |hash, key| hash[key] = Hash.new{ |hash, key| hash[key] = Array.new } }
    end

    def each
      @vertex_values.each do |vertex, values|
        (values.values).transpose.each do |row|
          yield row + [vertex]
        end
      end
    end

    def remove_default_proc!
      @vertex_objects.default_proc = nil
      @vertex_values.default_proc  = nil
      @vertex_values.values.each { |x| x.default_proc = nil }
    end

    def add_obj(vertex, values, seq)
      values.each do |field, val|
        @vertex_values[vertex][field].push val
      end
      so = SeqObject.new
      so.props = values
      @vertex_objects[vertex].push so
    end
  end

  # element of sequence
  class SeqObject
    attr_accessor :props
    def initialize
      @props = nil
    end
  end

  if __FILE__ == $PROGRAM_NAME
    model = Model.new
    model.learn(ARGV[0])
    binding.pry
  end
end
