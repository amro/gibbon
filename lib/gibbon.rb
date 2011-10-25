require 'active_support'
require 'httparty'
require 'json'
require 'cgi'

class Gibbon
  include HTTParty
  format :plain
  default_timeout 30

  attr_accessor :api_key, :timeout

  def initialize(api_key = nil, extra_params = {})
    @api_key = api_key || ENV['MC_API_KEY'] || ENV['MAILCHIMP_API_KEY'] || self.class.api_key
    @default_params = {:apikey => @api_key}.merge(extra_params)
  end

  def api_key=(value)
    @api_key = value
    @default_params = @default_params.merge({:apikey => @api_key})
  end

  def get_exporter
    GibbonExport.new(@api_key, @default_params)
  end

  def base_api_url
    "https://#{dc_from_api_key}api.mailchimp.com/1.3/?method="
  end

protected

  def call(method, params = {})
    url = base_api_url + method
    params = @default_params.merge(params)
    response = self.class.post(url, :body => CGI::escape(params.to_json), :timeout => @timeout)

    begin
      response = ActiveSupport::JSON.decode(response.body)
    rescue
      response = response.body
    end
    response
  end

  def method_missing(method, *args)
    method = method.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase } #Thanks for the gsub, Rails
    method = method[0].chr.downcase + method[1..-1].gsub(/aim$/i, 'AIM')
    args = {} unless args.length > 0
    args = args[0] if (args.class.to_s == "Array")
    call(method, args)
  end

  class << self
    attr_accessor :api_key

    def method_missing(sym, *args, &block)
      new(self.api_key).send(sym, *args, &block)
    end
  end

  def dc_from_api_key
    (@api_key.nil? || @api_key.length == 0 || @api_key !~ /-/) ? '' : "#{@api_key.split("-").last}."
  end
end

class GibbonExport < Gibbon
  def initialize(api_key = nil, extra_params = {})
    super(api_key, extra_params)
  end

protected

  def export_api_url
    "http://#{dc_from_api_key}api.mailchimp.com/export/1.0/"
  end

  def call(method, params = {})
    url = export_api_url + method + "/"
    params = @default_params.merge(params)
    response = self.class.post(url, :body => params, :timeout => @timeout)

    response.body.lines
  end
end
