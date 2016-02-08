require 'test/unit'
require_relative '../model.rb'
require 'measurable'
require 'knn'
require 'pry'

include SkNN
include Measurable
include KNNModule

class KNN
  attr_accessor :data
end

class ModelTest < Test::Unit::TestCase
  def setup
  end

  def data
    [
      [ 544, 1017 ],
      [ 578, 969  ],
      [ 596, 921  ],
      [ 596, 921  ],
      [ 601, 879  ],
      [ 560, 850  ],
      [ 503, 844  ],
      [ 424, 860  ],
      [ 342, 909  ],
      [ 275, 975  ],
      [ 251, 1071 ],
      [ 270, 1158 ],
      [ 327, 1216 ],
      [ 404, 1241 ],
      [ 477, 1214 ],
      [ 540, 1159 ],
      [ 581, 1092 ],
      [ 599, 1024 ],
      [ 604, 963  ],
      [ 604, 963  ],
      [ 604, 963  ],
      [ 604, 963  ],
      [ 657, 1095 ],
      [ 720, 1200 ],
      [ 802, 1286 ],
      [ 894, 1339 ],
      [ 999, 1351 ]
    ]
  end
  # def teardown
  # end

  def test_sequence_processing
    sequence = []
    model = Model.new
    so = nil
    so = SeqObject.new(so, "l1", "o1")
    sequence.push so
    so = SeqObject.new(so, "l1", "o1")
    sequence.push so
    so = SeqObject.new(so, "l2", "o2")
    sequence.push so
    so = SeqObject.new(so, "l2", "o1")
    sequence.push so
    so = SeqObject.new(so, "l1", "o1")
    sequence.push so
    so = SeqObject.new(so, "l3", "o1")
    sequence.push so
    so = SeqObject.new(so, "l2", "o1")
    sequence.push so
    model.process_sequence(sequence)
    
    node1 = model.node("l1")
    node2 = model.node("l2")
    node3 = model.node("l3")
    node_end  = model.node(:end)
    node_init = model.node(:init)
    
    assert_true(model.graph.has_edge?(node1, node3))
    assert_true(model.graph.has_edge?(node1, node2))
    assert_true(model.graph.has_edge?(node2, node1))
    assert_true(model.graph.has_edge?(node3, node2))
    assert_true(model.graph.has_edge?(node_init, node1))
    assert_true(model.graph.has_edge?(node2, node_end))

    assert_false(model.graph.has_edge?(node1, node_end))
    assert_false(model.graph.has_edge?(node3, node_end))
    
    assert_false(model.graph.has_edge?(node2, node3))
    assert_false(model.graph.has_edge?(node3, node1))

    assert_equal(node_init.dataset.objects.size, 1)
    assert_equal(node2.dataset.objects.size, 2)
    assert_equal(node_end.dataset.objects.size, 0)


    assert_false( node1.dataset.vertex_objects["l2"] == node1.dataset.vertex_objects["l3"] )

    assert_true( node1.dataset.vertex_objects["l2"].first.label == "l2" )
    assert_true( node1.dataset.vertex_objects["l3"].first.label == "l3" )

    aDistanceClass = Class.new do
      include Measurable::Euclidean
      alias :distance :euclidean
    end

    aDistanceClassInit = Class.new do
      include Measurable::Euclidean
      alias :distance :euclidean
      def initialize(x)
        throw "Wrong class in init" if x.class != Array
      end
    end


    config1 = NodeConstructorTemplate.new(aDistanceClass, KNN)
    config2 = NodeConstructorTemplate.new(aDistanceClassInit, KNN, :init_with_nodes => true )
    model.init_nodes(1, config2)
    model.init_nodes(1, config1)
    srch = node_init.searchers
    assert_equal(srch.size, 1)
    assert_equal(srch["l1"].class, KNN)
    
    srch = node1.searchers
    assert_false( srch["l2"] == srch["l3"] )
    assert_false( srch["l2"].data == srch["l3"].data )

  end
end
