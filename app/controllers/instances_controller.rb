module MetaVirt
  class InstancesController < Sinatra::Base
    configure do
      set :views, File.dirname(__FILE__) + '/../views/instances/'
    end
        # 
        # get "/" do
        #   @instances = DB[:instances]
        #   erb :home
        # end
        
    get '/' do
      Instance.all.to_json
    end
    
    get "/:instance_id" do
      inst = Instance.find(:instance_id=>params[:instance_id])
      response.status=404 if inst.nil?
      inst.to_json
    end
    
    post "/booted" do
      ifconfig_data = @env['rack.input'].read
      i_to_i = Instance.map_ip_to_interface(ifconfig_data)
      Metavirt::Log.info "Instance i_to_i: #{i_to_i.inspect} ==\n\n#{ifconfig_data}"
      net = Instance.parse_ifconfig(ifconfig_data)
      Metavirt::Log.info "Instance map_ip_to_interface: #{net.inspect}"
      instance = Instance[:status=>['booting', 'pending', 'running'],
                          :mac_address=>[net[:macs]] ] 
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
    
    delete '/:instance_id' do
      puts params.inspect
      puts CGI.unescape(params[:instance_id])
      instance = Instance[:instance_id=>CGI.unescape(params[:instance_id])].terminate!
      instance.to_json
    end
    
  end
end