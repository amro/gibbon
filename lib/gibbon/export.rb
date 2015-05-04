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

    # fsluis: Alternative, streaming, interface to mailchimp export api
    #         Prevents having to keep shitloads of data in memory
    def call(method, params = {}, &block)
      #puts "#{method}, #{params}, #{block_given?}"
      rows = []

      api_url = export_api_url + method + "/"
      params = @default_params.merge(params).merge({:apikey => @api_key})
      block = Proc.new { |row| rows << row } unless block_given?
      ensure_api_key params

      url = URI.parse(api_url)
      req = Net::HTTP::Post.new(url.path, initheader = {'Content-Type' => 'application/json'})
      req.body = MultiJson.dump(params)
      #puts "Starting http call #{url.host}, #{url.port}, req: #{req.path}"
      Net::HTTP.start(url.host, url.port, :read_timeout => @timeout) do |http|
        response = http.request req
        # puts "Response: #{response}, #{response.http_version}, #{response.code}, #{response.message}"
        i = -1
        last = ''
        response.read_body do |chunk|
          #puts "Chunk length: #{chunk.length}"
          #puts "Chunk: #{chunk}"
          next if chunk.nil?
          lines = (last+chunk).split("\n")
          last = lines.pop || ''
          lines.each do |line|
            #puts "Parsing line: #{line}"
            block.call(parse_response(line, i<0), i+=1) unless line.nil?
          end
        end
        #puts "Parsing last line: #{last}"
        block.call(parse_response(last, i<0), i+=1) unless last.nil? or last.empty?
      end
      # puts "block_given: #{block_given?}, rows: #{rows}"
      rows unless block_given?
    end

    def parse_response(res, check_error)
      return [] if res.strip.empty?
      super(res, check_error)
    end

    def set_instance_defaults
      @api_key = self.class.api_key if @api_key.nil?
      @timeout = self.class.timeout if @timeout.nil?
      super
    end

    # fsluis: added a &block to this method and function call
    def method_missing(method, *args, &block)
      # To support underscores, we camelize the method name

      # Thanks for the camelize gsub, Rails
      method = method.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }

      # We need to downcase the first letter of every API method
      # and MailChimp has a few of API methods that end in "AIM," which
      # must be upcased (See "Campaign Report Data Methods" in their API docs).
      method = method[0].chr.downcase + method[1..-1].gsub(/aim$/i, 'AIM')

      call(method, *args, &block)
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
