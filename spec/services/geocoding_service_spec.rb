require "rails_helper"
require "webmock/rspec"

RSpec.describe GeocodingService do
  let(:base_url) { "https://nominatim.openstreetmap.org/search" }
  let(:headers) do
    {
      'Accept' => '*/*',
      'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
      'User-Agent' => 'WeatherForecastApp/1.0 (https://github.com/your-repo; your-email@example.com)'
    }
  end

  describe ".lookup_zip" do
    it "returns a zip and country for a valid address" do
      # Stub the Nominatim API response for a valid address
      stub_request(:get, base_url)
        .with(
          query: {
            q: "1600 Amphitheatre Parkway, Mountain View, CA",
            format: "json",
            addressdetails: 1,
            limit: 1
          },
          headers: headers
        )
        .to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: [{
            lat: "37.4224764",
            lon: "-122.0842499",
            display_name: "Google Building 40, 1600, Amphitheatre Parkway, Mountain View, Santa Clara County, California, 94043, United States",
            address: {
              postcode: "94043",
              country_code: "us"
            }
          }].to_json
        )

      result = described_class.lookup_zip("1600 Amphitheatre Parkway, Mountain View, CA")
      expect(result).to include(:zip, :country)
      expect(result[:zip]).to eq("94043")
      expect(result[:country]).to eq("US")
      expect(result[:lat]).to eq("37.4224764")
      expect(result[:lon]).to eq("-122.0842499")
    end

    it "returns nil for a nonsense address" do
      # Stub the Nominatim API response for an invalid address
      stub_request(:get, base_url)
        .with(
          query: {
            q: "sdfkjhsdfkjhsdfkjhsdfkjhsdf",
            format: "json",
            addressdetails: 1,
            limit: 1
          },
          headers: headers
        )
        .to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: [].to_json
        )

      result = described_class.lookup_zip("sdfkjhsdfkjhsdfkjhsdfkjhsdf")
      expect(result).to be_nil
    end
  end
end
