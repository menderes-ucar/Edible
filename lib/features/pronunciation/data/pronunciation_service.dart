import 'package:flutter_tts/flutter_tts.dart';

enum SpeakResult { spoken, languageUnavailable, failed }

/// Reads text aloud with the phone's built-in text-to-speech voices (free,
/// works offline when the voice is installed). One shared engine: starting a
/// new phrase stops the previous one.
class PronunciationService {
  PronunciationService._();

  static final PronunciationService instance = PronunciationService._();

  final FlutterTts _tts = FlutterTts();
  bool _configured = false;

  Future<void> _configure() async {
    if (_configured) return;
    _configured = true;
    try {
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      // Slightly slower than normal so a learner can follow the phrase.
      await _tts.setSpeechRate(0.42);
      // Without this, iOS stays silent when the ringer switch is on mute.
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [IosTextToSpeechAudioCategoryOptions.mixWithOthers],
      );
    } catch (_) {
      // Defaults still work; only the pace / mute behaviour differ.
    }
  }

  Future<SpeakResult> speak(String text, String locale) async {
    final value = text.trim();
    if (value.isEmpty) return SpeakResult.failed;

    try {
      await _configure();

      // Android reports 1/true when the voice exists, iOS reports true/false.
      final available = await _tts.isLanguageAvailable(locale);
      if (!(available == true || available == 1)) {
        return SpeakResult.languageUnavailable;
      }

      await _tts.stop();
      await _tts.setLanguage(locale);
      final result = await _tts.speak(value);
      return (result == 0 || result == false)
          ? SpeakResult.failed
          : SpeakResult.spoken;
    } catch (_) {
      return SpeakResult.failed;
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
