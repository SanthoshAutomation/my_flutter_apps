import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  Future<void> init() async {
    if (_isInitialized) return;

    await _tts.setLanguage('de-DE');
    await _tts.setSpeechRate(0.65); // Slightly slower for learning
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setStartHandler(() => _isSpeaking = true);
    _tts.setCompletionHandler(() => _isSpeaking = false);
    _tts.setCancelHandler(() => _isSpeaking = false);
    _tts.setErrorHandler((_) => _isSpeaking = false);

    _isInitialized = true;
  }

  Future<void> speak(String text, {bool isGerman = true}) async {
    await stop();
    if (isGerman) {
      await _tts.setLanguage('de-DE');
      await _tts.setSpeechRate(0.6);
    } else {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.75);
    }
    _isSpeaking = true;
    await _tts.speak(text);
  }

  Future<void> speakSlow(String text) async {
    await stop();
    await _tts.setLanguage('de-DE');
    await _tts.setSpeechRate(0.4); // Very slow for difficult words
    _isSpeaking = true;
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
  }

  Future<void> dispose() async {
    await stop();
  }
}
