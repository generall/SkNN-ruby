require 'rubygems'
require 'bundler/setup'

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
  attr_accessor :schema

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

class SSVReader < Reader
  attr_accessor :schema
  def initialize(fname, schema = DefaultCSVSchema.new, delim = /\s/)
    super(fname)
    @schema = schema
    @delim = delim
  end
  def read_stream()
    if @schema
      File.open(@fname).lazy.map do |line|
        @schema.remap(line.strip.split(@delim))
      end.each
    end
  end
end

class Schema
  def initialize
  end
  def remap(row)
    return row
  end
end

class MapCSVSchema < Schema
  attr_accessor :schema
  def initialize(mapping)
    @mapping = mapping
    @row_size = nil
    @schema = nil
  end

  def try_numeric(val)
    Integer(val) rescue Float(val) rescue val
  end

  def remap(row)
    return nil if row.size == 0
    if !@row_size
      @row_size = row.size 
    elsif @row_size != row.size
      binding.pry
      raise "Wrong row size"
    end
    
    output = row[@mapping[:output]] rescue nil
    label  = row[@mapping[:label ]] rescue nil
    values = []
    if @mapping[:values]
      if @mapping[:values].class == Array
        @mapping[:values].each do |idx|
          values.push try_numeric(row[idx])
        end
      else
        row[@mapping[:values]].each do |x|
          values.push try_numeric(x)
        end
      end
    else
      not_values_indexes = [@mapping[:output], @mapping[:label]].to_set
      row.each.with_index do |x, i|
        values.push try_numeric(x) if !not_values_indexes.include? i
      end
    end
    if !@schema
      @schema = values.map.with_index { |x,i| i }.to_set
    end
    { :label => label, :output => output, :values => values }
  end
end

# deprecated
class DefaultCSVSchema < Schema
  def initialize
    @row_size = nil
  end
  def remap(row)
    return nil if row.size == 0

    if !@row_size
      @row_size = row.size 
    elsif @row_size != row.size
      binding.pry
      raise "Wrong row size"
    end
    features = {}
    row[0..-2].each.with_index do |val, index|
      features[index] = Integer(val) rescue val
    end
    tag = Integer(row.last) rescue row.last
    res = {:tag => tag, :features => features}
  end
end


class TestCSVSchema < Schema
  def initialize
    @row_size = nil
  end

  def remap(row)
    return nil if row.size == 0

    if !@row_size
      @row_size = row.size 
    elsif @row_size != row.size
      binding.pry
      raise "Wrong row size"
    end

    row.map do |val|
      Integer(val) rescue val
    end
    
  end

end
