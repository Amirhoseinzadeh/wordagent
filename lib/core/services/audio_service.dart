import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// سرویس پخش تلفظ.
///
/// تلفظ روی دستگاه و با موتور TTS سیستم تولید می‌شود؛ پس:
///  * به اینترنت نیاز ندارد،
///  * هیچ فایل صوتی در بسته‌ی اپ نیست (حجم نصب کم می‌ماند)،
///  * و در آینده می‌توان بدون تغییر در رابط کاربری، صدای ضبط‌شده‌ی
///    گوینده‌ی نیتیو را جایگزین کرد (پیاده‌سازی تازه از همین قرارداد).
abstract class AudioService {
  /// آماده‌سازی موتور تلفظ (تنبل انجام می‌شود).
  Future<void> warmUp();

  /// آیا تلفظ صوتی روی این دستگاه در دسترس است؟
  Future<bool> isAvailable();

  /// خواندن یک واژه یا جمله.
  Future<void> speak(String text, {double? speedFactor});

  /// تغییر سرعت پایه‌ی تلفظ (۰٫۷۵ / ۱ / ۱٫۲۵).
  Future<void> setSpeedFactor(double factor);

  Future<void> stop();

  void dispose();
}

/// پیاده‌سازی با موتور TTS سیستم‌عامل.
class TtsAudioService implements AudioService {
  TtsAudioService({this.language = 'en-US'});

  final String language;
  FlutterTts? _tts;
  bool _unavailable = false;
  double _speedFactor = 1;

  /// موتور دستگاه، سرعت را در بازه‌های متفاوتی می‌پذیرد:
  /// iOS: ۰ تا ۱ (۰٫۵ = طبیعی) و اندروید: ۱٫۰ = طبیعی.
  double get _nativeRate {
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    if (isIOS) return (0.45 * _speedFactor).clamp(0.1, 0.9);
    return (0.9 * _speedFactor).clamp(0.3, 1.6);
  }

  Future<FlutterTts?> _ensureEngine() async {
    if (_unavailable) return null;
    final existing = _tts;
    if (existing != null) return existing;
    try {
      final tts = FlutterTts();
      await tts.setLanguage(language);
      await tts.setVolume(1);
      await tts.setPitch(1);
      await tts.setSpeechRate(_nativeRate);
      await tts.awaitSpeakCompletion(true);
      _tts = tts;
      return tts;
    } catch (_) {
      // دستگاه بدون موتور TTS یا پلتفرم پشتیبانی‌نشده
      _unavailable = true;
      return null;
    }
  }

  @override
  Future<void> warmUp() async {
    await _ensureEngine();
  }

  @override
  Future<bool> isAvailable() async => (await _ensureEngine()) != null;

  @override
  Future<void> speak(String text, {double? speedFactor}) async {
    final tts = await _ensureEngine();
    if (tts == null || text.trim().isEmpty) return;
    try {
      final rate = speedFactor == null
          ? _nativeRate
          : _nativeRate * (speedFactor / _speedFactor);
      await tts.stop();
      await tts.setSpeechRate(rate.clamp(0.1, 1.6));
      await tts.speak(text);
    } catch (_) {
      // نادیده‌گرفتن خطای پخش؛ تجربه‌ی کاربر نباید قطع شود.
    }
  }

  @override
  Future<void> setSpeedFactor(double factor) async {
    _speedFactor = factor.clamp(0.5, 2.0);
    final tts = _tts;
    if (tts != null) {
      try {
        await tts.setSpeechRate(_nativeRate);
      } catch (_) {}
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts?.stop();
    } catch (_) {}
  }

  @override
  void dispose() {
    try {
      _tts?.stop();
    } catch (_) {}
    _tts = null;
  }
}

/// پیاده‌سازی خاموش — برای تست‌ها و پلتفرم‌هایی که TTS ندارند.
class SilentAudioService implements AudioService {
  const SilentAudioService();

  @override
  Future<void> warmUp() async {}

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<void> speak(String text, {double? speedFactor}) async {}

  @override
  Future<void> setSpeedFactor(double factor) async {}

  @override
  Future<void> stop() async {}

  @override
  void dispose() {}
}
