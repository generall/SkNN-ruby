require 'rubygems'
require 'bundler/setup'

require 'measurable'

module SkNN
  # stores data per class
  class Dataset
    attr_accessor :vertex_objects, :objects, :sequence_objects


    include Enumerable
    def initialize
      @objects = []
      @vertex_objects = Hash.new { |hash, key| hash[key] = Array.new }
      @sequence_objects = Hash.new { |hash, key| hash[key] = Array.new }
      # vertex
      # => fied
      # => => value array
      #
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

    def initialize(last = nil, label = nil, output = nil )
      @props = nil
      @prev = last
      @next = nil
      @label = label
      @output = output
      @schema = nil

      if @prev
        @prev.next = self
      end
    end

    def inspect()
      return "<SeqObject: #{@props} #{@label} #{@output}>"
    end
  end

end
