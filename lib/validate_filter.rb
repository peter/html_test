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
        return if !should_validate?
        assert_validates(validators, response.body.strip)        
      end

      # Override this method if you only want to validate a subset of pages
      def should_validate?
        response.headers['Status'] =~ /200/ and
        (response.headers['Content-Type'] =~ /text\/html/i or
        response.body =~ /<html/)
      end
    end
  end
end
