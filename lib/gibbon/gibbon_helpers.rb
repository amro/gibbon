module Gibbon
  # Shared helpers mixed into {APIRequest}.
  module Helpers
    # Extracts the data center prefix from an API key, e.g. `"us1."` from
    # `"TESTKEY-us1"`.
    #
    # @param api_key [String, nil] the API key
    # @return [String] the prefix including its trailing dot, or an empty string
    #   when the key carries no data center suffix
    def get_data_center_from_api_key(api_key)
      # Return an empty string for invalid API keys so Gibbon hits the main endpoint
      data_center = ""

      if api_key && api_key["-"]
        # Remove all non-alphanumeric characters in case someone attempts to inject
        # a different domain into the API key (e.g. when consuming user form-provided keys)
        # This approach avoids assuming a 3 letter prefix (e.g. if MC were to create
        # a us10 DC, this would continue to work), and will continue to hit MC's server
        # rather than a would-be attacker's servers.
        data_center = "#{api_key.split('-').last.gsub(/[^0-9a-z ]/i, '')}."
      end

      data_center
    end
  end
end