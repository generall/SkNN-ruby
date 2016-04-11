require 'rubygems'
require 'bundler/setup'

require_relative 'model'

module SkNN
  class Tagger

    attr_accessor :model

    def initialize
      @model = Model.new
      @statistics = Hash.new(0)
    end

    def learn(fname, reader = CSVReader)
      @loader = C45Loader.new(reader)
      ds = @loader.load(fname)
      @model.learn(ds)
    end

    def learn_from_dataset(dataset)
      @model.learn(dataset)
    end

    def init_nodes(distance_class, searcher_class, k, options = {})
      @config = NodeConstructorTemplate.new(distance_class, searcher_class, options)
      @model.init_nodes(k, @config)
    end

    # +nearests+ is [ [distance, object], ... ]
    # can be replaced with wighted distance
    def distance_agregation(nearests)
      sum = 0.0
      nearests.each do |distance, object|
        sum += distance
      end
      return sum
    end

    def viretbi(sequence)
      v = []
      path = []

      v << Hash.new { |hash, key| hash[key] = Float::INFINITY }

      v.last[model.init_node] = 0 # at fitst step only :init (1) vertex is accessible with dist = 0


      max_iterations = sequence.size

      sequence.each.with_index do |object, idx|
        prev = v.last
        current_disnatces = Hash.new { |hash, key| hash[key] = Float::INFINITY }
        current_path = Hash.new { |hash, key| hash[key] = nil }
        
        print "Viterbi: #{idx} of #{max_iterations}\r"

        # iterate all reached at `k-1` atep nodes 
        prev.each do |node, dist|
          if dist != Float::INFINITY
            searchers = node.searchers
            @model.graph.adjacent_vertices(node).each do |next_node|
              # calculating node -> next_node distance
              # and compare it with all distances to next_node on this step
              # save the shortest one
              nearest_objects = nil
              next_label = next_node.label
              searcher = searchers[next_label]
              local_distance = 0
              if searcher # if next_label == :end
                @statistics[:searcher_call] += 1;
                nearest_objects = searcher.find_k_nearest(object, node.k)
                local_distance = distance_agregation(nearest_objects)
              else
                local_distance = Float::INFINITY
              end
              # p "#{node} --> #{next_node}: #{object}(#{next_label}) ## #{nearest_objects}  =>  #{local_distance}"
              next if local_distance == Float::INFINITY
              d = dist + local_distance
              if d < current_disnatces[next_node]
                current_disnatces[next_node] = d
                current_path[next_node] = [node, nearest_objects]
              end
            end
          end
        end
        v << current_disnatces
        path << current_path
      end

      # do not calc distances for pathes no ended with +end_node+
      path.last.each do |last_node, prev_node|
        if !@model.graph.has_edge?(last_node, @model.end_node)
          v.last[last_node] = Float::INFINITY
        end
      end

      return [v, path]
    end


    def tagg(data)
      res = []
      distance, path = viretbi(data)
      binding.pry if $debug
      last_path  = path.pop
      last_dists = distance.pop
      closest_key = last_dists.min_by{|node, dist| dist}.first
      
      node = closest_key
      last_node, nearest = last_path[node]

      output = node.output
      res.push [output, node, nearest]

      while !path.empty?
        node = last_node
        last_path  = path.pop
        last_dists = distance.pop
        last_node, nearest = last_path[node]
        output = node.output
        res.push [output, node, nearest]
      end
      res.reverse
    rescue Exception => e
      binding.pry
    end

    def tag(dataset)
      dataset.sequence_objects.map do |label, seq|
        tagg(seq).map(&:first)
      end
    end

    def tag!(dataset)
      sz = dataset.sequence_objects.size
      i = 0;
      dataset.sequence_objects.each do |label, seq|
        tags = tagg(seq)
        tags.each.with_index do |res,i|
          seq[i].output = res[1].output
          seq[i].label  = res[1].label
        end
        i += 1;
        print "#{i} of #{sz}\r"
      end
    end


    def make_model(files, searcher, distance, model_file = "model.dat", k = 1, options = {})
     
      puts "Start reading ... " if SkNN_DEBUG
      files.each do |fname|
        learn(fname, options[:reader] || CSVReader)
      end
      
      #default config for CLI

      init_nodes(distance, searcher, k, options)

      dump = @model.dump

      File.write(model_file, dump)
    end

    def classify(test_file, model_file = "model.dat")
      @model = Model.load( File.read( model_file ) )
      loader = C45Loader.new
      dataset = loader.load_test(test_file)
      tag(dataset)
    end
  end
end
