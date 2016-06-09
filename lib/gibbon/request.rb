module Gibbon
  class Request
    attr_accessor :api_key, :api_endpoint, :timeout, :proxy, :faraday_adapter, :debug

    DEFAULT_TIMEOUT = 30

    def initialize(options = {})
      options.reverse_update(api_key: nil, api_endpoint: nil, timeout: nil, proxy: nil, faraday_adapter: nil, debug: false)

      @path_parts = []
      @api_key = options[:api_key] || self.class.api_key || ENV['MAILCHIMP_API_KEY']
      @api_key = @api_key.strip if @api_key
      @api_endpoint = options[:api_endpoint] || self.class.api_endpoint
      @timeout = options[:timeout] || self.class.timeout || DEFAULT_TIMEOUT
      @proxy = options[:proxy] || self.class.proxy || ENV['MAILCHIMP_PROXY']
      @faraday_adapter = options[:faraday_adapter] || Faraday.default_adapter
      @debug = options[:debug]
    end

    def method_missing(method, *args)
      # To support underscores, we replace them with hyphens when calling the API
      @path_parts << method.to_s.gsub("_", "-").downcase
      @path_parts << args if args.length > 0
      @path_parts.flatten!
      self
    end

    def send(*args)
      if args.length == 0
        method_missing(:send, args)
      else
        __send__(*args)
      end
    end

    def path
      @path_parts.join('/')
    end

    def create(options = {})
      options.reverse_update(params: nil, headers: nil, body: nil)

      APIRequest.new(self).post(options)
    ensure
      reset
    end

    def update(options = {})
      options.reverse_update(params: nil, headers: nil, body: nil)

      APIRequest.new(self).patch(options)
    ensure
      reset
    end

    def upsert(options = {})
      options.reverse_update(params: nil, headers: nil, body: nil)

      APIRequest.new(self).put(options)
    ensure
      reset
    end

    def retrieve(options = {})
      options.reverse_update(params: nil, headers: nil)

      APIRequest.new(self).get(options)
    ensure
      reset
    end

    def delete(options = {})
      options.reverse_update(params: nil, headers: nil)

      APIRequest.new(self).delete(options)
    ensure
      reset
    end

    protected

    def reset
      @path_parts = []
    end

    class << self
      attr_accessor :api_key, :timeout, :api_endpoint, :proxy

      def method_missing(sym, *args, &block)
        new(api_key: self.api_key, api_endpoint: self.api_endpoint, timeout: self.timeout, proxy: self.proxy).send(sym, *args, &block)
      end
    end
  end
end
