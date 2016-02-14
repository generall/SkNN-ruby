require 'test/unit'
require_relative '../reader.rb'
require_relative '../cluster_seq.rb'
require_relative '../loader.rb'
require_relative '../model.rb'

require 'pry'

CSV_TEST_FILE = '../data/test.csv'

class ReaderTest < Test::Unit::TestCase
  def setup
    @reader = CSVReader.new(CSV_TEST_FILE, MapCSVSchema.new( { :values => (0..-2), :label => -1, :output => -1 } ) )
  end

  # def teardown
  # end

  def test_csv
    data = @reader.read_stream.first
    assert_equal(data, {:label=>"state_2", :output=>"state_2", :values=>[1, 2, 3]})
  end
end

class LoaderTest < Test::Unit::TestCase
  def setup
    @loader = SkNN::C45Loader.new
  end

  def test_load
    ds = @loader.load(CSV_TEST_FILE)
    assert_equal(4, ds.vertex_objects.size)
    assert_equal(2, ds.sequence_objects.size)
    model = SkNN::Model.new
    model.learn(ds) # test for no error, graph building test is in model_test
    assert_equal(model.node("state_1").output, "state_1")
  end


  def test_feature_expand
    @ld = SkNN::ArrayLoader.new

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

    dataset = @ld.load(learn)
    SkNN::FeatureExpander.expand_sequence(dataset, 2)
  end
end
=begin
class ClusterTest < Test::Unit::TestCase
  def setup
    @cl = SkNN::`SeqClusterer.new
  end

  def test_load
    @cl.load("../data/test_clust.csv")
    label = "state_1"
    ds = @cl.datasets[label];
    @cl.cluster_array(ds)
    assert_true(ds.objects[1].props[:cluster] != ds.objects[5].props[:cluster])
  end

end
=end

