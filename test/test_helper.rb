class TestController < ActionController::Base
  prepend_view_path(File.dirname(__FILE__))

  layout nil
  def valid; render :file => TestController.test_file(:valid) end
  def untidy; render :file => TestController.test_file(:untidy) end
  def invalid; render :file => TestController.test_file(:invalid) end

  def url_no_route
    render :text => %Q{<a href="/norouteforthisurl">No route</a>}
  end

  def url_no_route_relative
    render :text => %Q{<a href="norouteforthisurl">No route</a>}    
  end

  def url_no_action
    render :text => %Q{<a href="/test/thisactiondoesnotexist">no action</a>}
  end

  def action_no_template
    render :text => %Q{<a href="/test/valid">valid</a>}
  end

  def redirect_no_action
    redirect_to :action => 'thisactiondoesnotexist'
  end

  def redirect_valid_action
    redirect_to :action => 'valid'
  end

  def image_file_exists
    render :text => %Q{<img src="/image.jpg?23049829034"/>}
  end

  def image_file_does_not_exist
    render :text => %Q{<img src="/image2.jpg?23049829034"/>}
  end

  def self.test_file(action)
    File.join(File.dirname(__FILE__), "#{action}.html")
  end

  def self.test_file_string(action)
    IO.read(test_file(action))
  end
  
  # Re-raise errors caught by the controller.
  def rescue_action(e)
    raise e
  end
end
