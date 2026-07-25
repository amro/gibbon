module Gibbon
  # Raised before a request is sent, when Gibbon cannot determine where to send
  # it: the API key is missing, or it carries no data center suffix and no
  # `api_endpoint` was configured.
  class GibbonError < StandardError; end
end