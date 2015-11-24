require 'rubygems'
require 'bundler/setup'

require 'goliath'
require 'json'

require_relative 'tagger.rb'

include SkNN

$tagger = Tagger.new
ARGV.each do |fname|
  $tagger.learn(fname)
end

pp = Preproc.new
pp.seq_normalization($tagger.model)

#$tagger.model.cluster_loops(2 , 5)
#$tagger.model.cluster_loops(3 , 5)
#$tagger.model.cluster_loops(4 , 5)
#$tagger.model.cluster_loops(5 , 5)
#$tagger.model.cluster_loops(6 , 5)
#$tagger.model.cluster_loops(7 , 5)
#$tagger.model.cluster_loops(8 , 5)
#$tagger.model.cluster_loops(9 , 5)
#$tagger.model.cluster_loops(10, 5)
#$tagger.model.cluster_loops(11, 5)

#binding.pry
#$tagger.model.cluster_loops(1)


class SkNNView < Goliath::API

  #use Goliath::Rack::Render, 'json'
  use Goliath::Rack::Params
  use Goliath::Rack::Heartbeat
  #use Goliath::Rack::Formatters::JSON
  use Goliath::Rack::Validation::RequestMethod, %w(GET POST PATCH)


  def respond_json(data, code = 200)
    [code, {'Content-Type' => 'application/json; charset=utf-8'}, data.to_json ]
  end

  def response(env)
    puts "#{env['REMOTE_ADDR']}: #{env['REQUEST_URI']}"
    path = env[ 'PATH_INFO' ]
    case env[ 'PATH_INFO' ]
    when /\/public\/.*/
      [200, {'Content-Type' => 'text/html; charset=utf-8'}, File.read( path[1..-1] ) ]
    when '/cluster'
      vertex    = $tagger.model.get_vertex(env.params['vertex'])
      centroids = env.params['centroids'] || 2
      centroids = centroids.to_i
      $tagger.model.cluster_loops(vertex, centroids)
      respond_json($tagger.model.get_graph_map)
    when '/graph'
      respond_json($tagger.model.get_graph_map)
    when '/tag'
      td = TargetData.new("data/pen_test.csv")
      data = td.data[1]
      v, vertices, nearest = $tagger.tagg(data)
      closest = nearest[1..-2].map{|obj| obj.props}
      res = data.zip(closest)
      respond_json(res)
    when '/plot'
      begin
        if env.params['vertex']
          seq = env.params['seq'] ? env.params['seq'].to_i : nil
          vertex =  $tagger.model.get_vertex(env.params['vertex'])
          schema = ($tagger.model.vertex_dataset[vertex].schema.to_a + [:vertex]).map{|x| "field_" + x.to_s }.join("\t") + "\n"
          sc = $tagger.model.vertex_dataset[vertex].schema.to_a
          tsv = schema + $tagger.model.vertex_dataset[vertex].enum(sc + [:vertex], seq: seq).map{|x| x.join("\t")}.join("\n")
        else
          n = 0
          schema = ($tagger.model.vertex_dataset[1].schema.to_a + ["num"]).map{|x| "field_" + x.to_s }.join("\t") + "\n"
          tsv = schema + $tagger.model.enum.map{|x| n+=1; (x + [n]).join("\t")}.join("\n")
        end
      rescue Exception => e
        binding.pry
      end
      [200,{}, tsv ]
    end
  end
end


runner = Goliath::Runner.new(ARGV, nil)
runner.api = SkNNView.new
runner.app = Goliath::Rack::Builder.build(SkNNView, runner.api)
runner.run
