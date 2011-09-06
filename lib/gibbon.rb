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

  def base_api_url
    dc = @api_key.blank? ? '' : "#{@api_key.split("-").last}."
    "https://#{dc}api.mailchimp.com/1.3/?method="
  end

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
end