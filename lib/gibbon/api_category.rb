require 'gibbon/api'

module Gibbon
  class APICategory
    include HTTParty
    format :plain
    default_timeout 30

    attr_accessor :category_name, :api_key, :api_endpoint, :timeout, :throws_exceptions, :default_params
  
    def initialize(category_name)
      set_instance_defaults
      @category_name = category_name
    end
  
    def call(method, params = {})
      api_url = base_api_url + method
      params = @default_params.merge(params)
      response = self.class.post(api_url, body: MultiJson.dump(params), timeout: @timeout)
      parsed_response = MultiJson.load(response.body).first

      if should_raise_for_response?(parsed_response)
        error = MailChimpError.new("MailChimp API Error: #{parsed_response["error"]} (code #{parsed_response["code"]})")
        error.code = parsed_response["code"]
        raise error
      end

      parsed_response
    end
  
    def method_missing(method, *args)
      # To support underscores, we replace them with hyphens when calling the API
      method = method.to_s.gsub("_", "-").downcase
      call("#{@category_name}}/#{method}", *args)
    end
  
    def set_instance_defaults
      @timeout = (API.timeout || 30) if @timeout.nil?
      @api_endpoint = API.api_endpoint if @api_endpoint.nil?
      # Two lines because the class variable could be false and (false || true) is always true
      @throws_exceptions = API.throws_exceptions if @throws_exceptions.nil?
      @throws_exceptions = true if @throws_exceptions.nil?
    end

    def should_raise_for_response?(response)
      @throws_exceptions && response.is_a?(Hash) && response["error"]
    end

    def base_api_url
      "#{@api_endpoint || get_api_endpoint}/2.0/?method="
    end

    def get_api_endpoint
      "https://#{get_data_center_from_api_key}api.mailchimp.com"
    end

    def get_data_center_from_api_key
      # Return an empty string for invalid API keys so Gibbon hits the main endpoint
      data_center = ""

      if (@api_key && @api_key["-"])
        # Add a period since the data_center is a subdomain and it keeps things dry
        data_center = "#{@api_key.split('-').last}."
      end

      data_center
    end
  end
end