class WeatherService
  include HTTParty
  base_uri "https://api.openweathermap.org/data/2.5"

  def self.normalize_coordinates(lat, lon)
    return nil unless lat && lon
    [
      lat.to_f.round(4),
      lon.to_f.round(4)
    ]
  end

  def self.cache_key_for(zip: nil, country: nil, lat: nil, lon: nil)
    key = if zip && country && country.upcase != 'CA'
      "weather_forecast/zip/#{zip}-#{country}"
    elsif lat && lon
      lat_norm, lon_norm = normalize_coordinates(lat, lon)
      "weather_forecast/coords/#{lat_norm}/#{lon_norm}"
    end
    key&.downcase
  end

  def self.get_forecast(zip: nil, country: nil, lat: nil, lon: nil)
    # Build cache key and API params
    if zip && country && country.upcase != 'CA'
      api_params = { zip: "#{zip},#{country}" }
    elsif lat && lon
      lat_norm, lon_norm = normalize_coordinates(lat, lon)
      api_params = { lat: lat_norm, lon: lon_norm }
    else
      return { error: "Invalid location parameters" }
    end

    cache_key = cache_key_for(zip: zip, country: country, lat: lat, lon: lon)
    Rails.logger.info "[WeatherService] Using cache key: #{cache_key}"

    # Try to read from cache first
    cached_data = Rails.cache.read(cache_key)
    if cached_data
      # Check if cache is still valid (within 30 minutes)
      cache_age = Time.current.to_i - cached_data[:cached_at]
      if cache_age < 30.minutes
        Rails.logger.info "[WeatherService] Cache hit - returning cached data"
        return cached_data.merge(from_cache: true)
      else
        Rails.logger.info "[WeatherService] Cache expired after #{cache_age} seconds"
        Rails.cache.delete(cache_key)
      end
    end

    # Fetch fresh data from API
    Rails.logger.info "[WeatherService] Cache miss - fetching from API"
    response = get("/weather", query: api_params.merge({
      appid: ENV["OPENWEATHER_API_KEY"],
      units: "metric"
    }))

    if response.success?
      result = {
        temp: response["main"]["temp"],
        temp_min: response["main"]["temp_min"],
        temp_max: response["main"]["temp_max"],
        weather: response["weather"].first["description"],
        cached_at: Time.current.to_i,
        from_cache: false
      }

      # Cache the new data
      Rails.cache.write(cache_key, result, expires_in: 30.minutes)
      Rails.logger.info "[WeatherService] Cached new data"

      result
    else
      { error: "Weather data not available" }
    end
  end
end