module Html
  module Test
    class InvalidUrl < RuntimeError; end

    class UrlChecker
      attr_accessor :request, :response, :params
      
      include Html::Test::UrlSelector    
      
      def initialize(controller)
        self.request = controller.request
        self.response = controller.response
        self.params = controller.params
      end
      
      def check_urls_resolve
        urls_to_check.each do |url|
          check_url_resolves(url)
        end
      end

      def check_redirects_resolve
        if response.headers['Status'] =~ /302/
          if response.redirected_to.is_a?(Hash)
            # redirected_to={:action=>"foobar"}
            url = url_from_params(response.redirected_to)
          else
            # redirected_to="http://test.host/foobar"
            url = response.redirected_to[%r{test.host(.+)$}, 1]
          end
          check_url_resolves(url)
        end
      end

      protected
      def urls_to_check
        anchor_urls + image_urls + form_urls
      end

      def check_url_resolves(url)
        return if url.blank? or skip_url?(url) or external_http?(url)
        url = strip_anchor(remove_query(make_absolute(url)))
        return if public_file_exists?(url)
        check_action_exists(url)
      end

      def public_file_exists?(url)
        public_path = File.join(rails_public_path, url)
        File.exists?(public_path) || File.exists?(public_path + ".html")
      end

      def rails_public_path
        File.join(RAILS_ROOT, "public")
      end

      # Make relative URLs absolute, i.e. relative to the site root
      def make_absolute(url)
        return url if url =~ %r{^/}
        current_url = request.request_uri || url_from_params
        current_url = File.dirname(current_url) if current_url !~ %r{/$}
        url = File.join(current_url, url) 
      end

      def remove_query(url)
        url =~ /\?/ ? url[/^(.+?)\?/, 1] : url
      end

      def strip_anchor(url)
        url =~ /\#/ ? url[/^(.+?)\#/, 1] : url
      end

      def check_action_exists(url)
        route = route_from_url(url)
        controller = "#{route[:controller].camelize}Controller".constantize
        if !controller.public_instance_methods.include?(route[:action]) &&
          !template_file_exists?(route, controller)
          raise Html::Test::InvalidUrl.new("No action or template for url '#{url}' body=#{response.body}")
        end      
      end

      def template_file_exists?(route, controller)
        # Workaround for Rails 1.2 that doesn't have the view_paths method
        template_dirs = controller.respond_to?(:view_paths) ?
          controller.view_paths : [controller.view_root]
        template_dirs.each do |template_dir|
          template_file = File.join(template_dir, controller.controller_path, "#{route[:action]}.*")
          return true if !Dir.glob(template_file).empty?
        end
        false
      end

      # This is a special case where on my site I had a catch all route for 404s. If you have
      # such a route, you can override this method and check for it, i.e. you could do something
      # like this:
      #
      #   if params[:action] == "rescue_404"
      #     raise Html::Test::InvalidUrl.new("Action rescue_404 invoked for url '#{url}'")
      #   end
      def check_not_404(url, params)
        # This method is unimplemented by default
      end

      def route_from_url(url)
        [:get, :post, :put, :delete].each do |method|
          begin
            # Need to specify the method here for RESTful resource routes to work, i.e.
            # for /posts/1 to be recognized as the show action etc.
            params = ::ActionController::Routing::Routes.recognize_path(url, {:method => method})
            check_not_404(url, params)
            return params
          rescue
            # Could not find a route with that method, let's try the next method in the list.
            # Some routes may have stuff like :conditions => {:method => :post}
          end
        end
        raise Html::Test::InvalidUrl.new("Cannot find a route for url '#{url}'")
      end

      def url_from_params(options = params)
        return "/" if params.empty?
        options[:controller] ||= params[:controller]
        ::ActionController::Routing::Routes.generate_extras(symbolize_hash(options))[0]
      end

      # Convert all keys in the hash to symbols. Not sure why this is needed.
      def symbolize_hash(hash)
        hash.keys.inject({}) { |h, k| h[k.to_sym] = hash[k]; h }
      end
    end
  end
end