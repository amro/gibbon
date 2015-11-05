require 'spec_helper'
require 'webmock/rspec'

describe Gibbon::APIRequest do
  let(:api_key) { "1234-us1" }

  before do
    @gibbon = Gibbon::Request.new(api_key: api_key)
    @api_root = "https://apikey:#{api_key}@us1.api.mailchimp.com/3.0"
  end

  it "surfaces client request exceptions as a Gibbon::MailChimpError" do
    exception = Faraday::Error::ClientError.new("the server responded with status 503")
    stub_request(:get, "#{@api_root}/lists").to_raise(exception)
    expect { @gibbon.lists.retrieve }.to raise_error(Gibbon::MailChimpError)
  end

  it "surfaces an unparseable client request exception as a Gibbon::MailChimpError" do
    exception = Faraday::Error::ClientError.new(
      "the server responded with status 503")
    stub_request(:get, "#{@api_root}/lists").to_raise(exception)
    expect { @gibbon.lists.retrieve }.to raise_error(Gibbon::MailChimpError)
  end

  it "surfaces an unparseable response body as a Gibbon::MailChimpError" do
    response_values = {:status => 503, :headers => {}, :body => '[foo]'}
    exception = Faraday::Error::ClientError.new("the server responded with status 503", response_values)

    stub_request(:get, "#{@api_root}/lists").to_raise(exception)
    expect { @gibbon.lists.retrieve }.to raise_error(Gibbon::MailChimpError)
  end
end
