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

require "log"

%w(columbus).each do |lib|
  require "#{File.dirname(__FILE__)}/vendor/gems/#{lib}/lib/#{lib}"
end

Dir[File.dirname(__FILE__)+"/lib/*.rb"].each{|lib| require lib}
Dir[File.dirname(__FILE__)+"/lib/*/*.rb"].each{|lib| require lib}

#NOTE: This is only needed in the models, not in this file.
$:.unshift(::File.join(::File.dirname(__FILE__), "../poolparty/lib/"))
require "poolparty"

DB = Sequel.connect("sqlite://db/metavirt.db") unless defined?(DB)
Dir[File.dirname(__FILE__)+"/models/*"].each{|model| require model}

module MetaVirt
  class MetadataServer < Sinatra::Base
    SERVER_URI='http://192.168.248.1:3000' unless defined? SERVER_URI
    
    #TODO: add support for accepting clouds.rb from POST data
    # require "/Users/mfairchild/Code/poolparty_fresh/examples/metavirt_cloud.rb"
    # clouds.keys.each{|name| MetaVirt::Cloud.find_or_create(:name=>name.to_s) }
    
    configure do
      Metavirt::Log.init "metavirt", "#{Dir.pwd}/log"
      
      unless $TESTING
        Columbus::Server.name = "columbus-server"
        Columbus::Server.description = ENV["IP"] ? ENV["IP"] : Instance.parse_ifconfig(%x{ifconfig})[:ips].values.last
        
        @pid = fork do
           Signal.trap(:USR1) {puts "STOPPING on USR1"; exit()}
           Signal.trap(:TERM) {puts "STOPPING on TERM"; exit()}
           Signal.trap(:INT) {puts "STOPPING on INT"; exit()}
           while true do
             Columbus::Server.announce("vmnet8")
             sleep(90)
           end           
         end
         Process.detach(@pid)
      end
    end
    
    get "/" do
      @instances = DB[:instances]
      erb :home
    end
    
    get '/boot_script' do
      # @host = "#{@env['rack.url_scheme']}//#{@env['HTTP_HOST']}".strip
      @response['Content-Type']='text/plain'
      erb :boot_script, :layout=>:none
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
    
    get "/instance/:instance_id" do
      Instance.find(:instance_id=>params[:instance_id]).to_json
    end
    
    put( /\/run-instance|\/launch_new_instance/ ) do
      params =  JSON.parse(@env['rack.input'].read).symbolize_keys!
      instance = Instance.safe_create(params)
      launched = instance.start!
      puts "Started instance #{launched.inspect}\n"
      instance.to_json
    end
    
    post "/instances/booted" do
      ifconfig_data = @env['rack.input'].read
      i_to_i = Instance.map_ip_to_interface(ifconfig_data)
      Metavirt::Log.info "Instance i_to_i: #{i_to_i.inspect} ==\n\n#{ifconfig_data}"
      net = Instance.parse_ifconfig(ifconfig_data)
      Metavirt::Log.info "Instance map_ip_to_interface: #{net.inspect}"
      instance = Instance[:status=>['booting', 'pending', 'running'],
                          :mac_address=>net[:macs]]
      Metavirt::Log.info "Instance is: #{instance.inspect}"
      return @response.status=404 if !instance
      instance.update(:status=>'running',
                      :internal_ip=>(net[:ips]["eth0"] rescue nil),
                      :public_ip=>(net[:ips]["eth0"] rescue nil),
                      :ifconfig => net[:ifconfig_data]
                     )
      Metavirt::Log.info "Instance updated: #{instance.inspect}"
      instance.authorized_keys
    end
    
    delete '/instance/:instance_id' do
      puts params.inspect
      puts CGI.unescape(params[:instance_id])
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