require 'test/unit'
require_relative '../tagger.rb'
require 'measurable'
require 'knn'
require 'pry'

include SkNN
include KNNModule

class EuclidDist
  include Measurable::Euclidean
  alias :distance :euclidean
end

class ReaderTest < Test::Unit::TestCase
  def setup
     # model.cluster_loops(2) # cluster A
    # model.cluster_loops(3) # cluster B
  end

  def test_array_loader
    @tagger = Tagger.new
    @ld = ArrayLoader.new()

    learn = [
      [
        {:values => [1  ], :label => :l1},
        {:values => [100], :label => :l2},
        {:values => [10 ], :label => :l3},
        {:values => [11 ], :label => :l3}
      ],
      [
        {:values => [1  ], :label => :l1},
        {:values => [50 ], :label => :l4},
        {:values => [21 ], :label => :l5},
        {:values => [20 ], :label => :l5}
      ],
      [
        {:values => [1], :label => :l1},
        {:values => [2], :label => :l1},
        {:values => [3], :label => :l1},
        {:values => [4], :label => :l1},
        {:values => [5], :label => :l1}
      ]
    ]

    # Array is Measurabe, so it can be compared with SeqObject!
    test = [
      [
        [1 ],
        [70],
        [0 ],
        [0 ]
      ],
      [
        [1 ],
        [80],
        [23],
        [22]
      ]
    ]

    dataset = @ld.load(learn)
    @tagger.learn_from_dataset(dataset)
    model = @tagger.model

    @tagger.init_nodes(EuclidDist, KNN, 1)

    res = test.map do |t|
      @tagger.tagg(t)
    end

    assert_equal(res[0][0][0], :l1)
    assert_equal(res[0][1][0], :l2)
    assert_equal(res[0][2][0], :l3)
    assert_equal(res[0][3][0], :l3)
    
    assert_equal(res[1][0][0], :l1)
    assert_equal(res[1][1][0], :l4)
    assert_equal(res[1][2][0], :l5)
    assert_equal(res[1][3][0], :l5)


    test_dataset = @ld.load(test, {:values => (0..-1)})
    
    @tagger.tag!(test_dataset)

    assert_equal(test_dataset.sequence_objects[0][0].label, :l1)
    assert_equal(test_dataset.sequence_objects[0][1].label, :l2)
    assert_equal(test_dataset.sequence_objects[0][2].label, :l3)
    assert_equal(test_dataset.sequence_objects[0][3].label, :l3)
    assert_equal(test_dataset.sequence_objects[1][0].label, :l1)
    assert_equal(test_dataset.sequence_objects[1][1].label, :l4)
    assert_equal(test_dataset.sequence_objects[1][2].label, :l5)
    assert_equal(test_dataset.sequence_objects[1][3].label, :l5)
    
    Marshal.dump(KNN.new(nil))
    
    @tagger.model.dump

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

  def test_csv
    @tagger = Tagger.new
    @tagger.learn("../data/clust_pen.csv")
    model = @tagger.model
    
    aDistanceClass = Class.new do
      include Measurable::Euclidean
      alias :distance :euclidean
    end
    config = NodeConstructorTemplate.new(aDistanceClass, KNN)
    model.init_nodes(1, config)


    @tagger.model.graph.render

    tags = @tagger.tagg(data)
    assert_equal(data.size, tags.size)
  end


  def test_real_sknn
    @tagger = Tagger.new
    @tagger.make_model(["../data/clust_pen.csv"], KNN, EuclidDist )
    
    @tagger = Tagger.new
    res = @tagger.classify("../data/test_pen_a.csv")
    binding.pry
  end
end

