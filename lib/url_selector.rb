module Html
  module Test
    module UrlSelector
      def skip_url?(url)
        return true if url.blank? or (!external_http?(url) and url =~ /:\/\//) # Unsupported protocol
        [/^javascript:/, /^mailto:/, /^\#$/].each do |pattern|
          return true if url =~ pattern
        end
        false
      end

      def external_http?(url)
         url =~ /^http(?:s)?:\/\//
      end

      def anchor_urls
        select("a").map { |l| l.attributes['href'] }
      end

      def image_urls
        select("img").map { |i| i.attributes['src'] }
      end

      def form_urls
        select("form").map { |i| i.attributes['action'] }        
      end
      
      def response_body
        self.respond_to?(:response) ? response.body : @response.body
      end

      def select(pattern)
        HTML::Selector.new(pattern).select(HTML::Document.new(response_body).root)
      end      
    end
  end
end
