module Gibbon
  # Builds and issues requests against MailChimp's Marketing API.
  #
  # `Request` defines no methods for MailChimp's resources. An unknown method
  # appends a segment to an internal path and returns `self`, so
  # `gibbon.lists(list_id).members` builds `lists/<list_id>/members`. A CRUD
  # verb ({#create}, {#retrieve}, {#update}, {#upsert}, {#delete}) then issues
  # the request and resets the path. Because of that reset, an instance is safe
  # to reuse only after a verb has run.
  #
  # @example Fetching lists
  #   gibbon = Gibbon::Request.new(api_key: "your_api_key-us1")
  #   gibbon.lists.retrieve.body["lists"]
  #
  # @see https://mailchimp.com/developer/marketing/api/ MailChimp's resource documentation
  class Request
    # Per-instance configuration. Each falls back to the matching class level
    # setting, then to an environment variable or built-in default; see
    # {#initialize} for the resolution order.
    attr_accessor :api_key, :api_endpoint, :timeout, :open_timeout, :proxy, :faraday_adapter, :symbolize_keys, :debug, :logger

    # Default read timeout, in seconds.
    DEFAULT_TIMEOUT = 60
    # Default connection open timeout, in seconds.
    DEFAULT_OPEN_TIMEOUT = 60

    # @param api_key [String, nil] API key or OAuth access token. Falls back to
    #   `Gibbon::Request.api_key`, then `ENV["MAILCHIMP_API_KEY"]`.
    # @param api_endpoint [String, nil] Base URL, e.g. `"https://us1.api.mailchimp.com"`.
    #   Required when the key carries no data center suffix, as OAuth access
    #   tokens do not; otherwise it is derived from the key.
    # @param timeout [Integer, nil] Read timeout in seconds. Defaults to {DEFAULT_TIMEOUT}.
    # @param open_timeout [Integer, nil] Open timeout in seconds. Defaults to {DEFAULT_OPEN_TIMEOUT}.
    # @param proxy [String, nil] Proxy URL. Falls back to `ENV["MAILCHIMP_PROXY"]`.
    # @param faraday_adapter [Symbol, nil] Faraday adapter. Defaults to `Faraday.default_adapter`.
    # @param symbolize_keys [Boolean] Whether parsed response bodies use symbol keys.
    # @param debug [Boolean] Whether to log requests and responses.
    # @param logger [Logger, nil] Logger used when `debug` is true. Defaults to `Logger.new(STDOUT)`.
    def initialize(api_key: nil, api_endpoint: nil, timeout: nil, open_timeout: nil, proxy: nil, faraday_adapter: nil, symbolize_keys: false, debug: false, logger: nil)
      @path_parts = []
      @api_key = api_key || self.class.api_key || ENV['MAILCHIMP_API_KEY']
      @api_key = @api_key.strip if @api_key
      @api_endpoint = api_endpoint || self.class.api_endpoint
      @timeout = timeout || self.class.timeout || DEFAULT_TIMEOUT
      @open_timeout = open_timeout || self.class.open_timeout || DEFAULT_OPEN_TIMEOUT
      @proxy = proxy || self.class.proxy || ENV['MAILCHIMP_PROXY']
      @faraday_adapter = faraday_adapter || self.class.faraday_adapter || Faraday.default_adapter
      @symbolize_keys = symbolize_keys || self.class.symbolize_keys || false
      @debug = debug || self.class.debug || false
      @logger = logger || self.class.logger || ::Logger.new(STDOUT)
    end

    # Appends the method name to the request path, along with any arguments as
    # further segments, and returns `self` so calls can be chained.
    #
    # @return [Request] self
    def method_missing(method, *args)
      # To support underscores, we replace them with hyphens when calling the API
      @path_parts << method.to_s.gsub("_", "-").downcase
      @path_parts << args if args.length > 0
      @path_parts.flatten!
      self
    end

    # Every method name is a potential path segment, so this always returns true.
    #
    # @return [true]
    def respond_to_missing?(method_name, include_private = false)
      true
    end

    # Appends `send` as a path segment when called with no arguments, so that
    # `gibbon.campaigns(id).actions.send.create` reaches
    # `campaigns/<id>/actions/send`. Called with arguments, this behaves like
    # `Object#send` and invokes the named method.
    #
    # @return [Request, Object] self, or the return value of the invoked method
    def send(*args)
      if args.length == 0
        method_missing(:send, args)
      else
        __send__(*args)
      end
    end

    # @return [String] the path accumulated so far, e.g. `"lists/abc123/members"`
    def path
      @path_parts.join('/')
    end

    # Issues a `POST` to the accumulated path, then resets it.
    #
    # @param params [Hash, nil] query string parameters
    # @param headers [Hash, nil] additional request headers
    # @param body [Hash, nil] request body, serialized to JSON
    # @return [Response, nil] the response, or nil when MailChimp returns an empty body
    # @raise [GibbonError] if no usable API key is configured
    # @raise [MailChimpError] if the request fails or the response cannot be parsed
    def create(params: nil, headers: nil, body: nil)
      APIRequest.new(builder: self).post(params: params, headers: headers, body: body)
    ensure
      reset
    end

    # Issues a `PATCH` to the accumulated path, then resets it.
    #
    # @param (see #create)
    # @return (see #create)
    # @raise (see #create)
    def update(params: nil, headers: nil, body: nil)
      APIRequest.new(builder: self).patch(params: params, headers: headers, body: body)
    ensure
      reset
    end

    # Issues a `PUT` to the accumulated path, then resets it. Updates the record
    # if it exists and inserts it otherwise, where MailChimp supports it.
    #
    # @param (see #create)
    # @return (see #create)
    # @raise (see #create)
    def upsert(params: nil, headers: nil, body: nil)
      APIRequest.new(builder: self).put(params: params, headers: headers, body: body)
    ensure
      reset
    end

    # Alias for {#retrieve}.
    #
    # @param (see #retrieve)
    # @return (see #retrieve)
    # @raise (see #retrieve)
    def get(params: nil, headers: nil)
      retrieve(params: params, headers: headers)
    end

    # Issues a `GET` to the accumulated path, then resets it.
    #
    # @param params [Hash, nil] query string parameters
    # @param headers [Hash, nil] additional request headers
    # @return [Response, nil] the response, or nil when MailChimp returns an empty body
    # @raise [GibbonError] if no usable API key is configured
    # @raise [MailChimpError] if the request fails or the response cannot be parsed
    def retrieve(params: nil, headers: nil)
      APIRequest.new(builder: self).get(params: params, headers: headers)
    ensure
      reset
    end

    # Issues a `DELETE` to the accumulated path, then resets it.
    #
    # @param (see #retrieve)
    # @return (see #retrieve)
    # @raise (see #retrieve)
    def delete(params: nil, headers: nil)
      APIRequest.new(builder: self).delete(params: params, headers: headers)
    ensure
      reset
    end

    protected

    def reset
      @path_parts = []
    end

    class << self
      # Class level defaults applied to every new instance. Setting these is a
      # convenient way to configure Gibbon once, e.g. from a Rails initializer.
      attr_accessor :api_key, :timeout, :open_timeout, :api_endpoint, :proxy, :faraday_adapter, :symbolize_keys, :debug, :logger

      # Starts a call chain on a new instance built from the class level
      # configuration, so `Gibbon::Request.lists.retrieve` works once
      # {api_key} has been set.
      #
      # @return [Request] a new instance carrying the first path segment
      def method_missing(sym, *args, &block)
        new(api_key: self.api_key, api_endpoint: self.api_endpoint, timeout: self.timeout, open_timeout: self.open_timeout, faraday_adapter: self.faraday_adapter, symbolize_keys: self.symbolize_keys, debug: self.debug, proxy: self.proxy, logger: self.logger).send(sym, *args, &block)
      end

      # Every method name is a potential path segment, so this always returns true.
      #
      # @return [true]
      def respond_to_missing?(method_name, include_private = false)
        true
      end
    end
  end
end
