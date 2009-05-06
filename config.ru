require "rubygems"
$:.unshift File.dirname(__FILE__) + "/lib"
$:.unshift File.dirname(__FILE__)
require "lib/invisible"
require "invisible/erb"
# require "invisible/erubis" Remove erb if you uncomment this
# require "invisible/haml"

require File.dirname(__FILE__)+"/app.rb"

use Rack::Session::Cookie
use Rack::Static, :urls => %w(/stylesheets /javascripts /images),
                  :root => MetadataServer.root + "/public"
  
  # RACK_ENV = ENV["RACK_ENV"] ||= "development"
  # # load "config/env/#{RACK_ENV}.rb", :reload => false
  # case RACK_ENV
  # when 'development'
  #   require "invisible/reloader"
  #   use Invisible::Reloader, self
  #   use Rack::ShowExceptions
  #   use Rack::CommonLogger
  #   use Rack::Lint
  # when 'production'
  # when 'test'
  #   use Rack::Lint
  # end
  
run MetadataServer