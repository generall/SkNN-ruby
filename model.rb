require 'rubygems'
require 'bundler/setup'

require 'rgl/adjacency'
require 'rgl/dot'
require 'set'
require 'json'


require_relative 'reader'
require_relative 'dataset'
require_relative 'loader'

# module for model of Structured kNN sequence tagger
module SkNN

  class Node
    attr_accessor :dataset, :label, :output, :k, :searchers, :distance_function

    def initialize()
      @k = 1
      @dataset = Dataset.new
      @label = nil
      @output = nil
      @searchers = {} # Search objects here (Linear or some kind of tree (VP, R, e.t.c.))
      @distance_function = nil
    end

    def add_obj(seq_obj, seq)
      @dataset.add_seq_obj(seq_obj, seq)
      # add object somewhere else
    end

    def inspect
      "<Node: [#{@label}] #{@output}>"
    end

    def remove_default_proc!
      @dataset.remove_default_proc!
    end

    def to_s
      inspect
    end
  end


  # Graph of the model
  class ModelGraph < RGL::DirectedAdjacencyGraph
    def render(fname = "graph.png")
      write_to_graphic_file('png')
    end
  end

  # Model class
  class Model
    attr_accessor :graph, :labels, :outputs, :init_node, :end_node

    def node(label)
      return @label_to_node[label]
    end

    def dump()
      @label_to_node.each {|label, node| node.remove_default_proc!}
      @label_to_node.default = nil
      return Marshal.dump(self)
    end

    def self.load(dump)
      return Marshal.load(dump)
    end

    def initialize
      init_label = :init
      end_label  = :end

      @init_node = Node.new
      @init_node.label = init_label
      @end_node = Node.new
      @end_node.label = end_label

      @label_to_node = Hash.new
      @labels = Set.new
      @outputs = Set.new
      @current_node = @init_node
      @graph = ModelGraph.new
      @graph.add_vertex(@init_node)
      @graph.add_vertex(@end_node)
      @label_to_node[init_label] = @init_node
      @label_to_node[end_label ] = @end_node

      @seq_n = 0
    end

    def get_graph_map
      nodes = @graph.vertices.map do |vert|
        {
          id: vert,
          name: get_label(vert),
          value: 1
        }
      end
      links = @graph.edges.map do |edge|
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

    def learn(dataset)
      sz = dataset.sequence_objects.size
      i = 0
      dataset.sequence_objects.each do |num, seq|
        process_sequence(seq)
        i += 1;
        print "#{i} of #{sz}\r"
      end
    end


    # sequence is Array of Sequence object (or Enumerator)
    def process_sequence(sequence)
      @current_node = @init_node
      sequence.each do |instance|
        next_label = instance.label
        next_node = @label_to_node[next_label]
        if !next_node
          next_node = Node.new
          next_node.label = next_label
          next_node.output = instance.output
          @label_to_node[next_label] = next_node
        end
        @labels.add next_label
        @outputs.add instance.output
        @current_node.add_obj(instance, @seq_n)
        @graph.add_edge(@current_node, next_node)
        @current_node = next_node
      end
      @graph.add_edge(@current_node, @end_node)
      @seq_n += 1;
    end

    def init_nodes(k, constructor)
      @label_to_node.each do |label, node|
        node.k = k
        constructor.construct_distance_function(node)
        node.dataset.vertex_objects.each do |key, subset|
          constructor.construct_searcher(key, subset, node, self)
        end
      end
    end

  end

end
