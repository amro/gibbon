require 'spec_helper'
require 'cgi'

describe Gibbon do
  describe "attributes" do
    before do
      Gibbon::APIRequest.send(:public, *Gibbon::APIRequest.protected_instance_methods)

      @api_key = "123-us1"
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
<<<<<<< HEAD
      expect(Gibbon::Request.api_endpoint).not_to be_nil
      expect(Gibbon::Request.new.api_endpoint).to eq(Gibbon::Request.api_endpoint)
=======
      expect(Gibbon::API.api_endpoint).not_to be_nil
      expect(Gibbon::API.new.api_endpoint).to eq(Gibbon::API.api_endpoint)
    end
  end

  describe "build api body" do
    before do
      @key = "TESTKEY-us1"
      @gibbon = Gibbon::API.new(@key)
      @url = "https://us1.api.mailchimp.com/2.0/say/hello"
      @body = {"apikey" => @key}
    end

    it "works for string parameters" do
      @message = "simon says"
      expect_post(@url, @body.merge("message" => @message))
      @gibbon.say.hello(:message => @message)
    end

    it "works for string parameters in an array" do
      expect_post(@url, @body.merge("messages" => ["simon says", "do this"]))
      @gibbon.say.hello(:messages => ["simon says", "do this"])
    end

    it "works for string parameters in a hash" do
      expect_post(@url, @body.merge("messages" => {"simon says" => "do this"}))
      @gibbon.say.hello(:messages => {"simon says" => "do this"})
    end

    it "works for nested string parameters" do
      expect_post(@url, @body.merge("messages" => {"simon says" => ["do this", "and this"]}))
      @gibbon.say.hello(:messages => {"simon says" => ["do this", "and this"]})
    end

    it "pass through non string parameters" do
      expect_post(@url, @body.merge("fee" => 99))
      @gibbon.say.hello(:fee => 99)
    end

    it "pass through http header settings" do
      @gibbon.timeout=30
      expect_post(@url, @body.merge("messages" => 'Simon says'), @gibbon.timeout, {'Accept-Language' => 'en'})
      @gibbon.say.hello(:messages => 'Simon says', :headers => {'Accept-Language' => 'en'} )
    end

    it "with http headers not set" do
      @gibbon.timeout=30
      expect_post(@url, @body.merge("messages" => 'Simon says'), @gibbon.timeout, {})
      @gibbon.say.hello(:messages => 'Simon says' )
    end

  end

  describe "Gibbon instances" do
    before do
      @key = "TESTKEY-us1"
      @gibbon = Gibbon::API.new(@key)
      @url = "https://us1.api.mailchimp.com/2.0/say/hello"
      @body = {"apikey" => @key}
      @returns = Struct.new(:body).new(MultiJson.dump(["array", "entries"]))
    end

    it "produce a good exporter" do
      @exporter = @gibbon.get_exporter
      expect(@exporter.api_key).to eq(@gibbon.api_key)
    end

    it "not throw exception if configured to and the API replies with a JSON hash containing a key called 'error'" do
      @gibbon.throws_exceptions = false
      allow(Gibbon::APICategory).to receive(:post).and_return(Struct.new(:body).new(MultiJson.dump({'error' => 'bad things'})))

      @gibbon.say.hello
    end

    it "throw exception if configured to and the API replies with a JSON hash containing a key called 'error'" do
      @gibbon.throws_exceptions = true
      allow(Gibbon::APICategory).to receive(:post).and_return(Struct.new(:body).new(MultiJson.dump({'error' => 'bad things'})))
      expect {@gibbon.say.hello}.to raise_error(Gibbon::MailChimpError)
    end

    it "not raise exception if the api returns no response body" do
      allow(Gibbon::APICategory).to receive(:post).and_return(Struct.new(:body).new(nil))
      expect(@gibbon.say.hello).to be_nil
    end

    it "can send a campaign" do
      allow(Gibbon::APICategory).to receive(:post).and_return(Struct.new(:body).new(MultiJson.dump({"cid" => "1234567"})))
      expect(@gibbon.campaigns.send({"cid" => "1234567"})).to eq({"cid" => "1234567"})
    end

    it "not throw exception if configured to and the API returns an unparsable response" do
      @gibbon.throws_exceptions = false
      allow(Gibbon::APICategory).to receive(:post).and_return(Struct.new(:body).new("<HTML>Invalid response</HTML>"))
      expect(@gibbon.say.hello).to eq({"name" => "UNPARSEABLE_RESPONSE", "error" => "Unparseable response: <HTML>Invalid response</HTML>", "code" => 500})
    end

    it "throw exception if configured to and the API returns an unparsable response" do
      @gibbon.throws_exceptions = true
      allow(Gibbon::APICategory).to receive(:post).and_return(Struct.new(:body).new("<HTML>Invalid response</HTML>"))
      expect{@gibbon.say.hello}.to raise_error(Gibbon::MailChimpError)
    end
  end

  describe "export API" do
    before do
      @key = "TESTKEY-us1"
      @gibbon = Gibbon::Export.new(@key)
      @url = "http://us1.api.mailchimp.com/export/1.0/"
      @body = {:apikey => @key, :id => "listid"}
      @returns = Struct.new(:body).new(MultiJson.dump(["array", "entries"]))
    end

    it "handle api key with dc" do
      @api_key = "TESTKEY-us2"
      @gibbon = Gibbon::Export.new(@api_key)

      @body[:apikey] = @api_key
      params = {:body => MultiJson.dump(@body), :timeout => 30}

      url = @url.gsub('us1', 'us2') + "sayHello/"
      expect(Gibbon::Export).to receive(:post).with(url, params).and_return(@returns)
      @gibbon.say_hello(@body)
    end

    it "uses timeout if set" do
      Gibbon::Export.timeout = 45
      expect(Gibbon::Export.new.timeout).to eql 45
    end

    it "not throw exception if the Export API replies with a JSON hash containing a key called 'error'" do
      @gibbon.throws_exceptions = false
      allow(Gibbon::Export).to receive(:post).and_return(Struct.new(:body).new(MultiJson.dump({'error' => 'bad things'})))

      @gibbon.say_hello(@body)
>>>>>>> 1d8ee00f576d354d5cc1f5bd1ec166d8565db1ca
    end
  end
end

