require 'rubygems'
require 'bundler/setup'

require 'goliath'
require 'json'

require_relative 'tagger.rb'

include SkNN

$tagger = Tagger.new
$tagger.learn(ARGV[0])


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
    when '/graph'
      respond_json($tagger.model.get_graph_map)
    when '/plot'
      [200,{},"Not implemented"]
    end
  end
end


runner = Goliath::Runner.new(ARGV, nil)
runner.api = SkNNView.new
runner.app = Goliath::Rack::Builder.build(SkNNView, runner.api)
runner.run
