require 'helper'
require 'cgi'
require 'ruby-debug'

class TestGibbon < Test::Unit::TestCase

  context "build api url" do
    setup do
      @gibbon = Gibbon.new
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
  end

  context "build api body" do
    setup do
      @key = "TESTKEY-us1"
      @gibbon = Gibbon.new(@key)
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
      @gibbon = Gibbon.new(@key)
      @url = "https://us1.api.mailchimp.com/1.3/?method=sayHello"
      @body = {"apikey" => @key}
    end

    should "produce a good exporter" do
      @exporter = @gibbon.get_exporter
      assert_equal(@exporter.api_key, @gibbon.api_key)
    end
  end

  context "export API" do
    setup do
      @key = "TESTKEY-us1"
      @gibbon = GibbonExport.new(@key)
      @url = "http://us1.api.mailchimp.com/export/1.0/"
      @body = {:apikey => @key}
      @returns = Struct.new(:body).new("")
    end

    should "handle api key with dc" do
      @api_key = "TESTKEY-us2"
      @gibbon = GibbonExport.new(@api_key)

      params = {:body => {:apikey => @api_key}, :timeout => nil}
      url = @url.gsub('us1', 'us2') + "sayHello/"
      GibbonExport.expects(:post).with(url, params).returns(@returns)
      @gibbon.say_hello
    end

    should "not escape string parameters" do
      @param = "list id"

      params = {:body => @body.merge(:id => 'list id'), :timeout => nil}
      GibbonExport.expects(:post).with(@url + 'sayHello/', params).returns(@returns)
      @gibbon.say_hello(:id => @param)
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
