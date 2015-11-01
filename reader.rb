#require 'rubygems'
#require 'bundler/setup'

require "csv"
require "pry"

# property of object
class Property
  def initialize
    @value = nil
    @cmp = nil
  end
end

class Reader

  attr_reader :data

  def initialize(fname)
    @fname = fname
  end

  def init_fake()
    @data = [[1,2,3], [4,5,6], [7,8,9]]
  end

  def init_data()
    init_fake
  end

  def read_stream(&code) #face stream
    init_data
    @data.each do |x|
      code.call(x)
    end
  end
end

class CSVReader < Reader

  def initialize(fname, schema = DefaultCSVSchema.new)
    super(fname)
    @schema = schema
  end

  def init_data()
    @data = CSV.read(@fname)
  end

  def read_stream()
    if @schema
      CSV.foreach(@fname).lazy.map{|row| @schema.remap(row)}.each
    else
      return CSV.foreach(@fname)
    end
  end
end

class Schema
  def initialize
  end
end

class DefaultCSVSchema < Schema
  def initialize
    @row_size = nil
  end
  def remap(row)
    return nil if row.size == 0
    if !@row_size
      @row_size = row.size 
    elsif @row_size != row.size
      
      raise "Wrong row size"
    end
    features = {}
    row[0..-1].each.with_index do |val, index|
      features[index] = Integer(val) rescue val
    end
    tag= Integer(row.last) rescue row.last
    res = {:tag => tag, :features => features}
  end
end
