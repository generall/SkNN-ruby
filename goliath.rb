#require 'rubygems'
#require 'bundler/setup'

require 'goliath'

require_relative 'model.rb'

include SkNN


class Hello < Goliath::API
  def response(env)

    params Rack::Utils.parse_nested_query(env['QUERY_STRING'])

    [200, {}, "Hello World"]
  end
end
