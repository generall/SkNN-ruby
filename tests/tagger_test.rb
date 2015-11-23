require 'test/unit'
require_relative '../tagger.rb'
require 'pry'

include SkNN


class ReaderTest < Test::Unit::TestCase
  def setup
    @tagger = Tagger.new
    @tagger.learn("../data/pen.csv")
    model = @tagger.model
    @tagger.model.graph.render
    model.cluster_loops(2) # cluster A
    model.cluster_loops(3) # cluster B
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
    tags = @tagger.tag(data)
    assert_equal(data.size, tags.size)

    assert_equal(tags[0],  "A")
  end
end
