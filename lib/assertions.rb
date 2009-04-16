module Html
  module Test
    module Assertions
      def assert_tidy(body = nil)
        assert_validates(:tidy, body)
      end

      def assert_w3c(body = nil)
        assert_validates(:w3c, body)
      end
      
      def assert_xmllint(body = nil)
        assert_validates(:xmllint, body)
      end

      def assert_validates(types = nil, body = nil)
        body ||= @response.body
        types ||= [:tidy, :w3c, :xmllint]
        types = [types] if !types.is_a?(Array)
        types.each do |t|
          error = Html::Test::Validator.send("#{t}_errors", body)
          assert(error.nil?, "Validator #{t} failed with message " +
            "'#{error}' for response body:\n #{with_line_counts(body)}")
        end
      end
      
      private
      def with_line_counts(body)
        separator = ("-" * 40) + $/
        body_counts = separator.dup
        body.each_with_index do |line, i|
          body_counts << sprintf("%4u %s", i+1, line) # Right align line numbers
        end
        body_counts << separator
        body_counts
      end
    end
  end
end
