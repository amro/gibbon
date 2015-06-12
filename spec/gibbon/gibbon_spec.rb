require 'spec_helper'
require 'cgi'
require 'webmock'
require 'webmock/rspec'

describe Gibbon do

  describe "attributes" do

    before do
      @api_key = "123-us1"
    end

    it "have no API by default" do
      @gibbon = Gibbon::API.new
      expect(@gibbon.api_key).to be_nil
    end

    it "set an API key in constructor" do
      @gibbon = Gibbon::API.new(@api_key)
      expect(@gibbon.api_key).to eq(@api_key)
    end

    it "set an API key from the 'MAILCHIMP_API_KEY' ENV variable" do
      ENV['MAILCHIMP_API_KEY'] = @api_key
      @gibbon = Gibbon::API.new
      expect(@gibbon.api_key).to eq(@api_key)
      ENV.delete('MAILCHIMP_API_KEY')
    end

    it "set an API key via setter" do
      @gibbon = Gibbon::API.new
      @gibbon.api_key = @api_key
      expect(@gibbon.api_key).to eq(@api_key)
    end

    it "set timeout and get" do
      @gibbon = Gibbon::API.new
      timeout = 30
      @gibbon.timeout = timeout
      expect(timeout).to eq(@gibbon.timeout)
    end

    it "detect api endpoint from initializer parameters" do
      api_endpoint = 'https://us6.api.mailchimp.com'
      @gibbon = Gibbon::API.new(@api_key, :api_endpoint => api_endpoint)
      expect(api_endpoint).to eq(@gibbon.api_endpoint)
    end

    it "sets the 'throws_exceptions' option from initializer parameters" do
      @gibbon = Gibbon::API.new(@api_key, :throws_exceptions => false)
      expect(false).to eq(@gibbon.throws_exceptions)
    end
  end

  describe "build api url" do
    before do
      @gibbon = Gibbon::API.new
      @url = "https://api.mailchimp.com/2.0/say/hello"
    end

    it "doesn't allow empty api key" do
      expect {@gibbon.say.hello}.to raise_error(Gibbon::GibbonError)
    end

    it "handle malformed api key" do
      @api_key = "123"
      @gibbon.api_key = @api_key
      expect_post(@url, {"apikey" => @api_key})
      @gibbon.say.hello
    end

    it "handle timeout" do
      expect_post(@url, {"apikey" => 'test'}, 120)
      @gibbon.api_key = 'test'
      @gibbon.timeout=120
      @gibbon.say.hello
    end

    it "handle api key with dc" do
      @api_key = "TESTKEY-us1"
      @gibbon.api_key = @api_key
      expect_post("https://us1.api.mailchimp.com/2.0/say/hello", {"apikey" => @api_key})
      @gibbon.say.hello
    end

    # when the end user has signed in via oauth, api_key and endpoint it be supplied separately
    it "not require datacenter in api key" do
      @api_key = "TESTKEY"
      @gibbon.api_key = @api_key
      @gibbon.api_endpoint = "https://us6.api.mailchimp.com"
      expect_post("https://us6.api.mailchimp.com/2.0/say/hello", {"apikey" => @api_key})
      @gibbon.say.hello
    end
  end

  describe "Gibbon class variables" do
    before do
      Gibbon::API.api_key = "123-us1"
      Gibbon::API.timeout = 15
      Gibbon::API.throws_exceptions = false
      Gibbon::API.api_endpoint = 'https://us6.api.mailchimp.com'
    end

    after do
      Gibbon::API.api_key = nil
      Gibbon::API.timeout = nil
      Gibbon::API.throws_exceptions = nil
      Gibbon::API.api_endpoint = nil
    end

    it "set api key on new instances" do
      expect(Gibbon::API.new.api_key).to eq(Gibbon::API.api_key)
    end

    it "set timeout on new instances" do
      expect(Gibbon::API.new.timeout).to eq(Gibbon::API.timeout)
    end

    it "set throws_exceptions on new instances" do
      expect(Gibbon::API.new.throws_exceptions).to eq(Gibbon::API.throws_exceptions)
    end

    it "set api_endpoint on new instances" do
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
      @return_items = ["array", "entries"]
      @returns = MultiJson.dump(@return_items)
    end

    it "handle api key with dc" do
      @api_key = "TESTKEY-us2"
      @gibbon = Gibbon::Export.new(@api_key)

      @body[:apikey] = @api_key
      url = @url.gsub('us1', 'us2') + "sayHello/"

      # Fake request
      stub_request(:post, url).
        to_return(:body => @returns, :status => 200)

      # Check request url
      @gibbon.say_hello(@body)
      expect(WebMock).to have_requested(:post, url).with(:body => @body)
    end

    it "uses timeout if set" do
      Gibbon::Export.timeout = 45
      expect(Gibbon::Export.new.timeout).to eql 45
    end

    it "not throw exception if the Export API replies with a JSON hash containing a key called 'error'" do
      @gibbon.throws_exceptions = false
      reply = MultiJson.dump({:error => 'bad things'})
      stub_request(:post, @url + 'sayHello/').
        to_return(:body => reply, :status => 200)

      @gibbon.say_hello(@body)
    end

    it "throw exception if configured to and the Export API replies with a JSON hash containing a key called 'error'" do
      @gibbon.throws_exceptions = true
      reply = MultiJson.dump({:error => 'bad things', :code => '123'})
      stub_request(:post, @url + 'sayHello/').
        to_return(:body => reply, :status => 200)

      expect {@gibbon.say_hello(@body)}.to raise_error(Gibbon::MailChimpError)
    end

    it "should handle a single empty space response without throwing an exception" do
      @gibbon.throws_exceptions = true
      stub_request(:post, @url + 'sayHello/').
        to_return(:body => " ", :status => 200)
      #allow(Gibbon::Export).to receive(:post).and_return(Struct.new(:body).new(" "))

      expect(@gibbon.say_hello(@body)).to eq([])
    end

    it "should handle an empty response without throwing an exception" do
      @gibbon.throws_exceptions = true
      stub_request(:post, @url + 'sayHello/').
        to_return(:body => "", :status => 200)
      #allow(Gibbon::Export).to receive(:post).and_return(Struct.new(:body).new(""))

      expect(@gibbon.say_hello(@body)).to eq([])
    end

    it "should feed API results per row to a given block" do
      # Fake request
      stub_request(:post, @url + 'sayHello/').
        to_return(:body => @returns, :status => 200)

      # Check request url
      @result = []
      @gibbon.say_hello(@body) { |res| @result << res }
      expect(@result).to contain_exactly(@return_items)
    end


  end

  private

  def expect_post(expected_url, expected_body, expected_timeout=30, expected_headers={})
    expect(Gibbon::APICategory).to receive(:post) { |url, opts|
      expect(url).to            eq expected_url
      expect(expected_body).to  eq MultiJson.load(URI::decode(opts[:body]))
      expect(opts[:timeout]).to eq expected_timeout
      expect(opts[:headers]).to eq expected_headers
    }.and_return(Struct.new(:body).new("[]"))
  end
end

