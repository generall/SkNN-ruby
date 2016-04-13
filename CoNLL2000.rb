require 'rubygems'
require 'bundler/setup'
require 'knn'
require 'measurable'
require 'vptree'
require 'pry'

require_relative 'tagger.rb'
require_relative 'rtree.rb'

include SkNN
include KNNModule
include Vptree
include Rtree

mvdm_class = Measurable::MVDM
weighted_overlap_class = Measurable::WeightedOverlap

#DATA_DIR="/home/generall/data/CoNLL2000/"
DATA_DIR="./"
SkNN_DEBUG = true
k = 1
model_file = "model.dat"

if __FILE__ == $0
  src_dir = "/home/generall/data/CoNLL2000/"

  if ARGV.include?("-ex")
    loader = C45Loader.new(SSVReader)
    ds_train = loader.load(src_dir + "train.txt"      , {:values => [0, 1], :label => -1, :output => -1} )
    ds_test  = loader.load(src_dir + "small_test.txt" , {:values => [0, 1], :label => -1, :output => -1} )
    FeatureExpander.expand_sequence(ds_train, 2)
    FeatureExpander.expand_sequence(ds_test , 2)
    File.write("train_ex.txt", ds_train.dump_sv())
    File.write("test_ex.txt" , ds_test.dump_sv())
    
    exit 0
  end

  if ARGV.include?("-d")
    # debug mode here
    tagger = Tagger.new
    loader = C45Loader.new(SSVReader)
    tagger.model = Model.load( File.read( model_file ) )
    test_dataset  = loader.load( DATA_DIR + "test_ex.txt" )
    
    sq1 = test_dataset.sequence_objects[0]
    data = sq1.map(&:itself)
    model = tagger.model
    binding.pry
    #res = tagger.tagg(data)

  else
    tagger = Tagger.new
    tagger.make_model( [DATA_DIR + "train_ex.txt"], VPTree, weighted_overlap_class, model_file, k, 
                      :init_with_nodes => true,
                      :reader => SSVReader,
                      :ratio => true,
                      :skip_weighting => true
                     )
    puts "make_model completed"
    loader = C45Loader.new(SSVReader)
    test_dataset  = loader.load( DATA_DIR + "test_ex.txt")
    valid_dataset = loader.load( DATA_DIR + "test_ex.txt")
    puts "Test dataset loading complete"
    tagger.tag!(test_dataset)
    obj1 = test_dataset.get_label_iterator
    obj2 = valid_dataset.get_label_iterator
    err = obj1.zip(obj2).select{|x,y| x != y}
    p err.size
    p (obj1.size - err.size)/obj1.size.to_f
    binding.pry
  end
end


