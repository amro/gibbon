require 'helper'

class TestGibbon < Test::Unit::TestCase

  context "build api url" do

    setup do
      @gibbon = Gibbon.new
    end

    should "handle empty api key" do
      expect_post("https://api.mailchimp.com/1.3/?method=sayHello", {"apikey" => nil})
      @gibbon.say_hello
    end

    should "handle timeout" do
      expect_post("https://api.mailchimp.com/1.3/?method=sayHello", {"apikey" => nil}, 120)
      @gibbon.timeout=120
      @gibbon.say_hello
    end

    should "handle api key with dc" do
      @gibbon.api_key="TESTKEY-us1"
      expect_post("https://us1.api.mailchimp.com/1.3/?method=sayHello", {"apikey" => "TESTKEY-us1"})
      @gibbon.say_hello
    end
  end

  context "build api body" do
    setup do
      @key = "TESTKEY-us1"
      @gibbon = Gibbon.new(@key)
      @url = "https://us1.api.mailchimp.com/1.3/?method=sayHello"
    end

    should "escape string parameters" do
      expect_post(@url, {"apikey" => @key, "message" => "simon+says"})
      @gibbon.say_hello(:message => "simon says")
    end

    should "escape string parameters in an array" do
      expect_post(@url, {"apikey" => @key, "messages" => ["simon+says", "do+this"]})
      @gibbon.say_hello(:messages => ["simon says", "do this"])
    end

    should "escape string parameters in a hash" do
      expect_post(@url, {"apikey" => @key, "messages" => {"simon+says" => "do+this"}})
      @gibbon.say_hello(:messages => {"simon says" => "do this"})
    end

    should "escape nested string parameters" do
      expect_post(@url, {"apikey" => @key, "messages" => {"simon+says" => ["do+this", "and+this"]}})
      @gibbon.say_hello(:messages => {"simon says" => ["do this", "and this"]})
    end

    should "pass through non string parameters" do
      expect_post(@url, {"apikey" => @key, "fee" => 99})
      @gibbon.say_hello(:fee => 99)
    end

  end

  private

  def expect_post(expected_url, expected_body, expected_timeout=nil)
    Gibbon.expects(:post).with do |url, opts|
      url == expected_url &&
      JSON.parse(URI::decode(opts[:body])) == expected_body &&
      opts[:timeout] == expected_timeout
    end.returns(Struct.new(:body).new("") )
  end
end
