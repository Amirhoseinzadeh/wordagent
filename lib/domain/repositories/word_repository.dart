import '../entities/pack.dart';
import '../entities/word.dart';

/// قرارداد دسترسی به محتوای واژه‌ها.
///
/// پیاده‌سازی فعلی محتوا را از بسته‌ی اپ (assets) می‌خواند و می‌تواند نسخه‌ی
/// تازه‌تری را از فضای محلی روی آن سوار کند. در فاز بک‌اند، همین قرارداد با
/// یک پیاده‌سازی شبکه‌ای جایگزین می‌شود؛ بدون تغییر در هیچ بخش دیگری از اپ.
abstract class WordRepository {
  /// بارگذاری همه‌ی واژه‌ها (با کش داخلی).
  Future<List<Word>> loadWords({bool forceReload = false});

  /// بارگذاری بسته‌های موضوعی.
  Future<List<StudyPack>> loadPacks();

  /// نسخه‌ی محتوای بارگذاری‌شده.
  String? get contentVersion;

  /// آیا محتوای تازه‌تری روی دستگاه ذخیره شده است؟
  Future<bool> hasLocalUpdate();

  /// بررسی وجود محتوای تازه (در فاز بک‌اند: تماس با سرور).
  Future<bool> checkForUpdates();

  /// اعمال محتوای ذخیره‌شده‌ی محلی روی محتوای بسته (بازگشت به‌روزرسانی).
  Future<void> applyLocalUpdate();

  /// برون‌بری کل محتوا برای پشتیبان‌گیری یا آزمون.
  Future<String> exportJson();
}
