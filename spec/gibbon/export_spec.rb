require 'spec_helper'
require 'webmock/rspec'

describe Gibbon::Export do
  before do
    Gibbon::Export.send(:public, *Gibbon::Export.protected_instance_methods)
    @export = Gibbon::Export.new
  end

  it "doesn't allow empty api key" do
    expect {@export.list(id: "123456")}.to raise_error(Gibbon::GibbonError)
  end

  it "doesn't allow api key without data center" do
    @api_key = "123"
    @export.api_key = @api_key
    expect {@export.list(id: "123456")}.to raise_error(Gibbon::GibbonError)
  end

  it "sets an API key from the 'MAILCHIMP_API_KEY' ENV variable" do
    ENV['MAILCHIMP_API_KEY'] = 'TESTKEY-us1'
    @export = Gibbon::Export.new
    expect(@export.api_key).to eq('TESTKEY-us1')
    ENV.delete('MAILCHIMP_API_KEY')
  end

  it "sets correct endpoint from api key" do
    @api_key = "TESTKEY-us1"
    @export.api_key = @api_key
    expect(@export.export_api_url).to eq("https://us1.api.mailchimp.com/export/1.0/")
  end

  it "sets correct timeout" do
    @api_key = "TESTKEY-us1"
    @export.api_key = @api_key
    @export.timeout = 9
    expect(@export.timeout).to eq(9)
  end
end
