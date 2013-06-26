module Gibbon
  class API
    attr_accessor :api_key, :api_endpoint, :timeout, :throws_exceptions

    def initialize(api_key = nil, default_parameters = {})
      @api_key = api_key || self.class.api_key || ENV['MAILCHIMP_API_KEY']
      @api_key = @api_key.strip if @api_key

      @api_endpoint = default_parameters.delete(:api_endpoint)
      @timeout = default_parameters.delete(:timeout)
      @throws_exceptions = default_parameters.delete(:throws_exceptions)

      @default_params = { apikey: @api_key }.merge(default_parameters)

      set_instance_defaults
    end

    def set_instance_defaults
      @timeout = (API.timeout || 30) if @timeout.nil?
      @api_endpoint = API.api_endpoint if @api_endpoint.nil?
      # Two lines because the class variable could be false and (false || true) is always true
      @throws_exceptions = API.throws_exceptions if @throws_exceptions.nil?
      @throws_exceptions = true if @throws_exceptions.nil?
    end

    def get_exporter
      Export.new(@api_key, @default_params)
    end

    def method_missing(method, *args)
      APICategory.new(method.to_s, @api_key, @api_endpoint, @timeout, @throws_exceptions, @default_params)
    end

    class << self
      attr_accessor :api_key, :timeout, :throws_exceptions, :api_endpoint

      def method_missing(sym, *args, &block)
        new(self.api_key, {
          api_endpoint: self.api_endpoint,
          timeout: self.timeout,
          throws_exceptions: self.throws_exceptions
        }).send(sym, *args, &block)
      end
    end
  end
end