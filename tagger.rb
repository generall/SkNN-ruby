require_relative 'model.rb'

module SkNN
  class Tagger

    attr_accessor :model

    def initialize
      @model = Model.new
    end

    def learn(fname)
      @model.learn(fname)
    end

  end

  if __FILE__ == $PROGRAM_NAME
    tagger = Tagger.new
    tagger.learn(ARGV[0])
    model = Model.load(tagger.model.dump)
    binding.pry
  end

end
