import 'local_store.dart';

/// پیاده‌سازی حافظه‌ای — برای وب، تست‌ها و پلتفرم‌هایی که دسترسی به فایل ندارند.
///
/// داده‌ها در طول عمر برنامه نگه داشته می‌شوند؛ پس اپ کار می‌کند، فقط
/// پیشرفت بین دو اجرا باقی نمی‌ماند. افزودن پیاده‌سازی مبتنی بر
/// `localStorage` یا `IndexedDB` در آینده از همین قرارداد انجام می‌شود.
class MemoryLocalStore implements LocalStore {
  final Map<String, String> _cache = <String, String>{};
  bool _ready = false;

  @override
  Future<void> init() async => _ready = true;

  @override
  bool get isReady => _ready;

  @override
  String? getString(String key) => _cache[key];

  @override
  Future<void> setString(String key, String value) async {
    _cache[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _cache.remove(key);
  }

  @override
  Future<void> clear() async {
    _cache.clear();
  }

  @override
  Map<String, String> exportAll() => Map<String, String>.unmodifiable(_cache);

  @override
  Future<void> flush() async {}
}

LocalStore createLocalStore() => MemoryLocalStore();
