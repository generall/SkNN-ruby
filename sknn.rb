require 'rubygems'
require 'bundler/setup'
require 'optparse'
require 'knn'
require 'pry'

require_relative 'tagger.rb'

include SkNN
include KNNModule

class EuclidDist
  include Measurable::Euclidean
  alias :distance :euclidean
end

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: ruby sknn.rb [options] file1 file2 ..."

  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end

  opts.on("-lMODEL", "--learn=MODEL", "Learn classifier model and save to MODEL file") do |model|
    options[:learn] = true
    options[:model] = model
  end

  opts.on("-xMODEL", "--execute=MODEL", "Execute classifier with MODEL file") do |model|
    options[:exec] = true
    options[:model] = model
  end

  opts.on("-o", "--output=FILE", "Write output to FILE (override). STDOUT if not specified.") do |file|
    options[:to_file] = true
    options[:output_fname] = file
  end

  opts.on("-k", "--k-knn=K", "K param to kNN algorithm.") do |k|
    options[:k] = k.to_i
  end

end.parse!


tagger = Tagger.new

if options[:learn] then
  tagger.make_model(ARGV, KNN, EuclidDist, options[:model], options[:k] || 1)
end

if options[:exec] then
  res = tagger.classify(ARGV[0], options[:model])
  output = res.map{|x| x.join("\n")}.join("\n\n")
  if options[:to_file] then
    File.write(options[:output_fname],output)
  else
    print output
  end
end
