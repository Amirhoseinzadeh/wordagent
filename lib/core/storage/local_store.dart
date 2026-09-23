/// ذخیره‌سازی محلی کلید-مقدار.
///
/// پیاده‌سازی‌ها:
///  * موبایل/دسکتاپ: فایل JSON در پوشه‌ی اسناد اپ (`local_store_io.dart`)
///  * وب/تست: نگهدارنده‌ی حافظه‌ای (`local_store_memory.dart`)
///
/// دامنه‌ی اپلیکیشن فقط به این قرارداد وابسته است؛ پس افزودن بک‌اند ابری
/// در آینده فقط یک پیاده‌سازی تازه می‌خواهد، نه تغییر در منطق.
abstract class LocalStore {
  /// آماده‌سازی محل ذخیره و خواندن داده‌های پیشین.
  Future<void> init();

  bool get isReady;

  String? getString(String key);

  Future<void> setString(String key, String value);

  Future<void> remove(String key);

  /// پاک‌کردن کامل داده‌ها (بازنشانی پیشرفت).
  Future<void> clear();

  /// همه‌ی کلیدهای موجود (برای برون‌بری داده).
  Map<String, String> exportAll();

  /// نوشتن فوری داده‌های معلق روی دیسک (پیش از بستن اپ).
  Future<void> flush();
}

/// فضاهای نام کلیدهای ذخیره‌سازی.
class StoreKeys {
  const StoreKeys._();

  static const profile = 'profile';
  static const settings = 'settings';
  static const progress = 'word_progress';
  static const sessions = 'study_sessions';
  static const achievements = 'achievements';
  static const streak = 'streak';
  static const subscription = 'subscription';
  static const chat = 'ai_chat';
  static const contentMeta = 'content_meta';
  static const onboarding = 'onboarding';
}
