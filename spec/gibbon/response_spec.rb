require 'spec_helper'

describe Gibbon::Response do
  it "defaults body and headers to empty hashes" do
    response = Gibbon::Response.new
    expect(response.body).to eq({})
    expect(response.headers).to eq({})
  end

  it "exposes the body and headers it is given" do
    body = { "id" => "abc" }
    headers = { "content-type" => "application/json" }
    response = Gibbon::Response.new(body: body, headers: headers)
    expect(response.body).to eq(body)
    expect(response.headers).to eq(headers)
  end
end
