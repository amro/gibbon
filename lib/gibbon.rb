require 'httparty'
require 'json'
require 'cgi'

class Gibbon
  include HTTParty
  format :plain
  default_timeout 30

  attr_accessor :api_key, :api_endpoint, :timeout, :throws_exceptions

  MailChimpError = Class.new(StandardError)

  def initialize(api_key = nil, default_parameters = {})
    @api_key = api_key || self.class.api_key || ENV['MAILCHIMP_API_KEY']
    @api_key = @api_key.strip if @api_key

    @api_endpoint = default_parameters.delete(:api_endpoint)
    @timeout = default_parameters.delete(:timeout)
    @throws_exceptions = default_parameters.delete(:throws_exceptions)
  
    @default_params = {apikey: @api_key}.merge(default_parameters)
    
    set_instance_defaults
  end
  
  def api_key=(value)
    @api_key = value.strip if value
    @default_params = @default_params.merge({apikey: @api_key})
  end

  def get_exporter
    GibbonExport.new(@api_key, @default_params)
  end

  protected

  def call(method, params = {})
    api_url = base_api_url + method
    params = @default_params.merge(params)
    response = self.class.post(api_url, body: CGI::escape(params.to_json), timeout: @timeout)
    
    # MailChimp API sometimes returns JSON fragments (e.g. true from listSubscribe)
    # so we parse after adding brackets to create a JSON array so 
    # JSON.parse succeeds in those cases.
    parsed_response = JSON.parse('[' + response.body + ']').first

    if should_raise_for_response?(parsed_response)
      raise MailChimpError.new("MailChimp API Error: #{parsed_response["error"]} (code #{parsed_response["code"]})")
    end

    parsed_response
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
  
  def set_instance_defaults
    @timeout = (self.class.timeout || 30) if @timeout.nil?
    @api_endpoint = self.class.api_endpoint if @api_endpoint.nil?
    # Two lines because the class variable could be false and (false || true) is always true
    @throws_exceptions = self.class.throws_exceptions if @throws_exceptions.nil?
    @throws_exceptions = true if @throws_exceptions.nil?
  end

  def should_raise_for_response?(response)
    @throws_exceptions && response.is_a?(Hash) && response["error"]
  end

  def base_api_url
    "#{@api_endpoint || get_api_endpoint}/1.3/?method="
  end

  def get_api_endpoint
    "https://#{get_data_center_from_api_key}api.mailchimp.com"
  end

  class << self
    attr_accessor :api_key, :timeout, :throws_exceptions, :api_endpoint

    def method_missing(sym, *args, &block)
      new(self.api_key, {api_endpoint: self.api_endpoint, timeout: self.timeout, throws_exceptions: self.throws_exceptions}).send(sym, *args, &block)
    end
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
  
class GibbonExport < Gibbon
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
    response = self.class.post(api_url, body: CGI::escape(params.to_json), timeout: @timeout)

    lines = response.body.lines
    if @throws_exceptions
      first_line = JSON.parse(lines.first) if lines.first
      
      if should_raise_for_response?(first_line)
        raise MailChimpError.new("MailChimp Export API Error: #{first_line["error"]} (code #{first_line["code"]})")
      end
    end

    lines
  end
end