/// نقش دستوری واژه.
enum PartOfSpeech {
  noun(code: 'n', faLabel: 'اسم'),
  verb(code: 'v', faLabel: 'فعل'),
  adjective(code: 'adj', faLabel: 'صفت'),
  adverb(code: 'adv', faLabel: 'قید'),
  pronoun(code: 'pron', faLabel: 'ضمیر'),
  preposition(code: 'prep', faLabel: 'حرف اضافه'),
  conjunction(code: 'conj', faLabel: 'حرف ربط'),
  determiner(code: 'det', faLabel: 'حرف تعریف'),
  interjection(code: 'intj', faLabel: 'حرف ندا'),
  numeral(code: 'num', faLabel: 'عدد'),
  phrase(code: 'phr', faLabel: 'عبارت'),
  phrasalVerb(code: 'phrv', faLabel: 'فعل عبارتی'),
  idiom(code: 'idiom', faLabel: 'اصطلاح');

  const PartOfSpeech({required this.code, required this.faLabel});

  /// کد کوتاه انگلیسی (برای نمایش کنار واژه).
  final String code;

  /// نام فارسی نقش دستوری.
  final String faLabel;

  /// واژه‌های چندبخشی (فعل عبارتی، اصطلاح و عبارت) در تمرین‌ها
  /// به شکل «چند کلمه» بررسی می‌شوند.
  bool get isMultiWord =>
      this == PartOfSpeech.phrasalVerb ||
      this == PartOfSpeech.idiom ||
      this == PartOfSpeech.phrase;

  static PartOfSpeech fromCode(String? code, {PartOfSpeech fallback = PartOfSpeech.noun}) {
    if (code == null) return fallback;
    final normalized = code.trim().toLowerCase().replaceAll(' ', '');
    for (final pos in PartOfSpeech.values) {
      if (pos.code.toLowerCase() == normalized) return pos;
      if (pos.name.toLowerCase() == normalized) return pos;
    }
    return fallback;
  }
}
