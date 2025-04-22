import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlaying = false;
  
  Future<void> initialize() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    if (await _flutterTts.isLanguageAvailable("en-US")) {
      print("Language is available");
    }
    
    _flutterTts.setErrorHandler((msg) {
      print("TTS ERROR: $msg");
    });
  }
  
  Future<void> speakWarning(String message) async {
    if (!_isPlaying) {
      _isPlaying = true;
      try {
        await _flutterTts.speak(message);
        await Future.delayed(Duration(seconds: 10));
      } catch (e) {
        print("TTS ERROR: $e");
      } finally {
        _isPlaying = false;
      }
    }
  }
  
  Future<void> stop() async {
    await _flutterTts.stop();
  }
  
  void dispose() {
    _flutterTts.stop();
  }
} 