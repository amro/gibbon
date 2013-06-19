module Gibbon
  class Export < APICategory
    def initialize(api_key = nil, default_parameters = {})
      super(api_key, default_parameters)
    end

    protected

    def export_api_url
      "http://#{get_data_center_from_api_key}api.mailchimp.com/export/1.0/"
    end

    def call(method, params = {})
      api_url = export_api_url + method + "/"
      params = @default_params.merge(params)
      response = self.class.post(api_url, body: MultiJson.dump(params), timeout: @timeout)

      lines = response.body.lines
      if @throws_exceptions
        first_line = MultiJson.load(lines.first) if lines.first
    
        if should_raise_for_response?(first_line)
          error = MailChimpError.new("MailChimp Export API Error: #{first_line["error"]} (code #{first_line["code"]})")
          error.code = first_line["code"]
          raise error
        end
      end

      lines
    end

    def method_missing(method, *args)
      # To support underscores, we camelize the method name

      # Thanks for the camelize gsub, Rails
      method = method.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }

      # We need to downcase the first letter of every API method
      # and MailChimp has a few of API methods that end in "AIM," which
      # must be upcased (See "Campaign Report Data Methods" in their API docs).
      method = method[0].chr.downcase + method[1..-1].gsub(/aim$/i, 'AIM')

      call(method, *args)
    end
  end
end