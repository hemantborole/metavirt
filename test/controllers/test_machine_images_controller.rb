require File.dirname(__FILE__) + "/../test_helper"
require 'rack/test'

class TestMachineImagesController < Test::Unit::TestCase
  include Rack::Test::Methods
  
  def app
    MachineImagesController.new
  end
  
  def test_new_image
    get('/new')
    assert last_response.ok?
  end

  def test_post
    MachineImage.stubs(:repository).returns('/tmp')
    assert_equal '/tmp', MachineImage.repository 
    assert_equal '/tmp', MachineImage.new.repository
    bundle = Rack::Test::UploadedFile.new(File.dirname(__FILE__)+'/../fixtures/fake_machine_bundle.tgz')
    post('/', :image_file => bundle)
    assert last_response.ok?
    body =  JSON.parse(last_response.body).first
    assert MachineImage.list.include? body
    assert File.delete "/tmp/#{body}"
  end
   
end
