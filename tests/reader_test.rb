require 'test/unit'
require_relative '../reader.rb'

class ReaderTest < Test::Unit::TestCase
	def setup
		@reader = CSVReader.new("../data/test.csv")
	end

	# def teardown
	# end

	def test_csv
		data = @reader.read_stream.first
		assert_equal(data, {:features=>{0=>1 , 1=>2 , 2=>3 , 3=>4}, :tag=>4 })
	end
end