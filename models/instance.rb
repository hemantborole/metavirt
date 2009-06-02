require 'rubygems'
require 'uuid'

module MetaVirt
  class Instance < Sequel::Model
    # create_table(:instances) do
    #   primary_key :id
    #   Integer :rank
    #   String :instance_id
    #   String :image_id
    #   String :status, :default=>'pending'
    #   String :public_ip
    #   String :internal_ip
    #   String :mac_address
    #   String :keypair
    #   String :authorized_keys
    #   String :remoter_base
    #   String :cloud
    #   String :pool
    #   Timestamp :created_at
    #   Timestamp :updated_at
    #   Timestamp :launched_at
    #   Timestamp :booted_at
    #   Timestamp :terminated_at
    #   Text :ifconfig
    #   Text :remoter_base_options
    # end
    
    def self.defaults
      { :authorized_keys => '',
        :keypair_name => '',
        :image_id => nil,
        :remoter_base => :vmrun,
        :created_at => Time.now,
        :remoter_base_options => nil,
        :instance_id => generate_instance_id,
        :vmx_file => nil,
        :status => 'booting' 
       }
    end
    
    def self.safe_create(params={})
      safe_params = Instance.defaults.merge(default_params(params))
      safe_params[:authorized_keys] << params[:public_key].to_s
      safe_params[:remoter_base_options] = params[:remote_base].to_yaml if params[:remote_base]
      Instance.create(safe_params)
    end
    
    def start!
      opts = self.to_hash
      
      # remove remoter_base_options yaml string and yaml load into options
      opts.delete(:remoter_base_options)
      opts.merge! options if options
      
      launched = provider.launch_new_instance!(opts).symbolize_keys!
      if remoter_base=='vmrun'
        launched.delete(:instance_id)  # we want to use the metavirt id
        launched.delete(:status)  #vmrun always returns 'running' so we override it here untill node checks in
      end
      set Instance.safe_params(launched)
      launched_at = Time.now
      mac_address = launched.mac_address, 
      status      = 'booting'
      save
    end
    
    def terminate!
      if remoter_base == 'vmrun'
        provider.terminate_instance!(:vmx_file=>vmx_file)
      else
        provider.terminate_instance!(:instance_id=>instance_id)
      end
      update(:status=>'terminated', :terminated_at=>Time.now)      
    end

    def to_hash
      hsh = columns.inject({}){|h, k| h[k]=values[k];h}
      hsh[:ip]=public_ip
      hsh[:keypair] = keypair_name
      hsh.reject {|k,v| v.nil? || (v.empty? if v.respond_to? :empty)}
    end
    
    def to_json
      to_hash.to_json
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
      # ips = str.match(/inet (addr:)?(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/i).captures
      macs = str.match(/Ether.*((?:[0-9a-f]{2}[:-]){5}[0-9a-f]{2})/i).captures
      {:ips=>parse_ips_from_str(str), :macs=>macs}
    end
    def parse_ifconfig
      self.parse_ifconfig(ifconfig)
    end
    
    def self.parse_ips_from_str(str)
      out = []
      str.split("\n").collect do |line|          
        ip = line.match(/inet (addr:)?(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/i)
        if ip
          ip = ip.captures.compact.to_s.gsub(/addr:/, '')
          out << ip
        end
      end
      out
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
    def self.safe_params(params={})
      Instance.columns.inject({}){|sum, (k,_v)| sum[k]=params[k] if params[k];sum}
    end
    
    def self.generate_instance_id
      uuid = UUID.generate.gsub(/-/, '')
      "mv_#{uuid[0..8]}"
    end
    def generate_instance_id
      self.class.generate_instance_id
    end
    
    def self.generate_mac_address
      require 'uuid'
      uuid = UUID.generate.gsub(/-/, '')
      mac = Array.new(6)
      mac_address = mac.each_with_index{|v, i| mac[i]=uuid[i*2..i*2+1] }.join(':')
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

