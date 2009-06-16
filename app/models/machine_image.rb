require 'rubygems'
require 'uuid'
require 'fileutils'
$:.unshift(::File.join(::File.dirname(__FILE__), "/vendor/gems/poolparty/lib/"))


module MetaVirt
  class MachineImage #< Sequl::Model
    
    attr_reader :repository
    attr_accessor :name
    
    @repository =  File.dirname(__FILE__)+'/../../machine_images/'

    class << self
      attr_reader :repository
    end

    def initialize(options={})
      @repository = options[:repository] || self.class.repository
    end
    
    def register_image(opts={})
      options = {:file =>nil}.merge! opts
      @name = "mvi_#{UUID.generate[0..7]}"
      FileUtils.copy_file(options[:file].path, "#{repository}/#{@name}")
    end
  
    def self.list
      Dir["#{repository}/mvi_*"].collect {|f| f.split('/').last }
    end

  end
end
