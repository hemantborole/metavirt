require File.dirname(__FILE__) + "/test_helper"

class AppTest < Test::Unit::TestCase
  def test_should_get_root
    assert get("/").ok?
  end
  
  def test_should_get_key
    
  end
end