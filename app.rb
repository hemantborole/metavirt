require "rubygems"
require 'ruby-debug'
require 'pp'
$:.unshift File.dirname(__FILE__) + "/lib"
$:.unshift File.dirname(__FILE__)
require 'rack_response_callbacks'
# require 'invisible'
# require "invisible/erb"
# require "invisible/erubis" Remove erb if you uncomment this
# require "invisible/haml"
require 'sinatra'

require 'sequel'
require 'json'

$:.unshift(::File.join(::File.dirname(__FILE__), "../../../"))
require '/Users/mfairchild/Code/poolparty_fresh/lib/poolparty'

DB = Sequel.connect("sqlite://db/metavirt.db") unless defined?(DB)
Dir[File.dirname(__FILE__)+"/models/*"].each{|model| require model}

module MetaVirt
  class MetadataServer < Sinatra::Base
    SERVER_URI='http://172.16.68.2:3000' unless defined? SERVER_URI
    #TODO: add support for using the remoter base specified in the request
    REMOTER_BASE = PoolParty::Remote::Vmrun unless defined? REMOTER_BASE
    
    #TODO: add support for accepting clouds.rb from POST data
    require "/Users/mfairchild/Code/poolparty_fresh/examples/metavirt_cloud.rb"
    clouds.keys.each{|name| MetaVirt::Cloud.find_or_create(:name=>name.to_s) }

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
      Instance.to_json
    end
    
    get "/instance/:id" do
      Instance.find(:id=>params[:id]).to_json
    end
    
    put /\/run-instance|\/launch_new_instance/ do
      params =  JSON.parse(@env['rack.input'].read).to_mash
      instance = Instance.safe_create(params)
      # instance.authorized_keys = clouds[params[:cloud].to_sym].keypair.public_key_string
      launched = (REMOTER_BASE.launch_new_instance!(params)).to_mash
      puts "\nLaunced Instance:\n--------------\n#{launched.inspect}\n----------------"
      instance.update :instance_id=> launched.instance_id, :mac_address=>launched.mac_address, :status=>'booting'
      instance.to_json
    end
    
    post "/instances/booted" do
      ifconfig_data = @env['rack.input'].read
      ips =  ifconfig_data.match(/inet addr:(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/i).captures
      macs = ifconfig_data.match(/Ether.*((?:[0-9a-f]{2}[:-]){5}[0-9a-f]{2})/i).captures
      #TODO: be smarter about picking a matching instance.  Possibly use mac address
      # or verify with ping or sshing in before saving.
      instance = Instance[:status=>['booting', 'pending', 'running'],
                          :mac_address=>macs]
      return @response.status=404 if !instance
      instance.update(:status=>'running', 
                      :internal_ip=>(ips.first rescue nil),
                      :public_ip=>(ips.last rescue nil)
                     )
      instance.authorized_keys
    end
    
    delete '/instance/:id' do
      instance = Instance[params[:id]]
      result = REMOTER_BASE.terminate_instance!(:id=>params[:id])
      instance.update(:status=>'terminated')      
      result.to_json
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