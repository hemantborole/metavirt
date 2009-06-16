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
    MachineImage.any_instance.stubs(:repository).returns('/tmp')
    bundle = Rack::Test::UploadedFile.new(File.dirname(__FILE__)+'/../fixtures/fake_machine_bundle.tgz')
    post('/', :image_file => bundle)
    assert last_response.ok?
    p last_response.body
    assert File.delete "/tmp/#{last_response.body}"
  end
   
end