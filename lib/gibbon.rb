require 'httparty'
require 'json'
require 'cgi'

class Gibbon
  include HTTParty
  format :plain
  default_timeout 30
  disable_rails_query_string_format

  attr_accessor :api_key, :timeout, :throws_exceptions

  MailChimpError = Class.new(StandardError)

  def initialize(api_key = nil, default_parameters = {})
    @api_key = api_key || ENV['MAILCHIMP_API_KEY'] || self.class.api_key

    # Remove and set the timeout b/c we don't want it passed to MailChimp
    @timeout = default_parameters.delete(:timeout)

    @default_params = {:apikey => @api_key}.merge(default_parameters)
    
    # Default to throwing exceptions
    @throws_exceptions = true
  end

  def api_key=(value)
    @api_key = value
    @default_params = @default_params.merge({:apikey => @api_key})
  end

  def get_exporter
    GibbonExport.new(@api_key, @default_params)
  end

  protected

  def base_api_url
    "https://#{dc_from_api_key}api.mailchimp.com/1.3/?method="
  end

  def call(method, params = {})
    api_url = base_api_url + method
    params = @default_params.merge(params)
    response = self.class.post(api_url, :body => CGI::escape(params.to_json), :timeout => @timeout)
    
    # MailChimp API sometimes returns JSON fragments (e.g. true from listSubscribe)
    # so we parse after adding brackets to create a JSON array so 
    # JSON.parse succeeds in those cases.
    parsed_response = JSON.parse('[' + response.body + ']').first

    if should_raise_for_response(parsed_response)
      raise MailChimpError.new("MailChimp API Error: #{parsed_response["error"]} (code #{parsed_response["code"]})")
    end

    # Some calls (e.g. listSubscribe) return json fragments
    # (e.g. true) so wrap in an array prior to parsing
    response = JSON.parse('['+response.body+']').first

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

  def should_raise_for_response(response)
    @throws_exceptions && response.is_a?(Hash) && response["error"]
  end

  def base_api_url
    "https://#{get_data_center_from_api_key}api.mailchimp.com/1.3/?method="
  end

  class << self
    attr_accessor :api_key

    def method_missing(sym, *args, &block)
      new(self.api_key).send(sym, *args, &block)
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
    response = self.class.post(api_url, :body => params, :timeout => @timeout)

    lines = response.body.lines
    if @throws_exceptions
      first_line_object = JSON.parse(lines.first) if lines.first
      raise MailChimpError.new("MailChimp Export API Error: #{first_line_object["error"]} (code #{first_line_object["code"]})") if should_raise_for_response(first_line_object)
    end

    lines
  end
end