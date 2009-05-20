module Html
  module Test
    module UrlSelector
      def skip_url?(url, root_url = nil)
        if url.blank? || unsupported_protocol?(url) || special_url?(url)
          true
        else
          false
        end
      end

      def special_url?(url)
        [/^javascript:/, /^mailto:/, /^\#$/].any? { |pattern| url =~ pattern }
      end

      def external_http?(url, root_url = nil)
        if root_url
          http_protocol?(url) && !url.starts_with?(root_url)
        else
          http_protocol?(url)
        end
      end

      def http_protocol?(url)
        url =~ %r{^http(?:s)?://} ? true : false
      end

      def has_protocol?(url)
        url =~ %r{^[a-z]+://} ? true : false
      end

      def unsupported_protocol?(url)
        has_protocol?(url) && !http_protocol?(url)
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
