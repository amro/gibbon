module Gibbon
  class API
    attr_accessor :api_key, :api_endpoint, :timeout, :throws_exceptions
  
    def initialize(api_key = nil, default_parameters = {})
      @api_key = api_key || self.class.api_key || ENV['MAILCHIMP_API_KEY']
      @api_key = @api_key.strip if @api_key

      @api_endpoint = default_parameters.delete(:api_endpoint)
      @timeout = default_parameters.delete(:timeout)
      @throws_exceptions = default_parameters.delete(:throws_exceptions)
  
      @default_params = {apikey: @api_key}.merge(default_parameters)
    end
    
    def method_missing(method, *args)
      api_category = APICategory.new(method.to_s)
      api_category.api_key = @api_key
      api_category.timeout = @timeout
      api_category.throws_exceptions = @throws_exceptions
      api_category.default_params = @default_params
      api_category
    end
  
    def api_key=(value)
      @api_key = value.strip if value
      @default_params = @default_params.merge({apikey: @api_key})
    end
    
    class << self
      attr_accessor :api_key, :timeout, :throws_exceptions, :api_endpoint

      def method_missing(sym, *args, &block)
        new(self.api_key, {api_endpoint: self.api_endpoint, timeout: self.timeout, throws_exceptions: self.throws_exceptions}).send(sym, *args, &block)
      end
    end
  end
end