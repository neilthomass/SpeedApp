# Speed Tracker

A Flutter application that tracks and visualizes speed data in real-time with a modern, clean interface.

## Features

- Real-time speed tracking and visualization
- Dynamic speed chart with smooth animations
- Location logging with timestamps
- Unit conversion between MPH and KPH
- Dark/Light theme support
- Current location display
- GPS data integration
- Smooth data interpolation

## Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK
- iOS/Android development environment
- Required packages:
  - fl_chart
  - intl
  - csv
  - geolocator

### Installation

1. Clone the repository
2. Install dependencies:
    [bash]
    flutter pub get
3. Place your GPS data file in:
    assets/gps_data.csv
4. Run the app:
    [bash]
    flutter run

### CSV File Format
The GPS data file should be in CSV format with the following structure:
    latitude,longitude
    XX.XXXXX,YY.YYYYY

## Features in Detail
### Speed Display
- Large, easy-to-read speed indicator
- Toggle between MPH and KPH
- Smooth value transitions
### Speed Chart
- Real-time updating graph
- Smooth curve interpolation
- Dynamic y-axis scaling
- Transparent gradient fill
### Location Log
- Real-time GPS coordinate tracking
- Timestamp for each location update
- Scrollable history view
### Settings
- Theme toggle (Dark/Light mode)
- Current location display
- Persistent settings storage
## Technical Details
- Built with Flutter
- Uses custom interpolation for smooth animations
- Implements GPS data parsing
- Features real-time data processing
- Responsive design for various screen sizes
## Dependencies
dependencies:
  flutter:
    sdk: flutter
  fl_chart: ^0.65.0
  intl: ^0.18.1
  csv: ^5.1.1
  geolocator: ^10.1.0


## Project Structure
lib/
  ├── main.dart          # Main application entry point
  └── settings_page.dart # Settings page implementation
assets/
  └── gps_data.csv      # GPS data file


## Implementation Details
- Uses Haversine formula for distance calculations
- Implements smooth data interpolation
- Real-time speed calculations
- Dynamic chart updates
- Theme-aware UI components
- Location services integration

## Author
Built by Neil Thomas

## License
This project is proprietary and all rights are reserved.

## Resources
For help getting started with Flutter development:

- Flutter Documentation
- Flutter Cookbook
- Flutter API Reference



