
require_relative 'model.rb'

require "pry"

module SkNN

  class Preproc
    def initialize
    end

    def seq_normalization(model)

      schema = model.vertex_dataset[1].schema
      model.seq_objects.each do |seq, objects|
        objects.select!{|x| x.props[:tag] != :end}
        schema.each do |field|
          max_value = objects.max_by{|x| x.props[field]}.props[field]
          min_value = objects.min_by{|x| x.props[field]}.props[field]
          objects.each do |obj|
            obj.props[field] = (obj.props[field] - min_value) / (max_value - min_value).to_f
          end
        end
      end
    end

    def td_norm(td)
      td.data.each do |seq, elems|
        n_elems = []
        (0..(elems.first.size - 1)).each do |field|
          max_value = elems.max_by{|x| x[field]}[field]
          min_value = elems.min_by{|x| x[field]}[field]
          elems.each do |obj|
            obj[field] = (obj[field] - min_value) / (max_value - min_value).to_f
          end
        end
      end
    end


  end

end
