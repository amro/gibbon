module Gibbon
  module Helpers
    def get_data_center_from_api_key(api_key)
      # Return an empty string for invalid API keys so Gibbon hits the main endpoint
      data_center = ""

      if api_key && api_key["-"]
        # Add a period since the data_center is a subdomain and it keeps things dry
        data_center = "#{api_key.split('-').last}."
      end

      data_center
    end
  end
end