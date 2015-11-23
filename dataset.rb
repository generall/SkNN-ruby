require 'rubygems'
require 'bundler/setup'


module SkNN
  # stores data per class
  class Dataset
    attr_accessor :vertex_objects, :schema, :objects, :sequence_objects


    include Enumerable
    def initialize
      @objects = []
      @vertex_objects = Hash.new { |hash, key| hash[key] = Array.new }
      @sequence_objects = Hash.new { |hash, key| hash[key] = Array.new }
      @schema = Set.new
      # vertex
      # => fied
      # => => value array
      #
    end

    def each(selector = @schema.to_a)
      @objects.each do |obj|
        yield selector.map{ |x| obj.props[x] }
      end
    end

    def enum(selector = @schema.to_a, vertex: nil, seq: nil)
      objects = vertex ? @vertex_objects[vertex] : (seq ? @sequence_objects[seq] : @objects )
      return Enumerator.new do |y|
        objects.each do |obj|
          y << selector.map{ |x| obj.props[x] } if obj.props[:tag] != :end
        end
      end
    end

    def remove_default_proc!
      @vertex_objects.default_proc = nil
      @sequence_objects = nil
    end

    def add_obj(vertex, tag, values, seq)
      values.each do |field, val|
        @schema.add field
      end
      so = SeqObject.new
      so.props = values.merge( {:tag => tag, :vertex => vertex, :seq => seq} )
      @vertex_objects[vertex].push so
      @sequence_objects[seq].push so
      @objects.push so
      so
    end
  end

  # element of sequence
  class SeqObject
    attr_accessor :props, :prev, :next, :n

    @@last = nil

    def initialize
      @props = nil
      @prev = @@last
      @next = nil
      if prev
        prev.next = self
      end
      @@last = self
    end

    def inspect()
      return @props.to_s
    end
  end

  class TargetData

    attr_accessor :data

    def initialize(fname)
      reader = CSVReader.new(fname, TestCSVSchema.new)
      @data = {}
      n = 0
      sequence = []
      reader.read_stream.each do |row|
        if row
          sequence << row
        else
          @data[n] = sequence
          sequence = []
          n += 1;
        end
      end
      @data[n] = sequence
    end

  end

  if __FILE__ == $PROGRAM_NAME
    model = Model.new
    model.learn(ARGV[0])
    binding.pry
  end
end
