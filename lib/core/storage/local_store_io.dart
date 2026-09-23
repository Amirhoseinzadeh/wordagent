import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'local_store.dart';

/// ذخیره‌سازی فایلی (اندروید، iOS، دسکتاپ).
///
/// * همه‌ی مقادیر در یک فایل JSON کوچک نگه داشته می‌شوند؛
/// * نوشتن روی دیسک با کمی تأخیر (debounce) انجام می‌شود تا در جلسه‌های
///   مطالعه‌ی سریع، ده‌ها بار I/O سنگین رخ ندهد؛
/// * نوشتن به‌صورت اتمیک است (فایل موقت + جای‌گزینی) تا برق‌گرفتگی اپ وسط
///   نوشتن، داده‌ی کاربر را خراب نکند؛
/// * هر خطای I/O به حالت حافظه‌ای سقوط می‌کند تا اپ هرگز از کار نیفتد.
class FileLocalStore implements LocalStore {
  FileLocalStore({this.fileName = 'wordagent_store.json'});

  final String fileName;
  final Map<String, String> _cache = <String, String>{};

  File? _file;
  bool _ready = false;
  bool _dirty = false;
  Timer? _debounce;

  @override
  Future<void> init() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      if (await file.exists()) {
        final raw = await file.readAsString();
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          decoded.forEach((key, value) {
            if (value is String) _cache['$key'] = value;
          });
        }
      }
      _file = file;
    } catch (_) {
      _file = null;
    }
    _ready = true;
  }

  @override
  bool get isReady => _ready;

  @override
  String? getString(String key) => _cache[key];

  @override
  Future<void> setString(String key, String value) async {
    _cache[key] = value;
    _scheduleWrite();
  }

  @override
  Future<void> remove(String key) async {
    _cache.remove(key);
    _scheduleWrite();
  }

  @override
  Future<void> clear() async {
    _cache.clear();
    await flush();
  }

  @override
  Map<String, String> exportAll() => Map<String, String>.unmodifiable(_cache);

  void _scheduleWrite() {
    _dirty = true;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      unawaited(flush());
    });
  }

  @override
  Future<void> flush() async {
    final file = _file;
    if (file == null || !_dirty) return;
    _dirty = false;
    try {
      final temp = File('${file.path}.tmp');
      await temp.writeAsString(jsonEncode(_cache), flush: true);
      if (await file.exists()) {
        await file.delete();
      }
      await temp.rename(file.path);
    } catch (_) {
      _dirty = true;
    }
  }
}

LocalStore createLocalStore() => FileLocalStore();
