# encoding: utf-8
require_relative 'admin'
require_relative 'main'
require_relative 'auth'

class RodaApp < Roda
  route do |r|
    puts r.full_path_info
    puts @_request.request_method
    @user_id = (r.session['user_id'] || r.cookies['user_id'] || '')
    r.on 'admin' do
      r.route 'admin'
    end
    r.on 'auth' do
      r.route 'auth'
    end
    r.on 'assets' do
      # puts 'assets'
      r.is "styles", :extension => "css" do |file|
        response['Content-Type'] = 'text/css'
        # puts 'styles'
        r.get do
          # puts file
          set_view_subdir "scss"
          render file, engine: :scss, ext: :scss
        end
      end
      # r.is 'js', extension: 'js' do |file|
      #   response['Content-Type'] = 'text/css'
      #   r.get do
      #     run Rack::File.new("")
      #   end

      # end
    end
    stuff = ['apple-touch-icon-precomposed.png', 'apple-touch-icon-precomposed.png/', 'apple-touch-icon.png', 'apple-touch-icon.png/', 'favicon.ico', 'favicon.ico/']
    r.get stuff do
      nil
    end
    r.route 'main'
  end
end
