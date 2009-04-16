require File.join(File.dirname(__FILE__), "..", "..", "..", "..", "test", "test_helper")
require File.join(File.dirname(__FILE__), "test_helper")
require 'ostruct'

# Stub out the HTTP requests
module Net
  class HTTP
    @@test_requests = []
    cattr_accessor :test_requests
    
    @@test_with_links = false
    cattr_accessor :test_with_links    
    
    def self.get_response(uri)
      self.test_requests << uri.to_s

      if uri.path =~ /valid_links/ or test_with_links
        file = :valid_links
      else
        file = :valid
      end
      test_with_links = false
      return OpenStruct.new({
        :body => TestController.test_file_string(file),
        :code => "200",
        :header => {'content-type' => 'text/html'}
        })
    end
  end
end

class Html::Test::LinkValidatorTest < Test::Unit::TestCase
  def setup
    Net::HTTP.test_requests = []
  end
  
  def test_parse_command_line
    # Missing URL
    assert_raise(RuntimeError) { Html::Test::LinkValidator.parse_command_line(["--no-follow"]) }

    # Missing skip patterns
    options_no_skip = ["http://my.url.com", "--no-follow", "--validators", "w3c,tidy,xmllint",
      "--no-external", "--dtd", "some.dtd", "--only", "some/url", "--skip"]
    assert_raise(OptionParser::MissingArgument) do
      Html::Test::LinkValidator.parse_command_line(options_no_skip.dup)
    end

    # All options - valid
    assert_equal({
      :follow_links => false,
      :validators => ["w3c", "tidy", "xmllint"],
      :follow_external => false,
      :dtd => "some.dtd",
      :only_pattern => Regexp.new("some/url"),
      :skip_patterns => [/pattern1/, /pattern2/]
    }, Html::Test::LinkValidator.parse_command_line(options_no_skip << "pattern1,pattern2"))
  end

  def test_default_options
    url = "http://localhost:3000"
    validator = Html::Test::LinkValidator.new(url)
    
    assert_equal url, Net::HTTP.test_requests.first
    assert_equal 1, Net::HTTP.test_requests.size

    assert validator.options[:follow_links]
    assert_equal ['tidy'], validator.options[:validators]
    assert_equal [], validator.options[:skip_patterns]
    assert_nil validator.options[:only_pattern]
    assert validator.options[:follow_external]
  end

  def test_quiet
    validator = Html::Test::LinkValidator.new("http://my.cool.site", {:quiet => true})
    # Even in quiet mode the log should be populated
    assert_match /my\.cool\.site/, validator.log
  end
  
  def test_link_follow_page
    validator = Html::Test::LinkValidator.new("http://site.com/dir/valid_links")
    # All links visited
    assert_equal(["http://site.com/dir/valid_links",
      "http://site.com/link1",
      "http://site.com/dir/link2",
      "http://site.com/dir/foobar/link3",
      "http://foobar.com/external"].sort,
      Net::HTTP.test_requests.sort)
  end

  def test_link_follow_root
    %w(http://site.com http://site.com/).each do |url|
      Net::HTTP.test_requests = []
      Net::HTTP.test_with_links = true
      validator = Html::Test::LinkValidator.new(url)
      # All links visited
      assert_equal([url,
        "http://site.com/link1",
        "http://site.com/link2",
        "http://site.com/foobar/link3",
        "http://foobar.com/external"].sort,
        Net::HTTP.test_requests.sort)
    end
  end

  def test_link_follow_dir
    Net::HTTP.test_with_links = true
    validator = Html::Test::LinkValidator.new("http://site.com/dir/")
    # All links visited
    assert_equal(["http://site.com/dir/",
      "http://site.com/link1",
      "http://site.com/dir/link2",
      "http://site.com/dir/foobar/link3",
      "http://foobar.com/external"].sort,
      Net::HTTP.test_requests.sort)
  end

  def test_skip_patterns
    url = "http://my.cool.site/valid_links"
    validator = Html::Test::LinkValidator.new(url,
      {:skip_patterns => [/link[12]/, /http/]})
    assert_equal [url, "http://my.cool.site/foobar/link3"].sort,
      Net::HTTP.test_requests.sort
  end
  
  def test_only_pattern
    url = "http://my.cool.site/dir/valid_links"
    validator = Html::Test::LinkValidator.new(url, {:only_pattern => /link[12]/})
    assert_equal [url, "http://my.cool.site/link1", "http://my.cool.site/dir/link2"].sort,
      Net::HTTP.test_requests.sort
  end
  
  def test_follow_external_false
    Net::HTTP.test_with_links = true
    validator = Html::Test::LinkValidator.new("http://site.com/dir/", {:follow_external => false})
    assert_equal(["http://site.com/dir/",
      "http://site.com/link1",
      "http://site.com/dir/link2",
      "http://site.com/dir/foobar/link3"].sort,
      Net::HTTP.test_requests.sort)
  end
end
