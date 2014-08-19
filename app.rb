# encoding: utf-8
require 'rack'
# require 'rack/protection'
# require 'rack/parser'
require 'roda'
require 'haml'
require 'json'


class RodaApp < Roda
  plugin :multi_route
  plugin :render, :engine=>'haml'
  plugin :all_verbs
  # plugin :default_headers, 'Content-Type' => 'application/json'
  # plugin :indifferent_params
  plugin :halt

  # use Rack::Session::Cookie, :secret => 'change_me',
  #                            :old_secret => 'also_change_me'
                             # :key => 'rack.session',
                             # :domain => 'foo.com',
                             # :path => '/',
                             # :expire_after => 2592000,

end

require_relative 'routes/init'

# require_relative 'helpers/init'
# require_relative 'lib/init'
require_relative 'models/init'
