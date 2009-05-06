require "rubygems"
$:.unshift File.dirname(__FILE__) + "/lib"
$:.unshift File.dirname(__FILE__)
require "lib/invisible"

# Optional Invisible libs
require "invisible/erb"
# require "invisible/erubis" Remove erb if you uncomment this
# require "invisible/haml"

Invisible.run do
  root File.dirname(__FILE__)
  use Rack::Session::Cookie
  use Rack::Static, :urls => %w(/stylesheets /javascripts /images),
                    :root => root + "/public"
  
  RACK_ENV = ENV["RACK_ENV"] ||= "development"
  # load "config/env/#{RACK_ENV}.rb", :reload => false
  case RACK_ENV
  when 'development'
    require "invisible/reloader"
    use Invisible::Reloader, self
    use Rack::ShowExceptions
    use Rack::CommonLogger
    use Rack::Lint
  when 'production'
    require 'rack/cache'
    use Rack::Cache,
      :verbose     => true,
      :metastore   => "file:/#{root}/tmp/cache/meta",
      :entitystore => "file:/#{root}/tmp/cache/body"
  when 'test'
    use Rack::Lint
  end
  
  load "app"
end
