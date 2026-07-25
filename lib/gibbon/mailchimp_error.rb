module Gibbon
  # Raised when a request fails.
  #
  # A `4xx` or `5xx` from MailChimp populates every attribute from the error
  # document it returns. A transport level failure, such as a timeout, has no
  # response to read, so only the message is set. Gibbon also raises this when a
  # successful response body is not valid JSON, with a {#title} of
  # `"UNPARSEABLE_RESPONSE"` and a {#status_code} of `500`.
  class MailChimpError < StandardError
    # @return [String, nil] MailChimp's short name for the error, e.g. `"Resource Not Found"`
    attr_reader :title
    # @return [String, nil] MailChimp's human readable explanation of the error
    attr_reader :detail
    # @return [Hash, nil] the parsed error document
    attr_reader :body
    # @return [String, nil] the unparsed error response body
    attr_reader :raw_body
    # @return [Integer, nil] the HTTP status code
    attr_reader :status_code

    # @param message [String] the error message
    # @param params [Hash] any of `:title`, `:detail`, `:body`, `:raw_body`, `:status_code`
    def initialize(message = "", params = {})
      @title       = params[:title]
      @detail      = params[:detail]
      @body        = params[:body]
      @raw_body    = params[:raw_body]
      @status_code = params[:status_code]

      super(message)
    end

    # @return [String] the message followed by every populated attribute
    def to_s
      super + " " + instance_variables_to_s
    end

    private

    def instance_variables_to_s
      [:title, :detail, :body, :raw_body, :status_code].map do |attr|
        attr_value = send(attr)

        "@#{attr}=#{attr_value.inspect}"
      end.join(", ")
    end
  end
end
