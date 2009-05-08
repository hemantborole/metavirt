require "rubygems"
require 'rack'
# require 'rack/contrib'
require File.dirname(__FILE__)+"/app.rb"

# use Rack::BounceFavicon
use Rack::Session::Cookie
use Rack::Static, :urls => %w(/stylesheets /javascripts /images),
                  :root => File.dirname(__FILE__) + "/public"
  
RACK_ENV = ENV["RACK_ENV"] ||= "development"
case RACK_ENV
when 'development'
  use Rack::Reloader
  use Rack::ShowExceptions
  # use Rack::PostBodyContentTypeParser
  use Rack::CommonLogger
  use Rack::Lint
# when 'production'
# when 'test'
#   use Rack::Lint
end
    
run MetaVirt::MetadataServer