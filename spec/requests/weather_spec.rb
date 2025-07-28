require "rails_helper"

RSpec.describe WeatherService do
  describe ".get_forecast" do
    it "returns weather data for a valid zip and country" do
      result = WeatherService.get_forecast(zip: "94043", country: "US")
      expect(result).to include(:temp, :temp_min, :temp_max, :weather, :from_cache)
    end

    it "returns error for invalid zip" do
      result = WeatherService.get_forecast(zip: "00000", country: "XX")
      expect(result).to include(:error)
    end
  end
end
