# README
### 🌦️ Weather Forecast Application
This is a modern weather forecast application built with Ruby on Rails that provides real-time weather information with efficient caching.

### HL architecture

```
User inputs address
     ↓
Nominatim → get ZIP + lat/lon
     ↓
Check cache for forecast by ZIP
     ↓
If cached → return + flag “cached: true”
Else → call OpenWeatherMap → cache result
     ↓
Return forecast to user
```


https://github.com/user-attachments/assets/2a330653-692e-4d63-882e-a2a91bb99fa7


### Technical Stack
* Framework: Ruby on Rails 7.1
* APIs:
- OpenWeatherMap for weather data
- OpenStreetMap Nominatim for geocoding
* Caching: Rails built-in MemoryStore (50MB limit)
* Testing: RSpec with WebMock for API stubbing
* Frontend: Simple and responsive HTML/CSS interface

#### Key Components
* WeatherService : Handles weather data fetching and caching
* GeocodingService : Manages address lookup and coordinate normalization
* PagesController : Handles user interactions and data display

#### Data Flow
User enters an address
Address is geocoded to coordinates/ZIP code
Weather data is fetched from cache if available (within 30 minutes)
If not in cache, fresh data is fetched from OpenWeatherMap
Results are displayed with temperature, conditions, and cache status
The application prioritizes user experience with fast response times through caching while maintaining data freshness with a 30-minute cache expiration policy.
