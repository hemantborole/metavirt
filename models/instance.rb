module MetaVirt
  class Instance < Sequel::Model
    
    def self.defaults
      { :authorized_keys => '',
        :keypair => '',
        :image_id => nil,
        :remoter_base => :vmrun,
        :created_at => Time.now,
        :remoter_base_options => nil
       }
    end
    
    def start!
      opts = to_hash
      opts.delete(:remoter_base_options)
      opts.merge! options if options
      launched = provider.launch_new_instance!(opts).symbolize_keys!
      set_only launched, Instance.columns
      launched_at = Time.now
      mac_address = launched.mac_address, 
      status      = 'booting'
      save
    end
    
    def terminate!
      provider.terminate_instance!(instance_id)
      update(:status=>'terminated', :terminated_at=>Time.now)      
    end
    
    def self.generate_mac_address
      require 'uuid'
      uuid = UUID.generate.gsub(/-/, '')
      mac = Array.new(6)
      mac_address = mac.each_with_index{|v, i| mac[i]=uuid[i*2..i*2+1] }.join(':')
    end

    def to_hash
      hsh = columns.inject({}){|h, k| h[k]=values[k];h}
      hsh[:ip]=public_ip
      hsh
    end
    
    # Dump to html
    def to_xoxo
      require 'facets/xoxo'
      XOXO.dump self.to_hash
    end
    
    # The remoter_base as a ruby object
    def provider
      @provider ||= find_constant( remoter_base, ::PoolParty::Remote )
    end
    
    def options
      remoter_base_options.nil? ? nil : YAML.load(remoter_base_options)
    end
    
    def self.parse_ifconfig(str)
      ips = str.match(/inet addr:(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/i).captures
      macs = str.match(/Ether.*((?:[0-9a-f]{2}[:-]){5}[0-9a-f]{2})/i).captures
      {:ips=>ips, :macs=>macs}
    end
    def parse_ifconfig
      self.parse_ifconfig(ifconfig)
    end
    
    def self.safe_create(params={})
      safe_params = Instance.defaults.merge(default_params(params))
      safe_params[:authorized_keys] << params[:public_key].to_s
      safe_params[:remoter_base_options] = params[:remoter_base_options].to_yaml if params[:remoter_base_options]
      inst = Instance.create(safe_params)
      #set instance_id to id temporarily until real instance_id is returned from remoter_base
      inst.update(:instance_id=>inst.id)  
      inst
    end

    def to_json
      values.to_json
    end
    
    def self.to_json(filters=nil)
      if filters
        rows = dataset.filter(filters)
      else
        rows = dataset.all
      end
      rows.collect{|row| row.values}.to_json
    end
    
    private
    def self.default_params(params={})
      Instance.defaults.inject({}){|sum, (k,_v)| sum[k]=params[k] if params[k];sum}
    end
    # Take a string and return a ruby object if  found in the namespace.
    def find_constant(name, base_object=self)
      begin
        const = base_object.constants.detect{|cnst| cnst == camelcase(name)}
        base_object.module_eval const
      rescue Exception => e
        puts "#{name.camelcase} is not defined. #{e}"
        nil
      end
    end
    
    def camelcase(str)
      str.gsub(/(^|_|-)(.)/) { $2.upcase }
    end
        
    
  end
end