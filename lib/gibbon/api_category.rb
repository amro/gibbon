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
      ensure_api_key params

      api_url = base_api_url + method
      params = @default_params.merge(params).merge({:apikey => @api_key})
      headers = params.delete(:headers) || {}
      response = self.class.post(api_url, :body => MultiJson.dump(params), :headers => headers, :timeout => @timeout)

      parse_response(response.body) if response.body
    end

    def parse_response(response, check_error = true)
      begin
        parsed_response = MultiJson.load(response)
      rescue MultiJson::ParseError
        parsed_response = {
          "error" => "Unparseable response: #{response}",
          "name" => "UNPARSEABLE_RESPONSE",
          "code" => 500
        }
      end

      if should_raise_for_response?(parsed_response)
        error = MailChimpError.new(parsed_response["error"])
        error.code = parsed_response["code"]
        error.name = parsed_response["name"]
        raise error
      end
      parsed_response
    end

    def method_missing(method, *args)
      # To support underscores, we replace them with hyphens when calling the API
      method = method.to_s.gsub("_", "-").downcase
      call("#{@category_name}/#{method}", *args)
    end

    def send(*args)
      if ((args.length > 0) && args[0].is_a?(Hash))
        method_missing(:send, args[0])
      else
        __send__(*args)
      end
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

    private

    def ensure_api_key(params)
      unless @api_key || @default_params[:apikey] || params[:apikey]
        raise Gibbon::GibbonError, "You must set an api_key prior to making a call"
      end
    end
  end
end
