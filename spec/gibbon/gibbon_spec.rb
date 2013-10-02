require 'spec_helper'
require 'cgi'

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

    it "handle empty api key" do
      expect_post(@url, {"apikey" => nil})
      @gibbon.say.hello
    end

    it "handle malformed api key" do
      @api_key = "123"
      @gibbon.api_key = @api_key
      expect_post(@url, {"apikey" => @api_key})
      @gibbon.say.hello
    end

    it "handle timeout" do
      expect_post(@url, {"apikey" => nil}, 120)
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
      Gibbon::APICategory.stub(:post).and_return(Struct.new(:body).new(MultiJson.dump({'error' => 'bad things'})))

      @gibbon.say.hello
    end

    it "throw exception if configured to and the API replies with a JSON hash containing a key called 'error'" do
      @gibbon.throws_exceptions = true
      Gibbon::APICategory.stub(:post).and_return(Struct.new(:body).new(MultiJson.dump({'error' => 'bad things'})))
      expect {@gibbon.say.hello}.to raise_error(Gibbon::MailChimpError)
    end

    it "not raise exception if the api returns no response body" do
      Gibbon::APICategory.stub(:post).and_return(Struct.new(:body).new(nil))
      expect(@gibbon.say.hello).to be_nil
    end

    it "can send a campaign" do
      Gibbon::APICategory.stub(:post).and_return(Struct.new(:body).new(MultiJson.dump({"cid" => "1234567"})))
      expect(@gibbon.campaigns.send({"cid" => "1234567"})).to eq({"cid" => "1234567"})
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
      Gibbon::Export.should_receive(:post).with(url, params).and_return(@returns)
      @gibbon.say_hello(@body)
    end

    it "not throw exception if the Export API replies with a JSON hash containing a key called 'error'" do
      @gibbon.throws_exceptions = false
      Gibbon::Export.stub(:post).and_return(Struct.new(:body).new(MultiJson.dump({'error' => 'bad things'})))

      @gibbon.say_hello(@body)
    end

    it "throw exception if configured to and the Export API replies with a JSON hash containing a key called 'error'" do
      @gibbon.throws_exceptions = true
      params = {:body => @body, :timeout => 30}
      reply = Struct.new(:body).new MultiJson.dump({'error' => 'bad things', 'code' => '123'})
      Gibbon::Export.stub(:post).and_return reply

      expect {@gibbon.say_hello(@body)}.to raise_error(Gibbon::MailChimpError)
    end

  end

  private

  def expect_post(expected_url, expected_body, expected_timeout=30)
    Gibbon::APICategory.should_receive(:post).with do |url, opts|
      expect(url).to            eq expected_url
      expect(expected_body).to  eq MultiJson.load(URI::decode(opts[:body]))
      expect(opts[:timeout]).to eq expected_timeout
    end.and_return(Struct.new(:body).new("[]"))
  end

  # def expect_post(expected_url, expected_body, expected_timeout=30)
  #   Gibbon::APICategory.should_receive(:post).and_return(Struct.new(:body).new(""))
  # end
end
