module Gibbon
  class Response
    attr_accessor :body, :headers

    def initialize(body: {}, headers: {})
      @body = body
      @headers = headers
    end

    def [](key)
      body[key]
    end
  end
end
