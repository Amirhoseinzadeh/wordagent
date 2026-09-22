import 'package:flutter/foundation.dart';

import 'cefr_level.dart';

/// یک بسته‌ی موضوعی لغت (مثل «سفر»، «کار»، «احساسات»).
@immutable
class StudyPack {
  const StudyPack({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.wordIds,
    this.level,
    this.premium = false,
    this.gradientSeed = 0,
  });

  final String id;
  final String title;
  final String description;
  final String emoji;

  /// شناسه‌ی واژه‌های داخل بسته.
  final List<String> wordIds;

  /// سطح تقریبی بسته.
  final CefrLevel? level;

  final bool premium;

  /// شماره‌ی گرادیان برای رنگ‌بندی بصری کارت.
  final int gradientSeed;

  int get wordCount => wordIds.length;

  @override
  bool operator ==(Object other) => other is StudyPack && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
