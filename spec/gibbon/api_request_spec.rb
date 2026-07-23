require 'spec_helper'
require 'webmock/rspec'

describe Gibbon::APIRequest do
  let(:api_key) { "1234-us1" }

  before do
    @gibbon = Gibbon::Request.new(api_key: api_key)
    @api_root = "https://us1.api.mailchimp.com/3.0"
    @basic_auth_credentials = ['apikey', api_key]
  end

  shared_examples_for 'client error handling' do
    it "surfaces client request exceptions as a Gibbon::MailChimpError" do
      exception = error_class.new("the server responded with status 503")
      stub_request(:get, "#{@api_root}/lists").with(basic_auth: @basic_auth_credentials).to_raise(exception)
      expect { @gibbon.lists.retrieve }.to raise_error(Gibbon::MailChimpError)
    end

    it "surfaces an unparseable client request exception as a Gibbon::MailChimpError" do
      exception = error_class.new(
        "the server responded with status 503")
      stub_request(:get, "#{@api_root}/lists").with(basic_auth: @basic_auth_credentials).to_raise(exception)
      expect { @gibbon.lists.retrieve }.to raise_error(Gibbon::MailChimpError)
    end

    it "surfaces an unparseable response body as a Gibbon::MailChimpError" do
      response_values = {:status => 503, :headers => {}, :body => '[foo]'}
      exception = error_class.new("the server responded with status 503", response_values)

      stub_request(:get, "#{@api_root}/lists").with(basic_auth: @basic_auth_credentials).to_raise(exception)
      expect { @gibbon.lists.retrieve }.to raise_error(Gibbon::MailChimpError)
    end

    context "handle_error" do
      it "includes status and raw body even when json can't be parsed" do
        response_values = {:status => 503, :headers => {}, :body => 'A non JSON response'}
        exception = error_class.new("the server responded with status 503", response_values)
        api_request = Gibbon::APIRequest.new(builder: Gibbon::Request)
        begin
          api_request.send :handle_error, exception
        rescue => boom
          expect(boom.status_code).to eq 503
          expect(boom.raw_body).to eq "A non JSON response"
        end
      end

      context "when symbolize_keys is true" do
        it "sets title and detail on the error params" do
          response_values = {:status => 422, :headers => {}, :body => '{"title": "foo", "detail": "bar"}'}
          exception = error_class.new("the server responded with status 422", response_values)
          api_request = Gibbon::APIRequest.new(builder: Gibbon::Request.new(symbolize_keys: true))
          begin
            api_request.send :handle_error, exception
          rescue => boom
            expect(boom.title).to eq "foo"
            expect(boom.detail).to eq "bar"
          end
        end
      end
    end
  end

  context 'Faraday::ClientError' do
    let(:error_class) { Faraday::ClientError }

    include_examples 'client error handling'
  end

  context 'Faraday::ServerError' do
    let(:error_class) { Faraday::ServerError }

    include_examples 'client error handling'
  end

  context "error responses over HTTP" do
    it "raises a MailChimpError with details parsed from a 4xx JSON response" do
      error_body = '{"title": "Invalid Resource", "detail": "The resource submitted could not be validated.", "status": 422}'
      stub_request(:get, "#{@api_root}/lists")
        .with(basic_auth: @basic_auth_credentials)
        .to_return(status: 422, body: error_body, headers: { 'Content-Type' => 'application/json' })

      begin
        @gibbon.lists.retrieve
        fail "expected a Gibbon::MailChimpError"
      rescue Gibbon::MailChimpError => e
        expect(e.status_code).to eq 422
        expect(e.title).to eq "Invalid Resource"
        expect(e.detail).to eq "The resource submitted could not be validated."
        expect(e.raw_body).to eq error_body
        expect(e.body).to eq MultiJson.load(error_body)
      end
    end

    it "raises a MailChimpError on a 5xx response" do
      stub_request(:get, "#{@api_root}/lists")
        .with(basic_auth: @basic_auth_credentials)
        .to_return(status: 503, body: '{"title": "Service Unavailable"}')

      begin
        @gibbon.lists.retrieve
        fail "expected a Gibbon::MailChimpError"
      rescue Gibbon::MailChimpError => e
        expect(e.status_code).to eq 503
        expect(e.title).to eq "Service Unavailable"
      end
    end
  end

  context "response parsing" do
    it "returns a Gibbon::Response with the parsed body and headers" do
      stub_request(:get, "#{@api_root}/lists")
        .with(basic_auth: @basic_auth_credentials)
        .to_return(status: 200, body: '{"lists": [{"id": "abc123"}]}', headers: { 'Content-Type' => 'application/json' })

      response = @gibbon.lists.retrieve
      expect(response).to be_a Gibbon::Response
      expect(response.body).to eq({ "lists" => [{ "id" => "abc123" }] })
      expect(response.headers["content-type"]).to eq "application/json"
    end

    it "symbolizes response keys when symbolize_keys is true" do
      stub_request(:get, "#{@api_root}/lists")
        .with(basic_auth: @basic_auth_credentials)
        .to_return(status: 200, body: '{"lists": [{"id": "abc123"}]}')

      response = Gibbon::Request.new(api_key: api_key, symbolize_keys: true).lists.retrieve
      expect(response.body).to eq({ lists: [{ id: "abc123" }] })
    end

    it "returns nil for an empty response body" do
      stub_request(:get, "#{@api_root}/lists")
        .with(basic_auth: @basic_auth_credentials)
        .to_return(status: 200, body: "")

      expect(@gibbon.lists.retrieve).to be_nil
    end

    it "raises a MailChimpError with details intact for an unparseable success response" do
      stub_request(:get, "#{@api_root}/lists")
        .with(basic_auth: @basic_auth_credentials)
        .to_return(status: 200, body: "not json")

      begin
        @gibbon.lists.retrieve
        fail "expected a Gibbon::MailChimpError"
      rescue Gibbon::MailChimpError => e
        expect(e.title).to eq "UNPARSEABLE_RESPONSE"
        expect(e.status_code).to eq 500
      end
    end
  end

  context "configure_request" do
    it "sets params, headers, body, and timeouts on the request" do
      gibbon = Gibbon::Request.new(api_key: api_key, timeout: 45, open_timeout: 15)
      api_request = Gibbon::APIRequest.new(builder: gibbon.lists)
      request = Struct.new(:params, :headers, :body, :options).new({}, {}, nil, Faraday::RequestOptions.new)

      api_request.send(:configure_request, request: request, params: { "count" => "10" }, headers: { "X-Custom" => "value" }, body: '{"a":1}')

      expect(request.params).to eq({ "count" => "10" })
      expect(request.headers).to eq({ "Content-Type" => "application/json", "X-Custom" => "value" })
      expect(request.body).to eq '{"a":1}'
      expect(request.options.timeout).to eq 45
      expect(request.options.open_timeout).to eq 15
    end
  end

  context "rest_client configuration" do
    it "includes the logger middleware when debug is enabled" do
      gibbon = Gibbon::Request.new(api_key: api_key, debug: true)
      client = Gibbon::APIRequest.new(builder: gibbon.lists).send(:rest_client)
      expect(client.builder.handlers).to include(Faraday::Response::Logger)
    end

    it "omits the logger middleware by default" do
      client = Gibbon::APIRequest.new(builder: @gibbon.lists).send(:rest_client)
      expect(client.builder.handlers).not_to include(Faraday::Response::Logger)
    end

    it "configures the proxy" do
      gibbon = Gibbon::Request.new(api_key: api_key, proxy: "http://proxy.example.com:8080")
      client = Gibbon::APIRequest.new(builder: gibbon.lists).send(:rest_client)
      expect(client.proxy.host).to eq "proxy.example.com"
      expect(client.proxy.port).to eq 8080
    end
  end

  context "rest_client ssl configuration" do
    it "requires TLS 1.2 as a minimum without capping the TLS version" do
      api_request = Gibbon::APIRequest.new(builder: @gibbon.lists)
      client = api_request.send(:rest_client)
      expect(client.ssl.min_version).to eq :TLS1_2
      expect(client.ssl.max_version).to be_nil
    end
  end
end
