module Gibbon
  class API
    attr_accessor :api_key, :api_endpoint, :timeout, :throws_exceptions

    def initialize(api_key = nil, default_parameters = {})
      @api_key = api_key || self.class.api_key || ENV['MAILCHIMP_API_KEY']
      @api_key = @api_key.strip if @api_key

      @api_endpoint = default_parameters.delete(:api_endpoint) || self.class.api_endpoint
      @timeout = default_parameters.delete(:timeout) || self.class.timeout
      @throws_exceptions = default_parameters.has_key?(:throws_exceptions) ? default_parameters.delete(:throws_exceptions) : self.class.throws_exceptions

      @default_params = {:apikey => @api_key}.merge(default_parameters)
    end

    def get_exporter
      Export.new(@api_key, @default_params)
    end

    def method_missing(method, *args)
      api = APICategory.new(method.to_s, @api_key, @timeout, @throws_exceptions, @api_endpoint, @default_params)
      api.api_endpoint = @api_endpoint if @api_endpoint
      api
    end

    def respond_to_missing?(method, include_private = false)
      %w{campaigns ecomm folders gallery lists helper reports templates users vip}.include?(method.to_s) || super
    end

    class << self
      attr_accessor :api_key, :timeout, :throws_exceptions, :api_endpoint

      def method_missing(sym, *args, &block)
        new(self.api_key, {:api_endpoint => self.api_endpoint, :timeout => self.timeout, :throws_exceptions => self.throws_exceptions}).send(sym, *args, &block)
      end
    end
  end
end
