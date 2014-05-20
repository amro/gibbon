module Gibbon
  class MailChimpError < StandardError
    attr_accessor :code, :name
  end
end
