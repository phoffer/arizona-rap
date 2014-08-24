# encoding: utf-8
require 'rack'
require 'rack/mobile-detect'
# require 'rack/protection'
# require 'rack/parser'

require 'sinatra/base'
require 'sinatra/namespace'

require 'haml'
require 'sass'
require 'json'


class Rap < Sinatra::Base
  register Sinatra::Namespace
  enable :sessions
  set :session_secret, ENV['SECRET']
  # disable :logging
  set :haml, format: :html5

  set :javascripts, []
  set :stylesheets, []

  use Rack::MobileDetect
  # use Rack::Session::Cookie, :secret => ENV['SECRET'],
  #                            :old_secret => ENV['OLD_SECRET'],
  #                            # :key => 'rack.session',
  #                            # :domain => 'foo.com',
  #                            # :expire_after => 3600*24*90,
  #                            :path => '/'

  configure :production do
    # require 'newrelic_rpm'
    # use Rack::SslEnforcer, :only => [%r{^/user/}, %r{^/log}, %r{^/signup}, %r{^/admin/}]
    set :haml, { :ugly=>true }
    set :clean_trace, false

  end

  configure :development do
    # set :public_folder,
  end
  before do
    @js = []
    @css = []
    @user_id = (session[:user_id] || request.cookies['user_id'] || '')
  end

  helpers do
    include Rack::Utils
    alias_method :h, :escape_html

  end
end


# require_relative 'helpers/init'
require_relative 'lib/init'
require_relative 'models/init'
require_relative 'routes/init'
Rap.run! if __FILE__ == $0
