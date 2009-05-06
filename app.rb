require 'rubygems'
$:.unshift(::File.join(::File.dirname(__FILE__), "lib"))
require 'invisible'
# require 'sinatra'
require 'sequel'
require 'json'

$:.unshift(::File.join(::File.dirname(__FILE__), "../../../"))
# require 'poolparty'

default_key = File.read(File.expand_path("~/.ssh/id_rsa.pub"))
DB = Sequel.connect("sqlite://metadata.db") unless defined?(DB)

MetadataServer = Invisible.new do
  layout { erb(:layout) }  
  get "/" do
    @instances = DB[:instances]
    render erb('home')
  end

  get "/hello" do
    render erb(:hello), :layout=>false
  end
  
  get '/test' do
    puts "testing"
    render 'hello there'
  end

  put '/run-instance' do
    instance = DB[:instance].insert(params)
    instance.run
  end

  #curl http://169.254.169.254/1.0/meta-data/public-keys/0/openssl
  get "/:version/meta-data/public-keys/0/openssl" do
    puts "#{@request.ip} requested keypair"
    instance = Instance.find_or_create(:internal_ip=>@request.ip)
    render instance.public_key.to_s, :layout=>:none
  end

  put '/meta-data/public-keys/0/openssl' do

  end

  put "/meta-data/:key" do
    instance = DB[:instances].first(:internal_ip=>@request.ip) || DB[:instances].insert(:internal_ip=>@request.ip)
    render instance, :layout => :none
  end
  
end