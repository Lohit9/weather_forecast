# README

### HL architecture

```
User inputs address
     ↓
Nominatim → get ZIP + lat/lon
     ↓
Check Redis cache for forecast by ZIP
     ↓
If cached → return + flag “cached: true”
Else → call OpenWeatherMap → cache result
     ↓
Return forecast to user
```


This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions
