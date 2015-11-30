require 'spec_helper'
require 'cgi'

describe Gibbon do
  describe "attributes" do
    before do
      Gibbon::APIRequest.send(:public, *Gibbon::APIRequest.protected_instance_methods)

      @api_key = "123-us1"
      @proxy_url = 'the_proxy_url'
    end

    it "have no API by default" do
      @gibbon = Gibbon::Request.new
      expect(@gibbon.api_key).to be_nil
    end
    
    it "set an API key in constructor" do
      @gibbon = Gibbon::Request.new(api_key: @api_key)
      expect(@gibbon.api_key).to eq(@api_key)
    end

    it "set an API key from the 'MAILCHIMP_API_KEY' ENV variable" do
      ENV['MAILCHIMP_API_KEY'] = @api_key
      @gibbon = Gibbon::Request.new
      expect(@gibbon.api_key).to eq(@api_key)
      ENV.delete('MAILCHIMP_API_KEY')
    end

    it "set an API key via setter" do
      @gibbon = Gibbon::Request.new
      @gibbon.api_key = @api_key
      expect(@gibbon.api_key).to eq(@api_key)
    end

    it "set timeout and get" do
      @gibbon = Gibbon::Request.new
      timeout = 30
      @gibbon.timeout = timeout
      expect(timeout).to eq(@gibbon.timeout)
    end

    it "timeout properly passed to APIRequest" do
      @gibbon = Gibbon::Request.new
      timeout = 30
      @gibbon.timeout = timeout
      @request = Gibbon::APIRequest.new(builder: @gibbon)
      expect(timeout).to eq(@request.timeout)
    end

    it "detect api endpoint from initializer parameters" do
      api_endpoint = 'https://us6.api.mailchimp.com'
      @gibbon = Gibbon::Request.new(api_key: @api_key, api_endpoint: api_endpoint)
      expect(api_endpoint).to eq(@gibbon.api_endpoint)
    end
    
    it "have no Proxy url by default" do
      @gibbon = Gibbon::Request.new
      expect(@gibbon.proxy_url).to be_nil
    end    

    it "set an proxy url key from the 'MAILCHIMP_PROXY_URL' ENV variable" do
      ENV['MAILCHIMP_PROXY_URL'] = @proxy_url
      @gibbon = Gibbon::Request.new
      expect(@gibbon.proxy_url).to eq(@proxy_url)
      ENV.delete('MAILCHIMP_PROXY_URL')
    end  
    
    it "set an API key via setter" do
      @gibbon = Gibbon::Request.new
      @gibbon.proxy_url = @proxy_url
      expect(@gibbon.proxy_url).to eq(@proxy_url)
    end    
  end

  describe "build api url" do
    before do
      Gibbon::APIRequest.send(:public, *Gibbon::APIRequest.protected_instance_methods)

      @gibbon = Gibbon::Request.new
      @url = "https://api.mailchimp.com/3.0/lists/"
    end

    it "doesn't allow empty api key" do
      expect {@gibbon.try.retrieve}.to raise_error(Gibbon::GibbonError)
    end

    it "doesn't allow api key without data center" do
      @api_key = "123"
      @gibbon.api_key = @api_key
      expect {@gibbon.try.retrieve}.to raise_error(Gibbon::GibbonError)
    end

    it "sets correct endpoint from api key" do
      @api_key = "TESTKEY-us1"
      @gibbon.api_key = @api_key
      @gibbon.try
      @request = Gibbon::APIRequest.new(builder: @gibbon)
      expect(@request.api_url).to eq("https://us1.api.mailchimp.com/3.0/try")
    end

    # when the end user has signed in via oauth, api_key and endpoint it be supplied separately
    it "not require datacenter in api key" do
      @api_key = "TESTKEY"
      @gibbon.api_key = @api_key
      @gibbon.api_endpoint = "https://us6.api.mailchimp.com"
      @request = Gibbon::APIRequest.new(builder: @gibbon)
      expect {@request.validate_api_key}.not_to raise_error
    end
  end

  describe "class variables" do
    before do
      Gibbon::Request.api_key = "123-us1"
      Gibbon::Request.timeout = 15
      Gibbon::Request.api_endpoint = 'https://us6.api.mailchimp.com'
    end

    after do
      Gibbon::Request.api_key = nil
      Gibbon::Request.timeout = nil
      Gibbon::Request.api_endpoint = nil
    end

    it "set api key on new instances" do
      expect(Gibbon::Request.new.api_key).to eq(Gibbon::Request.api_key)
    end

    it "set timeout on new instances" do
      expect(Gibbon::Request.new.timeout).to eq(Gibbon::Request.timeout)
    end

    it "set api_endpoint on new instances" do
      expect(Gibbon::Request.api_endpoint).not_to be_nil
      expect(Gibbon::Request.new.api_endpoint).to eq(Gibbon::Request.api_endpoint)
    end
  end
end
