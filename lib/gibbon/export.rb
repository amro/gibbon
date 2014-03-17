module Gibbon
  class Export < APICategory

    def initialize(api_key = nil, default_params = {})
      @api_key = api_key
      @default_params = default_params

      set_instance_defaults
    end

    protected

    def export_api_url
      "http://#{get_data_center_from_api_key}api.mailchimp.com/export/1.0/"
    end

    def call(method, params = {})
      ensure_api_key params

      api_url = export_api_url + method + "/"
      params = @default_params.merge(params).merge({:apikey => @api_key})
      response = self.class.post(api_url, :body => MultiJson.dump(params), :timeout => @timeout)

      lines = response.body.lines
      if @throws_exceptions
        first_line = MultiJson.load(lines.first) if lines.first

        if should_raise_for_response?(first_line)
          error = MailChimpError.new(first_line["error"])
          error.code = first_line["code"]
          raise error
        end
      end

      lines
    end

    def set_instance_defaults
      super
      @api_key = self.class.api_key if @api_key.nil?
      @timeout = self.class.timeout if @timeout.nil?
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

    def respond_to_missing?(method, include_private = false)
      %w{list ecommOrders ecomm_orders campaignSubscriberActivity campaign_subscriber_activity}.include?(method.to_s) || super
    end


    private

    def ensure_api_key(params)
      unless @api_key || @default_params[:apikey] || params[:apikey]
        raise Gibbon::GibbonError, "You must set an api_key prior to making a call"
      end
    end

    class << self
      attr_accessor :api_key, :timeout, :throws_exceptions

      def method_missing(sym, *args, &block)
        new(self.api_key, {:timeout => self.timeout, :throws_exceptions => self.throws_exceptions}).send(sym, *args, &block)
      end
    end
  end
end
