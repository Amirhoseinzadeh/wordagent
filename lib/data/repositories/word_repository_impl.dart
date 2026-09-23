import 'dart:convert';

import '../../core/storage/local_store.dart';
import '../../domain/entities/pack.dart';
import '../../domain/entities/word.dart';
import '../../domain/repositories/word_repository.dart';
import '../mappers/json_utils.dart';
import '../mappers/word_mapper.dart';
import '../sources/content_source.dart';

/// پیاده‌سازی مخزن واژه‌ها روی محتوای بسته‌ی اپ + لایه‌ی به‌روزرسانی محلی.
class WordRepositoryImpl implements WordRepository {
  WordRepositoryImpl(
    this._source,
    this._store, {
    Future<String?> Function()? remoteFetcher,
  }) : _remoteFetcher = remoteFetcher;

  final ContentSource _source;
  final LocalStore _store;

  /// تابع دریافت محتوای تازه از شبکه.
  ///
  /// در فاز فعلی `null` است (اپ کاملاً آفلاین کار می‌کند)؛ در فاز بک‌اند یک
  /// تابع متصل به Supabase/CDN این‌جا تزریق می‌شود و بقیه‌ی اپ تغییری نمی‌خواهد.
  final Future<String?> Function()? _remoteFetcher;

  ContentBundle? _cache;
  List<Word> _words = <Word>[];
  List<StudyPack> _packs = <StudyPack>[];
  Map<String, Word> _byId = <String, Word>{};

  @override
  String? get contentVersion => _cache?.version;

  @override
  Future<List<Word>> loadWords({bool forceReload = false}) async {
    if (_cache == null || forceReload) {
      await _load(forceReload: forceReload);
    }
    return _words;
  }

  @override
  Future<List<StudyPack>> loadPacks() async {
    if (_cache == null) await _load(forceReload: false);
    return _packs;
  }

  /// دسترسی سریع به واژه با شناسه (برای صفحه‌ی جزئیات و مرور).
  Word? wordById(String id) => _byId[id];

  Map<String, Word> get wordIndex => _byId;

  Future<void> _load({required bool forceReload}) async {
    // نسخه‌ی محلی (خروجی به‌روزرسانی آنلاین) همیشه بر نسخه‌ی بسته‌ی اپ
    // اولویت دارد؛ `forceReload` فقط کش داخلی را دور می‌زند تا محتوای
    // تازه دوباره خوانده شود.
    final bundle = await _source.load();
    _cache = bundle;
    _words = bundle.words;
    _packs = bundle.packs;
    _byId = <String, Word>{for (final word in _words) word.id: word};
  }

  @override
  Future<bool> hasLocalUpdate() async =>
      (_store.getString(ContentSource.overrideKey) ?? '').isNotEmpty;

  @override
  Future<bool> checkForUpdates() async {
    final fetcher = _remoteFetcher;
    if (fetcher == null) return false;
    try {
      final payload = await fetcher();
      if (payload == null || payload.trim().isEmpty) return false;
      final decoded = JsonUtils.asMap(jsonDecode(payload));
      final words = JsonUtils.asMapList(decoded['words']);
      if (words.isEmpty) return false;
      // اعتبارسنجی سبک: هر واژه باید شناسه و معنی داشته باشد.
      for (final item in words) {
        if (JsonUtils.asString(item['id']).isEmpty) return false;
        if (JsonUtils.asStringList(item['fa']).isEmpty) return false;
      }
      await _store.setString(ContentSource.overrideKey, payload);
      await _load(forceReload: true);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> applyLocalUpdate() async {
    final raw = _store.getString(ContentSource.overrideKey);
    if (raw == null || raw.isEmpty) return;
    await _load(forceReload: true);
  }

  @override
  Future<String> exportJson() async {
    final bundle = _cache ?? await _source.load();
    final payload = <String, dynamic>{
      'version': bundle.version,
      'words': bundle.words.map(WordMapper.toJson).toList(growable: false),
      'packs': bundle.packs
          .map((pack) => <String, dynamic>{
                'id': pack.id,
                'title': pack.title,
                'desc': pack.description,
                'emoji': pack.emoji,
                'words': pack.wordIds,
                if (pack.level != null) 'level': pack.level!.code,
                if (pack.premium) 'premium': true,
                'seed': pack.gradientSeed,
              })
          .toList(growable: false),
    };
    return jsonEncode(payload);
  }
}
