module Gibbon
  class APIRequest
    def initialize(builder: nil)
      @request_builder = builder
    end

    def post(params: nil, headers: nil, body: nil)
      validate_api_key

      begin
        response = self.rest_client.post do |request|
          configure_request(request: request, params: params, headers: headers, body: MultiJson.dump(body))
        end
        parse_response(response.body)
      rescue => e
        handle_error(e)
      end
    end
    
    def patch(params: nil, headers: nil, body: nil)
      validate_api_key

      begin
        response = self.rest_client.patch do |request|
          configure_request(request: request, params: params, headers: headers, body: MultiJson.dump(body))
        end
        parse_response(response.body)
      rescue => e
        handle_error(e)
      end
    end
    
    def get(params: nil, headers: nil)
      validate_api_key

      begin
        response = self.rest_client.get do |request|
          configure_request(request: request, params: params, headers: headers)
        end
        parse_response(response.body)
      rescue => e
        handle_error(e)
      end
    end
    
    def delete(params: nil, headers: nil)
      validate_api_key

      begin
        response = self.rest_client.delete do |request|
          configure_request(request: request, params: params, headers: headers)
        end
        parse_response(response.body)
      rescue => e
        handle_error(e)
      end
    end

    protected
    
    # Convenience accessors
  
    def api_key
      @request_builder.api_key
    end
    
    def api_endpoint
      @request_builder.api_endpoint
    end
    
    def timeout
      @request_builder.timeout
    end

    # Helpers

    def handle_error(error)
      error_to_raise = nil

      begin
        error_to_raise = MailChimpError.new(error.message)

        if error.is_a?(Faraday::Error::ClientError) && error.response
          parsed_response = MultiJson.load(error.response[:body])

          if parsed_response
            error_to_raise.body = parsed_response
            error_to_raise.title = parsed_response["title"] if parsed_response["title"]
            error_to_raise.detail = parsed_response["detail"] if parsed_response["detail"]
          end

          error_to_raise.status_code = error.response[:status]
          error_to_raise.raw_body = error.response[:body]
        end
      rescue MultiJson::ParseError
        error_to_raise.message = error.message
        error_to_raise.status_code = error.response[:status]
      end

      raise error_to_raise
    end

    def configure_request(request: nil, params: nil, headers: nil, body: nil)
      if request
        request.params.merge!(params) if params
        request.headers['Content-Type'] = 'application/json'
        request.headers.merge!(headers) if headers
        request.body = body if body
        request.options.timeout = self.timeout
      end
    end

    def rest_client
      client = Faraday.new(url: self.api_url) do |faraday|
        faraday.response :raise_error
        faraday.adapter Faraday.default_adapter
      end
      client.basic_auth('apikey', self.api_key)
      client
    end

    def parse_response(response_body)
      parsed_response = nil

      if response_body && !response_body.empty?
        begin
          parsed_response = MultiJson.load(response_body)
        rescue MultiJson::ParseError
          error = MailChimpError.new("Unparseable response: #{response_body}")
          error.title = "UNPARSEABLE_RESPONSE"
          error.status_code = 500
          raise error
        end
      end

      parsed_response
    end

    def validate_api_key
      api_key = self.api_key
      unless api_key && (api_key["-"] || self.api_endpoint)
        raise Gibbon::GibbonError, "You must set an api_key prior to making a call"
      end
    end

    def api_url
      base_api_url + @request_builder.path
    end

    def base_api_url
      computed_api_endpoint = "https://#{get_data_center_from_api_key}api.mailchimp.com"
      "#{self.api_endpoint || computed_api_endpoint}/3.0/"
    end

    def get_data_center_from_api_key
      # Return an empty string for invalid API keys so Gibbon hits the main endpoint
      data_center = ""

      if self.api_key && self.api_key["-"]
        # Add a period since the data_center is a subdomain and it keeps things dry
        data_center = "#{self.api_key.split('-').last}."
      end

      data_center
    end
  end
end
