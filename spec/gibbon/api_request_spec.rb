require 'spec_helper'
require 'webmock/rspec'

describe Gibbon::APIRequest do
  let(:api_key) { "1234-us1" }

  before do
    @gibbon = Gibbon::Request.new(api_key: api_key)
    @api_root = "https://apikey:#{api_key}@us1.api.mailchimp.com/3.0"
  end

  it "surfaces request exceptions as Gibbon::MailChimpError exceptions" do
    stub_request(:get, "#{@api_root}/lists").to_raise(StandardError)
    expect { @gibbon.lists.retrieve }.to raise_error(Gibbon::MailChimpError)
  end
end
