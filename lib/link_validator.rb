require 'test/unit'
require 'net/http'
require 'uri'

module Html
  module Test
    class LinkValidator
      include ::Test::Unit::Assertions
      include ::Html::Test::Assertions
      include UrlSelector
      
      attr_accessor :start_url, :options, :log
      
      def options
        @options ||= {}
      end

      def log
        @log ||= ""
      end

      def initialize(url, options = {})
        self.start_url = strip_anchor(url)

        # Default values for options
        if Object.const_defined?(:RailsTidy)
          self.options[:validators] = %w(tidy)
        else
          self.options[:validators] = %w(w3c)      
        end
        self.options[:skip_patterns] = []
        self.options[:follow_external] = true
        self.options[:follow_links] = true
        self.options[:quiet] = false
        Html::Test::Validator.dtd = options[:dtd] if options[:dtd]

        self.options.merge!(options)
        
        validate_links
      end

      # Generates an options hash from the command line options
      def self.parse_command_line(options_array)
        if options_array[0] !~ /:\/\//
          raise "First argument must be URL, i.e. http://my.url.com"
        end

        options = {}

        opts = OptionParser.new
        opts.on("--no-follow") { options[:follow_links] = false }
        opts.on("--validators validators") do |validators|
          options[:validators] = validators.split(",")
        end
        opts.on('--dtd DTD') { |dtd| options[:dtd] = dtd }
        opts.on("--skip skip_patterns") do |skip_patterns|
          options[:skip_patterns] = skip_patterns.split(",").map { |p| Regexp.new(p) }
        end
        opts.on("--only only_pattern") do |only_pattern|
          options[:only_pattern] = Regexp.new(only_pattern)
        end
        opts.on('--no-external') { options[:follow_external] = false }
        opts.on('--quiet') { options[:quiet] = true }
        
        opts.parse!(options_array)

        options
      end

      protected
      def validate_links
        @url_history = []
        @failed_urls = []

        get(start_url)
        return if !options[:follow_links]

        # Fetch links and images on the start page
        (anchor_urls + image_urls).each do |url|
          if skip_url?(url)
            output "skipping url #{url}\n"
            next
          end
          next unless options[:skip_patterns].select { |pattern| url =~ pattern }.empty?
          next if visited?(url)
          next if options[:only_pattern] and url !~ options[:only_pattern]

          if external_http?(url)
            if options[:follow_external]
              get(url, false)
            else
              output "skipping external link #{url}\n"
            end
          else
            get(url)
          end
        end

        if !@failed_urls.empty?
          raise "The following URLs had failures:\n#{@failed_urls.join("\n")}."            
        end    
      end

      def get(path, validate = true)
        begin
          url = canonical_url(path)
          output "GET #{url}"
          @response = Net::HTTP.get_response(URI.parse(url))
          output " ... #{@response.code}"
          @url_history << url
          if ![/200/, /^3/].find { |pattern| @response.code =~ pattern }
            raise "Invalid response code #{@response.code} for url #{url}"
          end
          validate_response if validate
          output "\n"
        rescue Exception => e
          output_error "Exception thrown while getting url #{qualify_url(path)}:" +
          " #{e} #{e.backtrace.join("\n  ")}\n"
          @failed_urls << qualify_url(path)
        end
      end

      def validate_response
        if @response and @response.header['content-type'] =~ /text\/html/i
          options[:validators].each do |type|
            assert_validates(type)
            output " ... #{type}"
          end
        end
      end

      def visited?(path)
        @url_history.include?(canonical_url(path))
      end

      def strip_anchor(url)
        url[/^(.*?)(?:\#.+)?$/, 1]
      end

      def qualify_url(url)
        return url if url =~ /:\/\// # External URL
        
        if url =~ /^\//
          # Relative site root
          root_url + url
        else
          # Relative start dir
          start_dir + "/" + url
        end
      end

      def canonical_url(url)
        strip_anchor(qualify_url(url))
      end

      def root_url
        start_url[/^([a-z]+:\/\/[^\/]+)/,1]
      end

      def start_dir
        return start_url if start_url == root_url # When start_url=http://site.com
        start_url[/^(.+?)\/[^\/]*$/,1] # Strip last slash and everything after it
      end

      def output_error(message)
        output(message, :error)
      end
      
      def output(message, type = :info)
        log << message
        print message if (type == :error or !options[:quiet])
      end
    end
  end
end
