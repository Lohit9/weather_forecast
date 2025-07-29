require "rails_helper"
require "webmock/rspec"

RSpec.describe WeatherService do
  let(:api_key) { ENV["OPENWEATHER_API_KEY"] }
  let(:base_url) { "https://api.openweathermap.org/data/2.5/weather" }
  include ActiveSupport::Testing::TimeHelpers

  describe ".get_forecast" do
    let(:weather_data) do
      {
        main: { temp: 22.5, temp_min: 20.0, temp_max: 25.0 },
        weather: [{ description: "clear sky" }]
      }
    end

    before do
      Rails.cache.clear
      stub_request(:get, base_url)
        .with(query: { zip: "94043,US", appid: api_key, units: "metric" })
        .to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: weather_data.to_json
        )
    end

    after do
      travel_back
    end

    it "returns live data on first request" do
      result = WeatherService.get_forecast(zip: "94043", country: "US")
      expect(result[:from_cache]).to be false
      expect(result[:temp]).to eq(22.5)
    end

    it "returns cached data on subsequent requests" do
      # First request - should hit the API
      first_result = WeatherService.get_forecast(zip: "94043", country: "US")
      expect(first_result[:from_cache]).to be false

      # Second request - should use cache
      second_result = WeatherService.get_forecast(zip: "94043", country: "US")
      expect(second_result[:from_cache]).to be true
      expect(second_result[:temp]).to eq(first_result[:temp])
    end

    it "expires cache after 30 minutes" do
      travel_to(Time.current) do
        # Initial request
        WeatherService.get_forecast(zip: "94043", country: "US")

        # Request after 29 minutes - should still be cached
        travel 29.minutes
        result_before = WeatherService.get_forecast(zip: "94043", country: "US")
        expect(result_before[:from_cache]).to be true

        # Request after 31 minutes - should be live
        travel 2.minutes
        result_after = WeatherService.get_forecast(zip: "94043", country: "US")
        expect(result_after[:from_cache]).to be false
      end
    end
  end
end
