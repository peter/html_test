require File.join(File.dirname(__FILE__), "..", "..", "..", "..", "test", "test_helper")
require File.join(File.dirname(__FILE__), "test_helper")

ActionController::Routing::Routes.draw do |map|
  map.connect 'test/:action', :controller => 'test'
end
ApplicationController.validate_all = false
ApplicationController.check_urls = true
ApplicationController.check_redirects = true

class Html::Test::IntegrationTest < ActionController::IntegrationTest
  def test_assert_valides_invokes_all
    get('/test/valid')
    assert_response :success

    [:tidy_errors, :w3c_errors, :xmllint_errors].each do |method|
      Html::Test::Validator.expects(method).with(@response.body)
    end
    assert_validates
  end

  def test_assert_tidy_invoked
    get('/test/valid')
    assert_response :success
    Html::Test::Validator.expects(:tidy_errors).with(@response.body)
    assert_tidy
  end
  
  def test_assert_valid_success
    get('/test/valid')
    assert_response :success
    assert_validates
  end

  def test_assert_tidy_failure
    file_string = TestController.test_file_string(:untidy)
    assert_raise(Test::Unit::AssertionFailedError) do
      assert_tidy(file_string)
    end
    assert_w3c(file_string)
    assert_xmllint(file_string)
  end
  
  def test_assert_w3c_failure
    file_string = TestController.test_file_string(:invalid)
    assert_raise(Test::Unit::AssertionFailedError) do
      assert_w3c(file_string)
    end
    assert_raise(Test::Unit::AssertionFailedError) do
      assert_xmllint(file_string)
    end
    assert_raise(Test::Unit::AssertionFailedError) do
      Html::Test::Validator.expects(:dtd).returns("doctype")
      assert_xmllint(file_string)
    end    
    assert_tidy(file_string)
  end
  
  def test_url_no_route
    TestController.any_instance.expects(:rescue_action).with() { |e| e.class == Html::Test::InvalidUrl }
    get '/test/url_no_route'
  end

  def test_url_no_route_relative
    TestController.any_instance.expects(:rescue_action).with() { |e| e.class == Html::Test::InvalidUrl }
    get '/test/url_no_route_relative'
  end
  
  def test_redirect_valid_action
    get '/test/redirect_valid_action'
    assert_response :redirect
  end
end
