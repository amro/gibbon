module Gibbon
  class MailChimpError < StandardError
    attr_accessor :title, :detail, :body, :raw_body, :status_code
  end
end
