class WeatherController < ApplicationController
  def forecast
    address = params[:address]
    return render json: { error: "Address missing" }, status: 400 unless address.present?

    Rails.logger.info("[WeatherController] Looking up address: #{address}")
    location = GeocodingService.lookup_zip(address)
    Rails.logger.info("[WeatherController] GeocodingService result: #{location.inspect}")

    if location.nil?
      Rails.logger.error("[WeatherController] Failed to resolve location. Location: #{location.inspect}")
      return render json: { error: "Could not resolve ZIP code and country" }, status: 422
    end

    # Try postal code first, then fall back to coordinates
    if location[:zip] && location[:country]
      forecast_data = WeatherService.get_forecast(zip: location[:zip], country: location[:country])
    elsif location[:lat] && location[:lon]
      forecast_data = WeatherService.get_forecast(lat: location[:lat], lon: location[:lon])
    else
      return render json: { error: "Could not resolve location coordinates" }, status: 422
    end

    render json: forecast_data
  end
end
  