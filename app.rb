require 'rubygems'
$:.unshift(::File.join(::File.dirname(__FILE__), "lib"))
require 'invisible'
require 'sequel'
require 'json'

$:.unshift(::File.join(::File.dirname(__FILE__), "../../../"))
# require 'poolparty'

DEFAULT_KEY = File.read(File.expand_path("~/.ssh/id_rsa.pub"))

unless defined?(DB)
  DB = Sequel.connect("sqlite://metadata.db")
  # DB = Sequel.sqlite 
  DB.create_table(:instances) do
    primary_key :launch_id
    String :id
    String :status
    String :image_id
    String :public_ip
    String :internal_ip
    String :keypair_name
    String :public_key, :default=>DEFAULT_KEY
  end unless DB.table_exists?(:instances)
end

layout { erb(:layout) }

get "/" do
  @instances = DB[:instances]
  render erb('home')
end

get "/hello" do
  render erb(:hello), :layout=>false
end

put '/run-instance' do
  instance = DB[:instance].insert(params)
  instance.run
end

#curl http://169.254.169.254/1.0/meta-data/public-keys/0/openssl
get "/:version/meta-data/public-keys/0/openssl" do
  puts "#{@request.ip} requested keypair"
  instance = Instance.find_or_create(:internal_ip=>@request.ip)
  render instance.public_key.to_s, :layout=>:none
end

put '/meta-data/public-keys/0/openssl' do
  
end

put "/meta-data/:key" do
  instance = DB[:instances].first(:internal_ip=>@request.ip) || DB[:instances].insert(:internal_ip=>@request.ip)
  render instance, :layout => :none
end




