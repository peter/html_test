require File.join(File.dirname(__FILE__), "..", "..", "..", "..", "test", "test_helper")
require File.join(File.dirname(__FILE__), "test_helper")

class Html::Test::ValidateAllTest < Test::Unit::TestCase
  def setup
    @controller = TestController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    ApplicationController.validate_all = true
    ApplicationController.validators = [:tidy]
  end

  def test_validate_all
    assert_raise(Test::Unit::AssertionFailedError) { get :untidy }
  end
end