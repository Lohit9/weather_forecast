class WeatherService
  include HTTParty
  base_uri "https://api.openweathermap.org/data/2.5"

  def self.get_forecast(zip: nil, country: nil, lat: nil, lon: nil)
    # Determine cache key and API parameters
    if zip && country
      cache_key = "#{zip}-#{country}".downcase
      api_params = { zip: "#{zip},#{country}" }
      Rails.logger.info("[WeatherService] Using postal code: #{zip}, #{country}")
    elsif lat && lon
      # Convert to floats and round for cache key
      lat_float = lat.to_f
      lon_float = lon.to_f
      cache_key = "#{lat_float.round(4)}-#{lon_float.round(4)}".downcase
      api_params = { lat: lat_float, lon: lon_float }
      Rails.logger.info("[WeatherService] Using coordinates: #{lat_float}, #{lon_float}")
    else
      return { error: "Invalid location parameters" }
    end

    Rails.logger.info("[WeatherService] Cache key: #{cache_key}")

    cached = true
    result = Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
      cached = false  # This line only executes if cache miss
      Rails.logger.info("[WeatherService] Making API call to OpenWeatherMap")
      
      response = get("/weather", query: api_params.merge({
        appid: ENV["OPENWEATHER_API_KEY"],
        units: "metric"
      }))

      Rails.logger.info("[WeatherService] API response success: #{response.success?}")
      Rails.logger.info("[WeatherService] API response code: #{response.code}")
      Rails.logger.info("[WeatherService] API response body: #{response.body}")

      if response.success?
        {
          temp: response["main"]["temp"],
          temp_min: response["main"]["temp_min"],
          temp_max: response["main"]["temp_max"],
          weather: response["weather"].first["description"]
        }
      else
        Rails.logger.error("[WeatherService] API call failed: #{response.code} - #{response.body}")
        { error: "Weather data not available" }
      end
    end

    result = result.with_indifferent_access
    result[:from_cache] = cached
    result
  end
end
  