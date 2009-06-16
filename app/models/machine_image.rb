require 'rubygems'
require 'sha1'
$:.unshift(::File.join(::File.dirname(__FILE__), "/vendor/gems/poolparty/lib/"))


module MetaVirt
  class MachineImage
    
    # default_options :storage_directory => File.dirname(__FILE__)+'../machine_images/'
    
    def initialize(options={})
      @repository = options[:repository] || File.dirname(__FILE__)+'../machine_images/'
    end
    
    def register_new_image(opts={})
      # {:name => }
    end
  
  end
end