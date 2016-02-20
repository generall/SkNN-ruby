require 'test/unit'
require_relative '../reader.rb'
require_relative '../loader.rb'
require_relative '../model.rb'
require_relative '../rtree.rb'
require 'measurable'

require 'pry'

include Rtree
include SkNN

class RTreeTest < Test::Unit::TestCase
  def setup
    @data = [
      [:a, :a, :b, :a],
      [:a, :a, :b, :b],
      [:a, :a, :b, :c],
      [:a, :b, :b, :b],
      [:a, :b, :b, :e],
      [:a, :b, :b, :f],
      [:a, :b, :b, :g],
      [:a, :c, :b, :h],
      [:a, :c, :b, :j],
      [:a, :c, :b, :j],
      [:a, :c, :b, :j],
      [:a, :c, :b, :j],
      [:a, :c, :b, :k]
    ]
    @labels = [:c1, :c1, :c1, :c2, :c2, :c2, :c2, :c3, :c3, :c3, :c3, :c3, :c3]
  end

  def test_ordering
    distClass = Measurable::WeightedOverlap
    wdist = distClass.new(@data, @labels, ratio: true)
    odist = distClass.new(@data, @labels, skip_weighting: true)
    wrtree = RTree.new(@data, :distance_measure => wdist)
    ortree = RTree.new(@data, :distance_measure => odist)
    ortree.add [:a, :c, :b, :l]
    wrtree.add [:a, :c, :b, :l]
    res = ortree.find_k_nearest([:a, :a, :b, :f], 2)
    assert_equal(res, [[1.0, [:a, :a, :b, :b]], [1.0, [:a, :a, :b, :a]]])
    assert_equal(ortree.order, [0,2,1,3])
  end

  def test_seqobj
    distClass = Measurable::WeightedOverlap
    dataset = C45Loader.new(SSVReader).load_test("rtree_data.ssv")
    odist = distClass.new(dataset.get_data_iterator, [1]*dataset.get_data_iterator.size, skip_weighting: true)
    ortree = RTree.new(dataset.objects, :distance_measure => odist)
    $debug=true
    res = ortree.find_k_nearest([1,2,3,4,5,6,7,8,9,9], 1)
    assert_in_delta(res[0][0],5.0)
  end 
end
