require 'spec_helper'

describe Gibbon::Helpers do
  let(:helper) { Class.new { include Gibbon::Helpers }.new }

  describe "#get_data_center_from_api_key" do
    it "returns an empty string for a nil api key" do
      expect(helper.get_data_center_from_api_key(nil)).to eq("")
    end

    it "returns an empty string for an api key without a data center" do
      expect(helper.get_data_center_from_api_key("1234")).to eq("")
    end

    it "returns the data center with a trailing dot" do
      expect(helper.get_data_center_from_api_key("1234-us1")).to eq("us1.")
    end

    it "uses the last segment of a key containing multiple hyphens" do
      expect(helper.get_data_center_from_api_key("12-34-us10")).to eq("us10.")
    end

    it "strips non-alphanumeric characters to prevent domain injection" do
      expect(helper.get_data_center_from_api_key("1234-attacker.net/path?")).to eq("attackernetpath.")
    end
  end
end
