require 'rubygems'
require 'bundler/setup'

require 'measurable'

module SkNN
  class DataIterator
    include Enumerable

    def initialize(sequence_objects)
      @data = sequence_objects 
    end

    def [](idx)
      @data[idx].coordinates
    end

    def each
      if block_given?
        @data.each { |x| yield x.coordinates }
      else
        Enumerator.new do |x|
          @data.each { |y| x << y.coordinates }
        end
      end
    end

    def empty?
      @data.empty?
    end

    def size
      @data.size
    end
  end

  class LabelIterator
    include Enumerable

    def initialize(sequence_objects)
      @data = sequence_objects
    end

    def [](idx)
      @data[idx].label
    end

    def each
      if block_given?
        @data.each { |x| yield x.label }
      else
        Enumerator.new do |x|
          @data.each { |y| x << y.label }
        end
      end
    end

    def empty?
      @data.empty?
    end

    def size
      @data.size
    end
  end

  # stores data per class
  class Dataset
    attr_accessor :vertex_objects, :objects, :sequence_objects

    # Make iterators!
    include Enumerable
    def initialize
      @objects = []
      @vertex_objects = Hash.new { |hash, key| hash[key] = [] }
      @sequence_objects = Hash.new { |hash, key| hash[key] = [] }
      # vertex
      # => fied
      # => => value array
      #
    end

    def get_data_iterator
      DataIterator.new(@objects)
    end

    def get_label_iterator
      LabelIterator.new(@objects)
    end

    def remove_default_proc!
      @vertex_objects.default = nil
      @sequence_objects.default = nil
    end

    def add_seq_obj(seq_obj, seq)
      label = seq_obj.label
      @vertex_objects[label].push seq_obj
      @sequence_objects[seq].push seq_obj
      @objects.push seq_obj
    end

    def dump_sv(delim = "\t")
      @sequence_objects.map do |key, seq|
        seq.map do |inst|
          row = inst.coordinates + [inst.label]
          row.join(delim)
        end.join("\n")
      end.join("\n\n")
    end
  end

  # element of sequence
  class SeqObject
    attr_accessor :props, :prev, :next, :label, :output, :schema
    include Measurable::MeasurableObject

    def coordinates
      if @schema
        @schema.map { |x| @props[x] }
      else
        return @props
      end
    end

    def size
      coordinates.size
    end

    def [](idx)
      coordinates[idx]
    end

    def initialize(last = nil, label = nil, output = nil)
      @props = nil
      @prev = last
      @next = nil
      @label = label
      @output = output
      @schema = nil

      @prev && @prev.next = self
    end

    def inspect
      return "<SeqObject: #{@props} #{@label} #{@output}>"
    end
  end
end
