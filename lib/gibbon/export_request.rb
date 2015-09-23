module Gibbon
  class ExportRequest
    attr_accessor :api_key, :timeout

    DEFAULT_TIMEOUT = 30

    def initialize(api_key: nil, timeout: nil)
      @api_key = api_key || self.class.api_key || ENV['MAILCHIMP_API_KEY']
      @api_key = @api_key.strip if @api_key
      @timeout = timeout || self.class.timeout || DEFAULT_TIMEOUT
    end
    
    def list(id: nil, status: nil, segment: nil, since: nil, &block)
      validate_api_key
      validate_id

      params = {}
      params[:id] = id if id
      params[:status] = status if status
      params[:segment] = segment if segment
      params[:since] = since if since
      post("list", params, &block)
    end

    def ecomm_orders(since: nil, &block)
      validate_api_key

      params = {}
      params[:since] = since if since
      post("ecommOrders", params, &block)
    end

    def campaign_subscriber_activity(id: nil, include_empty: false, since: nil, &block)
      validate_api_key
      validate_id
      
      params = {}
      params[:id] = id if id
      params[:include_empty] = include_empty if include_empty
      params[:since] = since if since
      post("campaignSubscriberActivity", params, &block)
    end

    protected
    
    def validate_api_key
      api_key = self.api_key
      unless api_key && (api_key["-"] || self.api_endpoint)
        raise Gibbon::GibbonError, "You must set an api_key prior to making a request"
      end
    end
  
    def validate_id
      unless params[:id] || params["id"]
        raise Gibbon::GibbonError, "You must pass a list id when making a request"
      end
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

    def export_api_url
      "http://#{get_data_center_from_api_key}api.mailchimp.com/export/1.0/"
    end
        
    def post(method, params, &block)
      rows = []
      block = Proc.new { |row| rows << row } unless block_given?
      params = params.merge({apikey: @api_key})
      api_url = export_api_url + method + "/"

      url = URI.parse(api_url)
      req = Net::HTTP::Post.new(url.path, initheader = {'Content-Type' => 'application/json'})
      req.body = MultiJson.dump(params)

      Net::HTTP.start(url.host, url.port, :read_timeout => @timeout) do |http|
        # http://stackoverflow.com/questions/29598196/ruby-net-http-read-body-nethttpokread-body-called-twice-ioerror
        http.request req do |response|
          i = -1
          last = ""
          response.read_body do |chunk|
            next if chunk.nil? or chunk.strip.empty?
            last += "\n" if last[-1, 1] == "]"
            lines = (last + chunk).split("\n")
            last = lines.pop || ""
            lines.each do |line|
              block.call(parse_response(line, i < 0), i += 1) unless line.nil?
            end
          end
          block.call(parse_response(last, i < 0), i += 1) unless last.nil? or last.empty?
        end
      end
      
      rows unless block_given?
    end
    
    def parse_response(response, check_error)
      return [] if response.strip.empty?

      parsed_response = []

      begin
        parsed_response = MultiJson.load(response)
      rescue MultiJson::ParseError
        error = MailChimpError.new("Unparseable response: #{response}")
        error.title = "UNPARSEABLE_RESPONSE"
        error.status_code = 500
        raise error
      end

      if parsed_response.is_a?(Hash) && parsed_response["error"]
        error = MailChimpError.new(parsed_response["error"])
        error.status_code = parsed_response["code"]
        error.title = parsed_response["name"]
        error.body = parsed_response
        error.raw_body = response
        raise error
      end

      parsed_response
    end

    class << self
      attr_accessor :api_key, :timeout

      def method_missing(sym, *args, &block)
        new(api_key: self.api_key, timeout: self.timeout).send(sym, *args, &block)
      end
    end
  end
end
