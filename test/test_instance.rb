require File.dirname(__FILE__) + "/test_helper"

class TestInstance < Test::Unit::TestCase
  def setup
    @inst = Instance.create({ 
      :authorized_keys => 'ssh-rsa AAAAB3NzaAAABIwA...',
      :keypair_name => 'id_stuff',
      :image_id => 'ami-8b30d5e2',
      :remoter_base => 'vmrun',
      :created_at => Time.now
     })
  end
  
  def test_should_be_able_to_create
    assert @inst.created_at.nil? == false
  end
  
  def test_remoter_base
    assert @inst.remoter_base == 'vmrun'
    assert @inst.provider == ::PoolParty::Remote::Vmrun
  end
  
  def test_safe_params
    params= Instance.safe_params(:boddingtons=>'yummy', :public_ip=>'76.4.4.4')
    assert !params.keys.include?(:boddingtons)
    assert_equal '76.4.4.4', params[:public_ip]
  end
  
  def test_safe_create
    i=Instance.safe_create({:bad=>'hacked', :image_id=>'fred', :public_key=>'sshkeypub'})
    assert i.image_id = 'fred'
    assert i.created_at.nil? == false
    assert_equal i.authorized_keys, 'sshkeypub'
    assert_raises NoMethodError do i.bad end
  end
  
  def test_to_json
    parsed = JSON.parse(@inst.to_json).symbolize_keys!
    assert_equal parsed.size, @inst.values.size
    assert_equal parsed, @inst.to_hash
    @inst.values.each do |k,v|
      next if k.to_s.scan('_at').size>0
      #parsed[k] = Time.parse(parsed[k])
      assert_equal(parsed[k], v)
    end
  end
  
  def test_options
    i=Instance.create(:remoter_base_options=>{:things=>[1,2,'wow']}.to_yaml)
    assert_equal i.options, {:things=>[1,2,'wow']}
  end
  
  def test_start
    @inst.stubs(:provider).returns(MockRemoter.new)
    launched = @inst.start!
    assert launched.status == 'booting'
    assert_equal launched.instance_id, @inst.instance_id
  end
    
  def test_parse_ifconfig
    ifconfig_string = %q{
      eth0      Link encap:Ethernet  HWaddr 00:1b:fc:2e:ac:a0  
                inet addr:192.168.4.10  Bcast:192.168.4.255  Mask:255.255.255.0
                inet6 addr: fe80::21b:fcff:fe2e:aca0/64 Scope:Link
                UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
                RX packets:6164224 errors:0 dropped:0 overruns:0 frame:0
                TX packets:3006386 errors:0 dropped:0 overruns:0 carrier:0
                collisions:0 txqueuelen:0 
                RX bytes:7042505941 (7.0 GB)  TX bytes:2423030352 (2.4 GB)
                
      en1: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
      	inet6 fe80::223:6cff:fe8d:c8cc%en1 prefixlen 64 scopeid 0x8 
      	inet 10.47.90.50 netmask 0xfffffe00 broadcast 10.47.91.255
      	ether 00:23:6c:8d:c8:cc 
      	media: autoselect status: active
      	supported media: autoselect      
      }
    net = Instance.parse_ifconfig(ifconfig_string)
    p net
    assert net[:macs] == ["00:1b:fc:2e:ac:a0"]
    assert net[:ips] == ["192.168.4.10", "10.47.90.50"]
  end
    
end