# map_street

A Flutter map application that displays the user's current location using OpenStreetMap and Flutter Map.

## Features

* Display interactive maps using Flutter Map
* Get the user's current location
* Location permissions handling
* OpenStreetMap integration
* HTTP requests support for map-related services

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter

  flutter_map: ^7.0.2
  latlong2: ^0.9.1
  geolocator: ^13.0.1
  http: ^1.2.2
```

## Android Permissions

Add the following permissions to:

`android/app/src/main/AndroidManifest.xml`

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

## iOS Permissions

Add the following to:

`ios/Runner/Info.plist`

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs your location to show it on the map.</string>
```

## Installation

1. Install dependencies:

```bash
flutter pub get
```

2. Run the application:

```bash
flutter run
```

## Packages Used

* flutter_map
* latlong2
* geolocator
* http

## License

This project is for learning and development purposes.
