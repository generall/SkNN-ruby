require 'optparse'
require 'pry'

require_relative 'tagger.rb'

include SkNN

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

  opts.on("-cN", "--cluster=N", "Perform clustering with num. of clusters = N") do |n|
    options[:cluster] = n.to_i
  end


  opts.on("-n", "--normalize", "Perform centring & scaling",  "(WARN: both, learn and test data should be normalized)" , "External normalization recomended") do
    options[:norm] = true
  end

  opts.on("-o", "--output=FILE", "Write output to FILE (override). STDOUT if not specified.") do |file|
    options[:to_file] = true
    options[:output_fname] = file
  end

  opts.on("-k", "--k-knn=K", "K param to kNN algorithm.") do |k|
    options[:k] = k
  end

end.parse!


tagger = Tagger.new

if options[:learn] then
  tagger.make_model(ARGV, options[:model], options[:norm], options[:cluster])
end

if options[:exec] then
  k = options[:k] || 1
	res = tagger.classify(ARGV[0], k)
	output = res.map{|x| x.join("\n")}.join("\n")
	if options[:to_file] then
		File.write(options[:output_fname],output)
	else
		print output
	end
end