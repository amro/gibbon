require 'spec_helper'

describe Gibbon::MailChimpError do
  let(:message) { 'Foo' }
  let(:params) do
    {
      title: 'error_title',
      detail: 'error_detail',
      body: 'error_body',
      raw_body: 'error_raw_body',
      status_code: 'error_status_code'
    }
  end

  before do
    @gibbon = Gibbon::MailChimpError.new(message, params)
  end

  it "adds the error params to the error message" do
    expected_message = "Foo "                               \
                       "@title=\"error_title\", "           \
                       "@detail=\"error_detail\", "         \
                       "@body=\"error_body\", "             \
                       "@raw_body=\"error_raw_body\", "     \
                       "@status_code=\"error_status_code\""

    expect(@gibbon.message).to eq(expected_message)
  end

  it 'sets the title attribute' do
    expect(@gibbon.title).to eq(params[:title])
  end

  it 'sets the detail attribute' do
    expect(@gibbon.detail).to eq(params[:detail])
  end

  it 'sets the body attribute' do
    expect(@gibbon.body).to eq(params[:body])
  end

  it 'sets the raw_body attribute' do
    expect(@gibbon.raw_body).to eq(params[:raw_body])
  end

  it 'sets the status_code attribute' do
    expect(@gibbon.status_code).to eq(params[:status_code])
  end

  context "without params" do
    before do
      @gibbon = Gibbon::MailChimpError.new(message)
    end

    it "leaves the attributes nil" do
      expect(@gibbon.title).to be_nil
      expect(@gibbon.detail).to be_nil
      expect(@gibbon.body).to be_nil
      expect(@gibbon.raw_body).to be_nil
      expect(@gibbon.status_code).to be_nil
    end

    it "still includes the attributes in the message" do
      expect(@gibbon.message).to eq "Foo @title=nil, @detail=nil, @body=nil, @raw_body=nil, @status_code=nil"
    end
  end
end
