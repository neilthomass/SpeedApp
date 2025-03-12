import 'package:audioplayers/audioplayers.dart';

class AudioUtils {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  
  static Future<void> playChime() async {
    try {
      await _audioPlayer.play(AssetSource('audio/chime.mp3'));
    } catch (e) {
      print('Error playing chime: $e');
    }
  }

  static void dispose() {
    _audioPlayer.dispose();
  }
} 