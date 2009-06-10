require 'rubygems'
$:.unshift(::File.join(::File.dirname(__FILE__), "/vendor/gems/poolparty/lib/"))


module MetaVirt
  class MachineImage
    
    # default_options :storage_directory => File.dirname(__FILE__)+'../machine_images/'
    
    def initialize(opts={})
      @storage_directory = opts[:storage_directory] || File.dirname(__FILE__)+'../machine_images/'      
    end
    
    def register_new_image
      
    end
  
  end
end