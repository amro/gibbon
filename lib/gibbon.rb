require 'httparty'
require 'json'
require 'cgi'

module Gibbon
  class API
    include HTTParty
    default_timeout 30

    attr_accessor :apikey, :timeout

    def initialize(apikey = nil, extra_params = {})
      @apikey = apikey
      @default_params = {:apikey => apikey}.merge(extra_params)
    end

    def apikey=(value)
      @apikey = value
      @default_params = @default_params.merge({:apikey => @apikey})
    end

    def base_api_url
      dc = @apikey.blank? ? '' : "#{@apikey.split("-").last}."
      "https://#{dc}api.mailchimp.com/1.3/?method="
    end

    def call(method, params = {})
      url = base_api_url + method
      params = escape_params(@default_params.merge(params))
      response = API.post(url, :body => params.to_json, :timeout => @timeout)

      begin
        response = JSON.parse(response.body)
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
    
    private
    
    def escape_params(param)
      case param
      when String
        CGI::escape(param)
      when Array
        param.collect{|v| escape_params(v)}
      when Hash
        param.keys.inject({}) {|r,k| r[escape_params(k)] = escape_params(param[k]) ;r} 
      else
        param
      end
    end
  end
end