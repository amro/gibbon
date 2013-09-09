require 'gibbon/api'

module Gibbon
  class APICategory
    include HTTParty
    format :plain
    default_timeout 30

    attr_accessor :category_name, :api_key, :api_endpoint, :timeout, :throws_exceptions, :default_params
  
    def initialize(category_name, api_key, timeout, throws_exceptions, api_endpoint, default_params)
      @category_name = category_name
      @api_key = api_key
      @api_endpoint = api_endpoint
      @default_params = default_params
      @throws_exceptions = throws_exceptions
      @timeout = timeout

      set_instance_defaults
    end

    def call(method, params = {})
      api_url = base_api_url + method
      params = @default_params.merge(params).merge({apikey: @api_key})
      response = self.class.post(api_url, body: MultiJson.dump(params), timeout: @timeout)
      
      parsed_response = nil
      
      if (response.body)
        parsed_response = MultiJson.load(response.body)

        if should_raise_for_response?(parsed_response)
          error = MailChimpError.new("MailChimp API Error: #{parsed_response["error"]} (code #{parsed_response["code"]})")
          error.code = parsed_response["code"]
          raise error
        end
        parsed_response["status_code"] = response.code

      end

      parsed_response
    end
  
    def method_missing(method, *args)
      # To support underscores, we replace them with hyphens when calling the API
      method = method.to_s.gsub("_", "-").downcase
      call("#{@category_name}/#{method}", *args)
    end
  
    def set_instance_defaults
      @timeout = (API.timeout || 30) if @timeout.nil?
      # Two lines because the class variable could be false and (false || true) is always true
      @throws_exceptions = API.throws_exceptions if @throws_exceptions.nil?
      @throws_exceptions = true if @throws_exceptions.nil?
    end

    def api_key=(value)
      @api_key = value.strip if value
    end
    
    def should_raise_for_response?(response)
      @throws_exceptions && response.is_a?(Hash) && response["error"]
    end

    def base_api_url
      "#{@api_endpoint || get_api_endpoint}/2.0/"
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