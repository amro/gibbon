require 'helper'
require 'cgi'

class TestGibbon < Test::Unit::TestCase

  context "attributes" do

    setup do
      @api_key = "123-us1"
    end

    should "have no API by default" do
      @gibbon = Gibbon::API.new
      assert_equal(nil, @gibbon.api_key)
    end

    should "set an API key in constructor" do
      @gibbon = Gibbon::API.new(@api_key)
      assert_equal(@api_key, @gibbon.api_key)
    end

    should "set an API key from the 'MAILCHIMP_API_KEY' ENV variable" do
      ENV['MAILCHIMP_API_KEY'] = @api_key
      @gibbon = Gibbon::API.new
      assert_equal(@api_key, @gibbon.api_key)
      ENV.delete('MAILCHIMP_API_KEY')
    end

    should "set an API key via setter" do
      @gibbon = Gibbon::API.new
      @gibbon.api_key = @api_key
      assert_equal(@api_key, @gibbon.api_key)
    end

    should "set timeout and get" do
      @gibbon = Gibbon::API.new
      timeout = 30
      @gibbon.timeout = timeout
      assert_equal(timeout, @gibbon.timeout)
    end

    should "detect api endpoint from initializer parameters" do
      api_endpoint = 'https://us6.api.mailchimp.com'
      @gibbon = Gibbon::API.new(@api_key, :api_endpoint => api_endpoint)
      assert_equal api_endpoint, @gibbon.api_endpoint
    end
  end

  context "build api url" do
    setup do
      @gibbon = Gibbon::API.new
      @url = "https://api.mailchimp.com/1.3/?method=sayHello"
    end

    should "handle empty api key" do
      expect_post(@url, {"apikey" => nil})
      @gibbon.say_hello
    end

    should "handle malformed api key" do
      @api_key = "123"
      @gibbon.api_key = @api_key
      expect_post(@url, {"apikey" => @api_key})
      @gibbon.say_hello
    end

    should "handle timeout" do
      expect_post(@url, {"apikey" => nil}, 120)
      @gibbon.timeout=120
      @gibbon.say_hello
    end

    should "handle api key with dc" do
      @api_key = "TESTKEY-us1"
      @gibbon.api_key = @api_key
      expect_post("https://us1.api.mailchimp.com/1.3/?method=sayHello", {"apikey" => @api_key})
      @gibbon.say_hello
    end

    # when the end user has signed in via oauth, api_key and endpoint should be supplied separately
    should "not require datacenter in api key" do
      @api_key = "TESTKEY"
      @gibbon.api_key = @api_key
      @gibbon.api_endpoint = "https://us6.api.mailchimp.com"
      expect_post("https://us6.api.mailchimp.com/1.3/?method=sayHello", {"apikey" => @api_key})
      @gibbon.say_hello      
    end
  end
  
  context "Gibbon class variables" do
    setup do
      Gibbon::API.api_key = "123-us1"
      Gibbon::API.timeout = 15
      Gibbon::API.throws_exceptions = false
      Gibbon::API.api_endpoint = 'https://us6.api.mailchimp.com'
    end
    
    teardown do
      Gibbon::API.api_key = nil
      Gibbon::API.timeout = nil
      Gibbon::API.throws_exceptions = nil
      Gibbon::API.api_endpoint = nil
    end
    
    should "set api key on new instances" do
      assert_equal(Gibbon::API.new.api_key, Gibbon::API.api_key)
    end

    should "set timeout on new instances" do
      assert_equal(Gibbon::API.new.timeout, Gibbon::API.timeout)
    end
    
    should "set throws_exceptions on new instances" do
      assert_equal(Gibbon::API.new.throws_exceptions, Gibbon::API.throws_exceptions)
    end

    should "set api_endpoint on new instances" do
      assert Gibbon::API.api_endpoint
      assert_equal(Gibbon::API.new.api_endpoint, Gibbon::API.api_endpoint)
    end
  end

  context "build api body" do
    setup do
      @key = "TESTKEY-us1"
      @gibbon = Gibbon::API.new(@key)
      @url = "https://us1.api.mailchimp.com/1.3/?method=sayHello"
      @body = {"apikey" => @key}
    end

    should "escape string parameters" do
      @message = "simon says"
      expect_post(@url, @body.merge("message" => CGI::escape(@message)))
      @gibbon.say_hello(:message => @message)
    end

    should "escape string parameters in an array" do
      expect_post(@url, @body.merge("messages" => ["simon+says", "do+this"]))
      @gibbon.say_hello(:messages => ["simon says", "do this"])
    end

    should "escape string parameters in a hash" do
      expect_post(@url, @body.merge("messages" => {"simon+says" => "do+this"}))
      @gibbon.say_hello(:messages => {"simon says" => "do this"})
    end

    should "escape nested string parameters" do
      expect_post(@url, @body.merge("messages" => {"simon+says" => ["do+this", "and+this"]}))
      @gibbon.say_hello(:messages => {"simon says" => ["do this", "and this"]})
    end

    should "pass through non string parameters" do
      expect_post(@url, @body.merge("fee" => 99))
      @gibbon.say_hello(:fee => 99)
    end
  end

  context "Gibbon instances" do
    setup do
      @key = "TESTKEY-us1"
      @gibbon = Gibbon::API.new(@key)
      @url = "https://us1.api.mailchimp.com/1.3/?method=sayHello"
      @body = {"apikey" => @key}
      @returns = Struct.new(:body).new(MultiJson.dump(["array", "entries"]))
    end

    should "produce a good exporter" do
      @exporter = @gibbon.get_exporter
      assert_equal(@exporter.api_key, @gibbon.api_key)
    end

    should "not throw exception if configured to and the API replies with a JSON hash containing a key called 'error'" do
      @gibbon.throws_exceptions = false
      Gibbon::API.stubs(:post).returns(Struct.new(:body).new(MultiJson.dump({'error' => 'bad things'})))
      assert_nothing_raised do
        @gibbon.say_hello
      end
    end

    should "throw exception if configured to and the API replies with a JSON hash containing a key called 'error'" do
      @gibbon.throws_exceptions = true
      Gibbon::API.stubs(:post).returns(Struct.new(:body).new(MultiJson.dump({'error' => 'bad things'})))
      assert_raise Gibbon::MailChimpError do
        @gibbon.say_hello
      end
    end
    
    should "not raise exception if the api returns no response body" do
      Gibbon::API.stubs(:post).returns(Struct.new(:body).new(nil))
      assert_nil @gibbon.say_hello
    end
  end

  context "export API" do
    setup do
      @key = "TESTKEY-us1"
      @gibbon = Gibbon::Export.new(@key)
      @url = "http://us1.api.mailchimp.com/export/1.0/"
      @body = {:apikey => @key, :id => "listid"}
      @returns = Struct.new(:body).new(MultiJson.dump(["array", "entries"]))
    end

    should "handle api key with dc" do
      @api_key = "TESTKEY-us2"
      @gibbon = Gibbon::Export.new(@api_key)

      params = {:body => CGI::escape(MultiJson.dump(@body)), :timeout => 30}
    
      url = @url.gsub('us1', 'us2') + "sayHello/"
      Gibbon::Export.expects(:post).with(url, params).returns(@returns)
      @gibbon.say_hello(@body)
    end

    should "not throw exception if the Export API replies with a JSON hash containing a key called 'error'" do
      @gibbon.throws_exceptions = false
      Gibbon::Export.stubs(:post).returns(Struct.new(:body).new(MultiJson.dump({'error' => 'bad things'})))

      assert_nothing_raised do
        @gibbon.say_hello(@body)
      end
    end

    should "throw exception if configured to and the Export API replies with a JSON hash containing a key called 'error'" do
      @gibbon.throws_exceptions = true
      params = {:body => @body, :timeout => 30}
      reply = Struct.new(:body).new MultiJson.dump({'error' => 'bad things', 'code' => '123'})
      Gibbon::Export.stubs(:post).returns reply

      assert_raise Gibbon::MailChimpError do
        @gibbon.say_hello(@body)
      end
    end

  end

  private

  def expect_post(expected_url, expected_body, expected_timeout=30)
    Gibbon::API.expects(:post).with do |url, opts|
      url == expected_url &&
      MultiJson.load(URI::decode(opts[:body])) == expected_body &&
      opts[:timeout] == expected_timeout
    end.returns(Struct.new(:body).new(""))
  end
end
