import 'package:flutter_tts/flutter_tts.dart';

class TTSUtils {
  static final FlutterTts _flutterTts = FlutterTts();
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
    _isInitialized = true;
  }

  static Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }
    await _flutterTts.speak(text);
  }

  static Future<void> stop() async {
    await _flutterTts.stop();
  }

  static Future<void> dispose() async {
    await _flutterTts.stop();
    _isInitialized = false;
  }
} 