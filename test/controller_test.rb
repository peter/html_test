require File.join(File.dirname(__FILE__), "..", "..", "..", "..", "test", "test_helper")
require File.join(File.dirname(__FILE__), "test_helper")

ActionController::Routing::Routes.draw do |map|
  map.connect 'test/:action', :controller => 'test'
end

class Html::Test::ControllerTest < Test::Unit::TestCase
  def setup
    @controller = TestController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    ActionController::Base.validate_all = false
    ActionController::Base.check_urls = true
    ActionController::Base.check_redirects = true
    Html::Test::Validator.tidy_ignore_list = []
    Html::Test::UrlChecker.any_instance.stubs(:rails_public_path).returns(File.join(File.dirname(__FILE__), "public"))
  end
  
  def test_assert_validates_success
    get :valid
    assert_response :success
    assert_validates # Should validate tidy, w3c, and xmllint
  end
  
  def test_assert_tidy_failure
    get :untidy
    assert_response :success
    assert_raise(Test::Unit::AssertionFailedError) do
      assert_tidy
    end
    assert_w3c
    assert_xmllint
  end
  
  def test_assert_w3c_failure
    get :invalid
    assert_response :success
    assert_raise(Test::Unit::AssertionFailedError) do
      assert_w3c
    end
    assert_raise(Test::Unit::AssertionFailedError) do
      assert_xmllint
    end
    assert_tidy
  end
  
  def test_url_no_route
    assert_raise(Html::Test::InvalidUrl) do
      get :url_no_route
    end
  end

  def test_url_no_action
    assert_raise(Html::Test::InvalidUrl) do
      get :url_no_action
    end
  end
 
 # TODO: figure out why those tests don't work 
#  def test_url_rhtml_template_exists
#    get :rhtml_template
#  end
  
#  def test_url_rxml_template_exists
#    get :rxml_template    
#  end

  def test_url_action_no_template
    get :action_no_template
  end

  def test_redirect_no_action
    assert_raise(Html::Test::InvalidUrl) do
      get :redirect_no_action
    end    
  end
  
  def test_redirect_valid_action
    get :redirect_valid_action
    assert_response :redirect
  end

  def test_image_file_exists
    get :image_file_exists
    assert_response :success
  end

  def test_image_does_not_exist
    assert_raise(Html::Test::InvalidUrl) do
      get :image_file_does_not_exist
    end
  end

  def test_urls_to_resolve
    checker = Html::Test::UrlChecker.new(@controller)
    checker.stubs(:response_body).returns(<<-HTML
      <a href="anchor_url">hej</a>
      Some text and <div>markup</div>
      <img src="image_url"/>
      Some more text
      <form action="form_url">
        Some text
      </form>
    HTML
    )
    assert_equal(%w(anchor_url form_url image_url), checker.send(:urls_to_check).sort)
  end
end
