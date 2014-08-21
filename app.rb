# encoding: utf-8
require 'rack'
require 'rack/mobile-detect'
# require 'rack/protection'
# require 'rack/parser'
require 'roda'
require 'haml'
require 'sass'
require 'json'


class RodaApp < Roda
  plugin :multi_route
  plugin :render, :engine=>'haml'
  render_opts[:cache] = ENV['RACK_ENV'] != 'development'
  plugin :view_subdirs
  # plugin :all_verbs
  # plugin :default_headers, 'Content-Type' => 'application/json'
  # plugin :indifferent_params
  plugin :halt

  use Rack::Static, :urls => ["/assets/images", "/assets/js"],
                    :root => "public"
  use Rack::MobileDetect
  use Rack::Session::Cookie, :secret => ENV['SECRET'],
                             :old_secret => ENV['OLD_SECRET'],
                             # :key => 'rack.session',
                             # :domain => 'foo.com',
                             # :expire_after => 3600*24*90,
                             :path => '/'

end

require_relative 'routes/init'

# require_relative 'helpers/init'
# require_relative 'lib/init'
require_relative 'models/init'
