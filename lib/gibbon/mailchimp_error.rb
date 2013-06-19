module Gibbon
  class MailChimpError < StandardError
    attr_accessor :code
  end
end