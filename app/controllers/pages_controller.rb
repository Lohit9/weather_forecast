class PagesController < ApplicationController
  def home
    render template: 'pages/home'
  end

  def search
    address = params[:address]

    if address.blank?
      @error = "Please enter an address."
      return render :home
    end

    location = GeocodingService.lookup_zip(address)

    if location.nil?
      @error = "Could not resolve location from that address."
    else
      # For Canadian addresses or when no postal code is available, use coordinates
      if location[:country]&.upcase == 'CA' || location[:zip].nil?
        @forecast = WeatherService.get_forecast(lat: location[:lat], lon: location[:lon])
      else
        @forecast = WeatherService.get_forecast(zip: location[:zip], country: location[:country])
      end
    end

    render :home
  end
end
