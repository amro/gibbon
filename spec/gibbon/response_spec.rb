require 'spec_helper'
require 'cgi'

describe Gibbon::Response do
  describe "#[]" do
    it "forwards the [] method to the body" do
      response = Gibbon::Response.new(body: { "foo" => "bar" })
      expect(response["foo"]).to eq "bar"
    end
  end
end
