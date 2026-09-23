import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../core/storage/local_store.dart';
import '../../domain/entities/cefr_level.dart';
import '../../domain/entities/pack.dart';
import '../../domain/entities/word.dart';
import '../mappers/json_utils.dart';
import '../mappers/word_mapper.dart';

/// نتیجه‌ی بارگذاری محتوا.
class ContentBundle {
  const ContentBundle({
    required this.words,
    required this.packs,
    required this.version,
    required this.source,
  });

  factory ContentBundle.empty() => const ContentBundle(
        words: <Word>[],
        packs: <StudyPack>[],
        version: null,
        source: 'empty',
      );

  final List<Word> words;
  final List<StudyPack> packs;
  final String? version;

  /// منبع بارگذاری: `assets` یا `local`.
  final String source;

  bool get isEmpty => words.isEmpty;

  int countFor(CefrLevel level) =>
      words.where((word) => word.level == level).length;
}

/// خواندن محتوای واژه‌ها از بسته‌ی اپ و (در صورت وجود) نسخه‌ی به‌روزشده‌ی محلی.
///
/// ساختار فایل‌های محتوا:
///  * `assets/content/manifest.json` — نسخه و فهرست فایل‌ها
///  * `assets/content/words_<level>.json` — واژه‌های هر سطح
///  * `assets/content/packs.json` — بسته‌های موضوعی
///
/// امکان به‌روزرسانی آنلاین: کل فایل محتوا می‌تواند در قالب یک رشته‌ی JSON
/// زیر کلید `content_override_v1` در ذخیره‌سازی محلی نوشته شود؛ در اجرای
/// بعدی، نسخه‌ی محلی بر نسخه‌ی بسته‌ی اپ اولویت می‌گیرد. (`RemoteContentUpdater`
/// در فاز بک‌اند همان کلید را پر می‌کند.)
class ContentSource {
  ContentSource(this._store, {this.assetRoot = 'assets/content'});

  final LocalStore _store;
  final String assetRoot;

  static const String overrideKey = 'content_override_v1';

  /// مسیر فایل‌های محتوا.
  static List<String> get levelFiles =>
      CefrLevel.values.map((level) => 'words_${level.code.toLowerCase()}.json').toList();

  Future<ContentBundle> load({bool preferLocal = true}) async {
    if (preferLocal) {
      final local = await _loadLocalOverride();
      if (local != null && local.words.isNotEmpty) return local;
    }
    return _loadFromAssets();
  }

  Future<ContentBundle> _loadFromAssets() async {
    final words = <Word>[];
    var version = '1.0.0';

    final manifest = await _readJson('$assetRoot/manifest.json');
    if (manifest != null) {
      version = JsonUtils.asString(manifest['version'], fallback: version);
    }

    final packIndex = <String, List<String>>{};
    final packsRaw = await _readJson('$assetRoot/packs.json');
    final packs = <StudyPack>[];
    if (packsRaw != null) {
      for (final entry in JsonUtils.asMapList(packsRaw['packs'])) {
        final pack = _packFromJson(entry);
        if (pack == null) continue;
        packs.add(pack);
        for (final wordId in pack.wordIds) {
          packIndex.putIfAbsent(wordId, () => <String>[]).add(pack.id);
        }
      }
    }

    for (final file in levelFiles) {
      final raw = await _readJson('$assetRoot/$file');
      if (raw == null) continue;
      for (final item in JsonUtils.asMapList(raw['words'])) {
        final id = JsonUtils.asString(item['id']);
        if (id.isEmpty) continue;
        words.add(WordMapper.fromJson(item, packIds: packIndex[id] ?? const <String>[]));
      }
    }

    return ContentBundle(
      words: words,
      packs: packs,
      version: version,
      source: 'assets',
    );
  }

  Future<ContentBundle?> _loadLocalOverride() async {
    final raw = _store.getString(overrideKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = JsonUtils.asMap(jsonDecode(raw));
      final words = <Word>[];
      for (final item in JsonUtils.asMapList(decoded['words'])) {
        final id = JsonUtils.asString(item['id']);
        if (id.isEmpty) continue;
        words.add(WordMapper.fromJson(item));
      }
      final packs = <StudyPack>[];
      for (final item in JsonUtils.asMapList(decoded['packs'])) {
        final pack = _packFromJson(item);
        if (pack != null) packs.add(pack);
      }
      return ContentBundle(
        words: words,
        packs: packs,
        version: JsonUtils.asString(decoded['version'], fallback: 'local'),
        source: 'local',
      );
    } catch (_) {
      return null;
    }
  }

  StudyPack? _packFromJson(Map<String, dynamic> json) {
    final id = JsonUtils.asString(json['id']);
    final title = JsonUtils.asString(json['title']);
    if (id.isEmpty || title.isEmpty) return null;
    final levelCode = JsonUtils.asNullableString(json['level']);
    return StudyPack(
      id: id,
      title: title,
      description: JsonUtils.asString(json['desc']),
      emoji: JsonUtils.asString(json['emoji'], fallback: '📘'),
      wordIds: JsonUtils.asStringList(json['words']),
      level: levelCode == null ? null : CefrLevel.fromCode(levelCode),
      premium: JsonUtils.asBool(json['premium']),
      gradientSeed: JsonUtils.asInt(json['seed']),
    );
  }

  Future<Map<String, dynamic>?> _readJson(String path) async {
    try {
      final raw = await rootBundle.loadString(path);
      if (raw.trim().isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is Map) return JsonUtils.asMap(decoded);
      return null;
    } catch (_) {
      // فایل وجود ندارد یا خراب است؛ اپ باید بدون آن هم کار کند.
      return null;
    }
  }
}
