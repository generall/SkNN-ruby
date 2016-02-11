require 'rubygems'
require 'bundler/setup'

require_relative 'reader.rb'
require_relative 'dataset.rb'

module SkNN
  class CSVLoader
    def initialize
    end

    def load_test(csv_file, mapping = { :values => (0..-1), :label => nil, :output => nil } )
      load(csv_file, mapping)
    end

    def load(csv_file, mapping = { :values => (0..-2), :label => -1, :output => -1 } )
      seq_n = 0
      dataset = Dataset.new
      last = nil
      csv_schema = MapCSVSchema.new(mapping)
      reader = CSVReader.new(csv_file, csv_schema)
      reader.read_stream.each do |row|
        if row
          label  = row[:label ]
          values = row[:values]
          output = row[:output]

          so = SeqObject.new(last, label, output)
          so.props = values
          last = so
          dataset.add_seq_obj(so, seq_n)
        else
          last = nil
          seq_n += 1
        end
      end
      return dataset
    end
  end

  class ArrayLoader
    def initialize
    end

    def load(array, mapping = { :values => :values, :label => :label, :output => :label } )
      dataset = Dataset.new
      array.each.with_index do |seq, seq_n|
        last = nil
        seq.each do |row|
          label  = row[mapping[:label ]] rescue nil
          output = row[mapping[:output]] rescue nil
          values = row[mapping[:values]]
          
          so = SeqObject.new(last, label, output)
          so.props = values
          last = so
          dataset.add_seq_obj(so, seq_n)
        end
      end
      return dataset
    end
  end


  class NodeConstructorTemplate
    def initialize(distance_function_class, searcher_class, options = {})
      @distance_function_class = distance_function_class
      @searcher_class = searcher_class
      # needs for nomalized functions or functions like MVDM
      @init_with_nodes = options[:init_with_nodes]
    end

    def construct_distance_function(node)
      if @init_with_nodes
        ds = node.dataset
        node.distance_function = @distance_function_class.new(ds.get_data_iterator, ds.get_label_iterator)
      else
        node.distance_function = @distance_function_class.new
      end
    end

    def construct_searcher(label, subset, node, model)
      node.searchers[label] = @searcher_class.new(
        subset, :distance_measure => node.distance_function)
    end
  end
end
