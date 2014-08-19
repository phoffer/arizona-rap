# encoding: utf-8
require_relative 'admin'
require_relative 'main'

class RodaApp < Roda
  route do |r|
    r.route 'main'
    r.on 'admin' do
      r.route 'admin'
    end
  end
end
