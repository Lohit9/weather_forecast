require "rails_helper"
require "webmock/rspec"

RSpec.describe WeatherService do
  let(:api_key) { ENV["OPENWEATHER_API_KEY"] }
  let(:base_url) { "https://api.openweathermap.org/data/2.5/weather" }
  include ActiveSupport::Testing::TimeHelpers

  after do
    travel_back # Clean up any time travel
  end

  describe ".get_forecast" do
    before do
      # Clear cache before each test
      Rails.cache.clear
    end

    it "returns weather data hash with temperature and description" do
      stub_request(:get, base_url)
        .with(
          query: {
            zip: "94043,US",
            appid: api_key,
            units: "metric"
          }
        ).to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: {
            main: { temp: 22.5, temp_min: 20.0, temp_max: 25.0 },
            weather: [{ description: "clear sky" }]
          }.to_json
        )

      result = WeatherService.get_forecast(zip: "94043", country: "US")
      expect(result).to include(:temp, :temp_min, :temp_max, :weather, :from_cache)
      expect(result[:temp]).to eq(22.5)
      expect(result[:weather]).to eq("clear sky")
      expect(result[:from_cache]).to be false
    end

    context "caching behavior" do
      it "returns from_cache: false on first request and true on subsequent requests" do
        stub_request(:get, base_url)
          .with(
            query: {
              zip: "94043,US",
              appid: api_key,
              units: "metric"
            }
          ).to_return(
            status: 200,
            headers: { 'Content-Type' => 'application/json' },
            body: {
              main: { temp: 22.5, temp_min: 20.0, temp_max: 25.0 },
              weather: [{ description: "clear sky" }]
            }.to_json
          )

        # First request should not be from cache
        first_result = WeatherService.get_forecast(zip: "94043", country: "US")
        expect(first_result[:from_cache]).to be false
        expect(first_result[:temp]).to eq(22.5)

        # Second request should be from cache and have the same data
        second_result = WeatherService.get_forecast(zip: "94043", country: "US")
        expect(second_result[:from_cache]).to be true
        expect(second_result[:temp]).to eq(first_result[:temp])
        expect(second_result[:weather]).to eq(first_result[:weather])
      end

      it "expires cache after 30 minutes" do
        stub_request(:get, base_url)
          .with(
            query: {
              zip: "94043,US",
              appid: api_key,
              units: "metric"
            }
          ).to_return(
            {
              status: 200,
              headers: { 'Content-Type' => 'application/json' },
              body: {
                main: { temp: 20.5, temp_min: 19.0, temp_max: 22.0 },
                weather: [{ description: "clear sky" }]
              }.to_json
            },
            {
              status: 200,
              headers: { 'Content-Type' => 'application/json' },
              body: {
                main: { temp: 25.5, temp_min: 24.0, temp_max: 27.0 },
                weather: [{ description: "partly cloudy" }]
              }.to_json
            }
          )

        # First request
        first_result = WeatherService.get_forecast(zip: "94043", country: "US")
        expect(first_result[:from_cache]).to be false
        expect(first_result[:temp]).to eq(20.5)

        # Second request within 30 minutes should be cached
        second_result = WeatherService.get_forecast(zip: "94043", country: "US")
        expect(second_result[:from_cache]).to be true
        expect(second_result[:temp]).to eq(20.5) # Same as first result

        # Travel 31 minutes into the future
        travel_to(31.minutes.from_now)
        
        # Request after cache expiry should not be from cache
        expired_result = WeatherService.get_forecast(zip: "94043", country: "US")
        expect(expired_result[:from_cache]).to be false
        expect(expired_result[:temp]).to eq(25.5) # New temperature from second response
      end

      it "caches by location (different locations don't share cache)" do
        # Stub SF weather
        stub_request(:get, base_url)
          .with(
            query: {
              zip: "94043,US",
              appid: api_key,
              units: "metric"
            }
          ).to_return(
            status: 200,
            headers: { 'Content-Type' => 'application/json' },
            body: {
              main: { temp: 22.5, temp_min: 20.0, temp_max: 25.0 },
              weather: [{ description: "clear sky" }]
            }.to_json
          )

        # Stub NY weather
        stub_request(:get, base_url)
          .with(
            query: {
              zip: "10001,US",
              appid: api_key,
              units: "metric"
            }
          ).to_return(
            status: 200,
            headers: { 'Content-Type' => 'application/json' },
            body: {
              main: { temp: 28.5, temp_min: 26.0, temp_max: 31.0 },
              weather: [{ description: "partly cloudy" }]
            }.to_json
          )

        # Request for first location
        sf_result = WeatherService.get_forecast(zip: "94043", country: "US")
        expect(sf_result[:from_cache]).to be false
        expect(sf_result[:temp]).to eq(22.5)

        # Request for different location should not use first location's cache
        ny_result = WeatherService.get_forecast(zip: "10001", country: "US")
        expect(ny_result[:from_cache]).to be false
        expect(ny_result[:temp]).to eq(28.5)
        expect(ny_result[:temp]).not_to eq(sf_result[:temp])

        # Subsequent request for first location should still use its cache
        sf_cached = WeatherService.get_forecast(zip: "94043", country: "US")
        expect(sf_cached[:from_cache]).to be true
        expect(sf_cached[:temp]).to eq(sf_result[:temp])
      end
    end
  end
end
