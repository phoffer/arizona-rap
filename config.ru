$stdout.sync = true
require ::File.join( ::File.dirname(__FILE__), 'app' )
# require 'rack/ssl-enforcer'
# use Rack::SslEnforcer
# use Rack::Parser, :parsers => {
#   'application/json' => proc { |body| Oj.load(body) },
#   # 'application/xml'  => proc { |body| MyCustomXmlEngine.decode body },
#   # 'application/roll' => proc { |body| 'never gonna give you up'     }
# }

run RodaApp.app

