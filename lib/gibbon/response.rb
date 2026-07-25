module Gibbon
  # A parsed response from MailChimp, returned by every CRUD verb on {Request}.
  #
  # @example
  #   response = gibbon.lists.retrieve
  #   response.body["lists"]
  #   response.headers["content-type"]
  class Response
    # @return [Hash, Array] the parsed JSON response body. Keys are symbols when
    #   the request was built with `symbolize_keys: true`, strings otherwise.
    attr_accessor :body

    # @return [Hash] the response headers, keyed by lower case string.
    attr_accessor :headers

    # @param body [Hash, Array] the parsed response body
    # @param headers [Hash] the response headers
    def initialize(body: {}, headers: {})
      @body = body
      @headers = headers
    end 
  end
end
