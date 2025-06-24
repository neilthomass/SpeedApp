
A Flutter application that tracks and visualizes speed data in real-time with a modern, clean interface. Features multiple lane visualization and speed suggestions based on lane selection.

## Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK
- iOS/Android development environment

### Required Packages

- `fl_chart`: For speed visualization charts
- `flutter_tts`: For text-to-speech functionality
- `location`: For GPS speed tracking
- `intl`: For data formatting

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/FlowMoTechnologies/flowmo_app.git
   cd flowmo_app
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
  ├── models/
  │   └── speed_data.dart       # Data models for speed and lane information
  ├── services/
  │   ├── speed_service.dart    # Speed tracking and calculations
  │   └── tts_service.dart      # Text-to-speech functionality
  ├── widgets/
  │   ├── speed_display.dart    # Speed indicator widget
  │   ├── speed_chart.dart      # Chart visualization
  │   └── lane_display.dart     # Lane-based visualization
  └── main.dart                 # Main application entry point
```


## Author

Built by Neil Thomas


## Resources

For help getting started with Flutter development:

- [Flutter Documentation](https://flutter.dev/docs)
- [Flutter Cookbook](https://flutter.dev/docs/cookbook)
- [Flutter API Reference](https://api.flutter.dev)

