require File.dirname(__FILE__) + "/test_helper"

class TestMachineImage < Test::Unit::TestCase
  def setup
   
  end
  
  def test_should_be_able_register_a_new_image
  end
  
  # def test_should_be_able_to_create_new_domain_xml_from_image
  # end
  # 
  # def test_should_copy_image_to_instance_run_space
  # end
  # 
  # def test_should_run_copy_of_image
  #   jaunty = MachineImage.create(:name=>'jaunty19', :root_disk_image=>'/tmp/jaunyt.qcow', :definition=>File.read('/tmp/jaunty.xml'))
  #   Instance.run(:image_id=>'jaunty19').should do |instance|
  #     copy jaunty.root_disk_image to instance.working_dir
  #     create a new instance
  #     create a new instance.id.xml
  #     define a new domain thru virsh define instance.id.xml
  #     instance.should be_sshable
  #     jaunty.destroy.should terminate image
  #   end
  # end
  
  

end