ENV["RACK_ENV"] = "test"
require 'rubygems'
# require "invisible/mock"
require "test/unit"
require 'mocha'
require 'sequel'
require 'uuid'

require File.dirname(__FILE__)+"/../db/migrations/01_initialize_db.rb"
DB = Sequel.sqlite unless defined?(DB)
InitializeDB.apply(DB, :up) unless DB.tables.include?(:version)

require File.dirname(__FILE__) + "/../app.rb"

class Test::Unit::TestCase
  include MetaVirt
  # include Invisible::MockMethods
end

class MockRemoter
  def self.generate_hash
    uuid = UUID.generate.gsub(/-/, '')
    mac = Array.new(6)
    mac = mac.each_with_index{|v, i| mac[i]=uuid[i*2..i*2+1] }.join(':')
    { :status => 'booting',
      :mac_address => mac,
      :public_ip => "75.#{rand 9}.#{rand 9}.#{rand 9}.#{rand 9}",
      :internal_ip => "10.#{rand 9}.#{rand 9}.#{rand 9}.#{rand 9}",
      :instance_id => "i_#{uuid[0..8]}",
      :keypair => 'id_rsa'
    }
  end
  def launch_new_instance!(o={})
    @inst = self.class.generate_hash
  end
  def terminate_instance(id)
  end
  def describe_instance(id)
    @inst ||= self.class.generate_hash
  end
  def describe_instances(o={})
    @inst ||= self.class.generate_hash
  end
end
