require "rubygems"
require 'ruby-debug'
require 'pp'
$:.unshift File.dirname(__FILE__) + "/lib"
$:.unshift File.dirname(__FILE__)
# require 'rack_response_callbacks'
# require 'invisible'
# require "invisible/erb"
# require "invisible/erubis" Remove erb if you uncomment this
# require "invisible/haml"
require 'sinatra'

require 'sequel'
require 'json'
require 'cgi'

Dir[File.dirname(__FILE__)+"/lib/*.rb"].each{|lib| require lib}
Dir[File.dirname(__FILE__)+"/lib/*/*.rb"].each{|lib| require lib}

#NOTE: This is only needed in the models, not in this file.
$:.unshift(::File.join(::File.dirname(__FILE__), "../poolparty/lib/"))
require "~/Code/poolparty/lib/poolparty"

DB = Sequel.connect("sqlite://db/metavirt.db") unless defined?(DB)
Dir[File.dirname(__FILE__)+"/models/*"].each{|model| require model}

module MetaVirt
  class MetadataServer < Sinatra::Base
    SERVER_URI='http://172.16.68.2:3000' unless defined? SERVER_URI
    
    #TODO: add support for accepting clouds.rb from POST data
    # require "/Users/mfairchild/Code/poolparty_fresh/examples/metavirt_cloud.rb"
    # clouds.keys.each{|name| MetaVirt::Cloud.find_or_create(:name=>name.to_s) }

    get "/" do
      @instances = DB[:instances]
      erb :home
    end
    
    get '/boot_script' do
      # @host = "#{@env['rack.url_scheme']}//#{@env['HTTP_HOST']}".strip
      @response['Content-Type']='text/plain'
      erb :boot_script, :layout=>:none
    end

    get "/hello" do
      erb :hello, :layout=>:none
    end
    
    get '/pools/' do
      erb "#{pools.keys.inspect}"
    end

    get '/clouds/' do
      @clds = clouds
      erb :clouds
    end
  
    get '/cloud/:name' do
      @cld = clouds[params[:name].to_sym]
      @cld.to_properties_hash.to_json
    end

    get '/instances/' do
      Instance.all.to_json
    end
    
    get "/instance/:id" do
      Instance.find(:instance_id=>CGI.unescape(params[:instance_id])).to_json
    end
    
    put( /\/run-instance|\/launch_new_instance/ ) do
      params =  JSON.parse(@env['rack.input'].read).symbolize_keys!
      instance = Instance.safe_create(params)
      launched = instance.start!
      instance.to_json
    end
    
    post "/instances/booted" do
      net = Instance.parse_ifconfig(ifconfig_data = @env['rack.input'].read)
      instance = Instance[:status=>['booting', 'pending', 'running'],
                          :mac_address=>net[:macs]]
      return @response.status=404 if !instance
      instance.update(:status=>'running',
                      :internal_ip=>(net[:ips].first rescue nil),
                      :public_ip=>(net[:ips].last rescue nil),
                      :ifconfig => net[:ifconfig_data]
                     )
      instance.authorized_keys
    end
    
    delete '/instance/:instance_id' do
      instance = Instance[:instance_id=>CGI.unescape(params[:instance_id])].terminate!
      instance.to_json
    end

    #curl http://169.254.169.254/1.0/meta-data/public-keys/0/openssl
    get "/:version/meta-data/public-keys/0/openssl" do
      instance = Instance.find(:internal_ip=>@request.ip)
      instance ? instance.authorized_keys.to_s : @response.status=404
    end

    put '/meta-data/public-keys/0/openssl' do
    end

  end    
end

include MetaVirt #just to make my irb sessions easier