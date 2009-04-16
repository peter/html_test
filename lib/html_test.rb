%w(validator assertions url_selector url_checker link_validator validate_filter).each do |file|
  require File.join(File.dirname(__FILE__), file)
end

if RAILS_ENV == 'test'
  class Test::Unit::TestCase
    include Html::Test::Assertions
  end

  module ActionController
    module Integration #:nodoc:
      class Session
        include Html::Test::Assertions      
      end
    end
  end

  ActionController::Base
  class ActionController::Base
    @@validate_all = false
    cattr_accessor :validate_all

    @@validators = [:tidy]
    cattr_accessor :validators

    @@check_urls = false
    cattr_accessor :check_urls

    @@check_redirects = false
    cattr_accessor :check_redirects

    after_filter :validate_page
    after_filter :check_urls_resolve
    after_filter :check_redirects_resolve

    private
    def validate_page
      return if !validate_all
      Html::Test::ValidateFilter.new(self).validate_page
    end

    def check_urls_resolve
      return if !check_urls
      Html::Test::UrlChecker.new(self).check_urls_resolve
    end

    def check_redirects_resolve
      return if !check_redirects
      Html::Test::UrlChecker.new(self).check_redirects_resolve
    end
  end
end
