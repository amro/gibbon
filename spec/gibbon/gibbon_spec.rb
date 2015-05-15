require 'spec_helper'
require 'cgi'

describe Gibbon do

  describe "attributes" do
    before do
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

    it "detect api endpoint from initializer parameters" do
      api_endpoint = 'https://us6.api.mailchimp.com'
      @gibbon = Gibbon::Request.new(api_key: @api_key, api_endpoint: api_endpoint)
      expect(api_endpoint).to eq(@gibbon.api_endpoint)
    end
  end

  describe "build api url" do
    before do
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

    # it "handle timeout" do
    #   expect_request(@url, {"apikey" => 'test'}, 120)
    #   @gibbon.api_key = 'test-123'
    #   @gibbon.timeout = 120
    #   @gibbon.try.retrieve
    # end

    # it "handle api key with dc" do
    #   @api_key = "TESTKEY-us1"
    #   @gibbon.api_key = @api_key
    #   expect_request(:get, "https://us1.api.mailchimp.com/3.0/try")
    #   @gibbon.try.retrieve
    # end

    # # when the end user has signed in via oauth, api_key and endpoint it be supplied separately
    # it "not require datacenter in api key" do
    #   @api_key = "TESTKEY"
    #   @gibbon.api_key = @api_key
    #   @gibbon.api_endpoint = "https://us6.api.mailchimp.com"
    #   expect_request("https://us6.api.mailchimp.com/2.0/say/hello", {"apikey" => @api_key})
    #   @gibbon.should.retrieve
    # end
  end

  describe "Gibbon class variables" do
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

  describe "build api body" do
    # before do
    #   @key = "TESTKEY-us1"
    #   @gibbon = Gibbon::Request.new(@key)
    #   @url = "https://us1.api.mailchimp.com/2.0/say/hello"
    #   @body = {"apikey" => @key}
    # end
    #
    # it "works for string parameters" do
    #   @message = "simon says"
    #   expect_request(@url, @body.merge("message" => @message))
    #   @gibbon.should.retrieve(:message => @message)
    # end
    #
    # it "works for string parameters in an array" do
    #   expect_request(@url, @body.merge("messages" => ["simon says", "do this"]))
    #   @gibbon.should.retrieve(:messages => ["simon says", "do this"])
    # end
    #
    # it "works for string parameters in a hash" do
    #   expect_request(@url, @body.merge("messages" => {"simon says" => "do this"}))
    #   @gibbon.should.retrieve(:messages => {"simon says" => "do this"})
    # end
    #
    # it "works for nested string parameters" do
    #   expect_request(@url, @body.merge("messages" => {"simon says" => ["do this", "and this"]}))
    #   @gibbon.should.retrieve(:messages => {"simon says" => ["do this", "and this"]})
    # end
    #
    # it "pass through non string parameters" do
    #   expect_request(@url, @body.merge("fee" => 99))
    #   @gibbon.should.retrieve(:fee => 99)
    # end
    #
    # it "pass through http header settings" do
    #   @gibbon.timeout=30
    #   expect_request(@url, @body.merge("messages" => 'Simon says'), @gibbon.timeout, {'Accept-Language' => 'en'})
    #   @gibbon.should.retrieve(:messages => 'Simon says', :headers => {'Accept-Language' => 'en'} )
    # end
    #
    # it "with http headers not set" do
    #   @gibbon.timeout=30
    #   expect_request(@url, @body.merge("messages" => 'Simon says'), @gibbon.timeout, {})
    #   @gibbon.should.retrieve(:messages => 'Simon says' )
    # end
  end

  describe "Gibbon instances" do
    before do
      @key = "TESTKEY-us1"
      @gibbon = Gibbon::Request.new(api_key: @key)
      @url = "https://us1.api.mailchimp.com/3.0/try"
      @body = nil
      @returns = Struct.new(:body).new(MultiJson.dump(["array", "entries"]))
    end

    # it "throw exception if API replies with 4" do
    #   @gibbon.throws_exceptions = true
    #   allow(Gibbon::APIRequest).to receive(:get).and_return(Struct.new(:body).new(MultiJson.dump({'error' => 'bad things'})))
    #   expect {@gibbon.try.retrieve}.to raise_error(Gibbon::MailChimpError)
    # end
    # 
    # it "not raise exception if the api returns no response body" do
    #   allow(Gibbon::RequestCategory).to receive(:post).and_return(Struct.new(:body).new(nil))
    #   expect(@gibbon.should.retrieve).to be_nil
    # end
    #
    # it "can send a campaign" do
    #   allow(Gibbon::RequestCategory).to receive(:post).and_return(Struct.new(:body).new(MultiJson.dump({"cid" => "1234567"})))
    #   expect(@gibbon.campaigns.send({"cid" => "1234567"})).to eq({"cid" => "1234567"})
    # end
    #
    # it "not throw exception if configured to and the API returns an unparsable response" do
    #   @gibbon.throws_exceptions = false
    #   allow(Gibbon::RequestCategory).to receive(:post).and_return(Struct.new(:body).new("<HTML>Invalid response</HTML>"))
    #   expect(@gibbon.should.retrieve).to eq({"name" => "UNPARSEABLE_RESPONSE", "error" => "Unparseable response: <HTML>Invalid response</HTML>", "code" => 500})
    # end
    #
    # it "throw exception if configured to and the API returns an unparsable response" do
    #   @gibbon.throws_exceptions = true
    #   allow(Gibbon::RequestCategory).to receive(:post).and_return(Struct.new(:body).new("<HTML>Invalid response</HTML>"))
    #   expect{@gibbon.should.retrieve}.to raise_error(Gibbon::MailChimpError)
    # end
  end

  private

  def expect_request(verb, expected_url, expected_body = nil, expected_timeout = 30, expected_headers = {})
    expect(Gibbon::APIRequest).to receive(verb) { |url, opts|
      puts "FOO: #{url}, #{opts}"
      expect(url).to            eq expected_url
      expect(expected_body).to  eq MultiJson.load(URI::decode(opts[:body])) if expected_body
      expect(opts[:timeout]).to eq expected_timeout
      expect(opts[:headers]).to eq expected_headers
    }.and_return(Struct.new(:body).new("[]"))
  end
end

