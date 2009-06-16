require 'rubygems'
require 'uuid'
require 'fileutils'
$:.unshift(::File.join(::File.dirname(__FILE__), "/vendor/gems/poolparty/lib/"))


module MetaVirt
  class MachineImage #< Sequl::Model
    
    attr_reader :repository
    attr_accessor :name
    
    def initialize(options={})
      @repository = options[:repository] || File.dirname(__FILE__)+'/../../machine_images/'
    end
    
    def register_image(opts={})
      options = {:file =>nil}.merge! opts
      @name = "mvi_#{UUID.generate[0..7]}"
      FileUtils.copy_file(options[:file].path, "#{repository}/#{@name}")
    end
  
  end
end