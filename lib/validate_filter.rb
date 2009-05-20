module Html
  module Test
    class ValidateFilter
      attr_accessor :request, :response, :params, :validators
      
      include ::Test::Unit::Assertions
      include ::Html::Test::Assertions

      def initialize(controller)
        self.request = controller.request
        self.response = controller.response
        self.params = controller.params
        self.validators = controller.class.validators
      end

      def validate_page
        url = request.request_uri
        return if (!should_validate? || ValidateFilter.already_validated?(url))
        assert_validates(validators, response.body.strip, url, :verbose => true)
        ValidateFilter.mark_url_validated(url)
      end

      def self.already_validated?(url)
        validated_urls[url]
      end

      def self.mark_url_validated(url)
        validated_urls[url] = true        
      end

      def self.validated_urls
        @validated_urls ||= {}
      end

      # Override this method if you only want to validate a subset of pages
      def should_validate?
        response.status =~ /200/ &&
          (response.headers['Content-Type'] =~ /text\/html/i || response.body =~ /<html/)
      end      
    end
  end
end
