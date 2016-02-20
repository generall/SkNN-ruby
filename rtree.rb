# After accepting Pull Request of Measurable it must be moved to separated Gem!
require 'rubygems'
require 'bundler/setup'

require "algorithms"

class Containers::PriorityQueue
  def next_priority
    @heap.next_key
  end
end

module Rtree
  # Implementation of queue with fixed size.
  # Will store elements with low priority
  class FixedLengthQueue < Containers::PriorityQueue
    def initialize(limit = 4) # 4 for example
      super()
      @limit = limit
    end

    def max_priority
      @heap.next_key
    end

    def push(value, priority)
      if size < @limit
        super(value, priority)
      else
        if priority < @heap.next_key
          pop
          super(value, priority)
        end
      end
    end

    def dump
      size.times.map { @heap.pop }
    end
  end

  # Mixin for calculating distance
  # compatable with Distance-measure gem
  module CalcDistance
    attr_accessor :stats
    def calc_dist(obj1, obj2)
      @stats[:calc_dist] += 1 if @stats
      return @is_block ? obj1.distance(obj2, &@distance_measure) : obj1.distance(obj2, @distance_measure)
    rescue
      # old fasion distance gem, for arrays only
      return @is_block ? @distance_measure.call(obj1, obj2) : obj1.send(@distance_measure, obj2)
    end
  end

  class RNode
    attr_accessor :value, :childrens, :index, :weight, :siblings_count, :level, :data
    def initialize
      @value = nil
      @level = nil
      @childrens = {}
      @index = nil
      @weight = nil # maximum distance contribution by this feature
      @siblings_count = 0
      @data = nil
    end
  end

  class RTree
    attr_accessor :order, :sum_from_start, :sum_from_end
    include CalcDistance
    def initialize(data, options = {})
      @data = data
      @is_block = block_given?
      # works ONLY with special distance functions
      @distance_measure = options[:distance_measure]
      @weights = @distance_measure.weights.values
      @f_count = @data.first.size
      @order = (0..(@data.first.size - 1)).to_a
      @order.sort! do |a,b|
        res = @weights[b] <=> @weights[a]
        if res == 0
          res = @distance_measure.feature_indexes[a].feature_count.size <=> @distance_measure.feature_indexes[b].feature_count.size
        end
        res
      end
      @root = RNode.new
      @root.siblings_count = @data.size
      @max_dist = @weights.reduce(:+)
      #
      # Example: weights = [1,2,3]
      #          order   = [0,1,2]
      #
      # sum_from_start = [1, 3, 6]
      # sum_from_end   = [5, 3, 0]
      #
      @sum_from_start = (0..(@f_count - 1)).map { |i| @order[0..i ].reduce(0.0) { |sum,idx| sum + @weights[idx] } }
      @sum_from_end   = (1..(@f_count    )).map { |i| @order[i..-1].reduce(0.0) { |sum,idx| sum + @weights[idx] } }
      build_tree
    end

    def build_tree
      queue = {@root => @data}
      @order.each.with_index do |idx, level|
        queue_new = {}
        queue.each do |node, data|
          groups = data.group_by { |x| x[idx] }
          groups.each do |key, subdata|
            new_node = RNode.new
            new_node.index = idx
            new_node.value = key
            new_node.level = level
            new_node.weight = @weights[idx]
            new_node.siblings_count = subdata.size
            node.childrens[key] = new_node
            queue_new[new_node] = subdata
          end
        end
        queue = queue_new
      end
      queue.each do |node, data|
        node.data = data.first
      end
    end

    def add(instance)
      node = @root
      @order.each.with_index do |idx, level|
        value = instance[idx]
        children = node.childrens[value]
        if children.nil?
          children = RNode.new
          node.childrens[value] = children
          children.value = value
          children.index = idx
          children.level = level
          children.weight = @weights[idx]
        end
        node.siblings_count += 1;
        node = children
      end
    end

    # Finds k nearest instances
    # Pruning condition:
    # If all subnode of observed node is fully equal to instance - there are 
    # enoth closer nodes: 
    def find_k_nearest(ints, k = 1)
      # garantee that specified count of instances will be closer than div
      raise "Too big k" if k > @root.siblings_count
      pesimistic_nodes = FixedLengthQueue.new(k)
      optimistic_nodes = Containers::PriorityQueue.new
      optimistic_nodes.push(@root, 0)
      node_iterated = 0
      while !optimistic_nodes.empty?
        node_iterated += 1;
        optimistic_distance_parent = - optimistic_nodes.next_priority
        max_accepted_distance = k > pesimistic_nodes.size ? Float::INFINITY : pesimistic_nodes.max_priority
        break if optimistic_distance_parent > max_accepted_distance
        node = optimistic_nodes.pop
        # make a decision about childrens adding to queue
        node.childrens.each do |sub_value, sub_node|
          idx   = sub_node.index
          level = sub_node.level
          inst_value = ints[idx]
          # calculate optimistic and pessimistic distances for this node
          if inst_value == sub_value
            optimistic_distance = optimistic_distance_parent
            pesimistic_distance = optimistic_distance_parent + @sum_from_end[level]
          else
            # WARNING
            # Next conditions will be work only for weighted overlap measure!
            # Rewrite it to use with other metrics: replace @weights with component distance
            optimistic_distance = optimistic_distance_parent + @weights[idx]
            pesimistic_distance = optimistic_distance_parent + @weights[idx] + @sum_from_end[level]
          end
          # make decision about pushing this node to queue here
          # try to add pessimistic node k times
          if sub_node.level == @f_count - 1 # if this node is leave
            i = 0
            max_insts = [k, sub_node.siblings_count].min
            max_accepted_distance = k > pesimistic_nodes.size ? Float::INFINITY : pesimistic_nodes.max_priority

            while i < max_insts  && max_accepted_distance > pesimistic_distance
              pesimistic_nodes.push([pesimistic_distance, sub_node.data], pesimistic_distance)
              max_accepted_distance = k > pesimistic_nodes.size ? Float::INFINITY : pesimistic_nodes.max_priority
              i += 1
            end
          else
            # try to add subnode to lookup queue: optimistic distance must be greater than pessimistic achived
            best_achived = k > pesimistic_nodes.size ? Float::INFINITY : pesimistic_nodes.max_priority
            # if it could be better
            if best_achived > optimistic_distance
              optimistic_nodes.push(sub_node, - optimistic_distance)
            end
          end
        end
      end
      puts "Node iterated: #{node_iterated}" if $debug
      return pesimistic_nodes.dump.reverse
    end
  end
end

