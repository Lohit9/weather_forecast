class GeocodingService
  include HTTParty
  base_uri "https://nominatim.openstreetmap.org"
  
  # Add headers to comply with Nominatim usage policy
  headers 'User-Agent' => 'WeatherForecastApp/1.0 (https://github.com/your-repo; your-email@example.com)'

  def self.lookup_zip(address)
    Rails.logger.info("[GeocodingService] Looking up address: #{address}")
    
    response = get("/search", query: {
      q: address,
      format: "json",
      addressdetails: 1,
      limit: 1
    })

    Rails.logger.info("[GeocodingService] Response success: #{response.success?}")
    Rails.logger.info("[GeocodingService] Response parsed: #{response.parsed_response.inspect}")

    return nil unless response.success? && response.parsed_response.any?

    result = response[0]
    address_data = result["address"]
    Rails.logger.info("[GeocodingService] Address data: #{address_data.inspect}")
    
    # Try multiple postal code field names for international support
    zip = address_data["postcode"] || 
          address_data["postal_code"] || 
          address_data["postalcode"] ||
          extract_postal_code_from_display_name(result["display_name"])
    
    country = address_data["country_code"]&.upcase
    # Keep coordinates as strings to match test expectations
    lat = result["lat"]
    lon = result["lon"]

    Rails.logger.info("[GeocodingService] Extracted zip: #{zip}, country: #{country}, lat: #{lat}, lon: #{lon}")

    if zip && country
      { zip: zip, country: country, lat: lat, lon: lon }
    elsif lat && lon
      # Fallback to coordinates if no postal code
      { lat: lat, lon: lon, country: country }
    else
      nil
    end
  end

  private

  def self.extract_postal_code_from_display_name(display_name)
    # Try to extract postal code from display name if not found in address fields
    # This is a fallback for cases where postal code is in the display name
    return nil unless display_name
    
    # Look for common postal code patterns
    postal_patterns = [
      /\b[A-Z]\d[A-Z]\s?\d[A-Z]\d\b/,  # Canadian format: A1A 1A1
      /\b\d{5}\b/,                       # US format: 12345
      /\b[A-Z]{1,2}\d[A-Z\d]?\s?\d[A-Z]{2}\b/  # UK format: A1 1AA
    ]
    
    postal_patterns.each do |pattern|
      match = display_name.match(pattern)
      return match[0] if match
    end
    
    nil
  end
end
  