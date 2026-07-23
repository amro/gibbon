require 'spec_helper'
require 'webmock/rspec'

describe Gibbon::Request do
  let(:api_key) { "1234-us1" }
  let(:api_root) { "https://us1.api.mailchimp.com/3.0" }
  let(:basic_auth_credentials) { ['apikey', api_key] }

  before do
    @gibbon = Gibbon::Request.new(api_key: api_key)
  end

  describe "path building" do
    it "builds a path from chained calls" do
      @gibbon.lists("list123").members
      expect(@gibbon.path).to eq("lists/list123/members")
    end

    it "replaces underscores with hyphens" do
      @gibbon.lists("list123").interest_categories
      expect(@gibbon.path).to eq("lists/list123/interest-categories")
    end

    it "downcases path parts" do
      @gibbon.LISTS
      expect(@gibbon.path).to eq("lists")
    end

    it "responds to any method" do
      expect(@gibbon.respond_to?(:anything_at_all)).to be true
    end

    it "appends 'send' to the path when called without arguments" do
      @gibbon.campaigns("abc").actions.send
      expect(@gibbon.path).to eq("campaigns/abc/actions/send")
    end

    it "dispatches send with arguments as a regular method call" do
      expect(@gibbon.send(:api_key)).to eq(api_key)
    end

    it "resets the path after a request" do
      stub_request(:get, "#{api_root}/lists").with(basic_auth: basic_auth_credentials).to_return(status: 200)
      @gibbon.lists.retrieve
      expect(@gibbon.path).to eq("")
    end

    it "resets the path when a request raises" do
      stub_request(:get, "#{api_root}/lists").with(basic_auth: basic_auth_credentials).to_return(status: 500, body: "{}")
      expect { @gibbon.lists.retrieve }.to raise_error(Gibbon::MailChimpError)
      expect(@gibbon.path).to eq("")
    end
  end

  describe "HTTP verb mapping" do
    let(:body) { { name: "Foo" } }

    it "maps create to POST" do
      stub = stub_request(:post, "#{api_root}/lists")
        .with(body: MultiJson.dump(body), basic_auth: basic_auth_credentials, headers: { 'Content-Type' => 'application/json' })
        .to_return(status: 200)
      @gibbon.lists.create(body: body)
      expect(stub).to have_been_requested
    end

    it "maps update to PATCH" do
      stub = stub_request(:patch, "#{api_root}/lists/list123")
        .with(body: MultiJson.dump(body), basic_auth: basic_auth_credentials, headers: { 'Content-Type' => 'application/json' })
        .to_return(status: 200)
      @gibbon.lists("list123").update(body: body)
      expect(stub).to have_been_requested
    end

    it "maps upsert to PUT" do
      stub = stub_request(:put, "#{api_root}/lists/list123")
        .with(body: MultiJson.dump(body), basic_auth: basic_auth_credentials, headers: { 'Content-Type' => 'application/json' })
        .to_return(status: 200)
      @gibbon.lists("list123").upsert(body: body)
      expect(stub).to have_been_requested
    end

    it "maps retrieve to GET" do
      stub = stub_request(:get, "#{api_root}/lists").with(basic_auth: basic_auth_credentials).to_return(status: 200)
      @gibbon.lists.retrieve
      expect(stub).to have_been_requested
    end

    it "maps get to GET" do
      stub = stub_request(:get, "#{api_root}/lists").with(basic_auth: basic_auth_credentials).to_return(status: 200)
      @gibbon.lists.get
      expect(stub).to have_been_requested
    end

    it "maps delete to DELETE" do
      stub = stub_request(:delete, "#{api_root}/lists/list123").with(basic_auth: basic_auth_credentials).to_return(status: 204)
      @gibbon.lists("list123").delete
      expect(stub).to have_been_requested
    end
  end

  describe "request options" do
    it "passes query params" do
      stub = stub_request(:get, "#{api_root}/lists")
        .with(query: { "count" => "10", "offset" => "20" }, basic_auth: basic_auth_credentials)
        .to_return(status: 200)
      @gibbon.lists.retrieve(params: { "count" => "10", "offset" => "20" })
      expect(stub).to have_been_requested
    end

    it "passes custom headers" do
      stub = stub_request(:get, "#{api_root}/lists")
        .with(headers: { 'X-Custom' => 'custom-value' }, basic_auth: basic_auth_credentials)
        .to_return(status: 200)
      @gibbon.lists.retrieve(headers: { 'X-Custom' => 'custom-value' })
      expect(stub).to have_been_requested
    end
  end

  describe "api key handling" do
    it "strips whitespace from the api key" do
      gibbon = Gibbon::Request.new(api_key: "  #{api_key}  ")
      expect(gibbon.api_key).to eq(api_key)
    end
  end

  describe "class-level requests" do
    before do
      Gibbon::Request.api_key = api_key
    end

    after do
      Gibbon::Request.api_key = nil
    end

    it "makes requests directly on the class" do
      stub = stub_request(:get, "#{api_root}/lists").with(basic_auth: basic_auth_credentials).to_return(status: 200)
      Gibbon::Request.lists.retrieve
      expect(stub).to have_been_requested
    end
  end
end
