/// نرمال‌سازی و مقایسه‌ی متن — قلب سنجش پاسخ‌های تایپی.
///
/// چالش اصلی: کاربران فارسی‌زبان «ی» و «ک» عربی، نیم‌فاصله، اعراب و
/// فاصله‌های اضافه را به شکل‌های مختلف تایپ می‌کنند. این کلاس همه‌ی این‌ها
/// را یکدست می‌کند تا یک پاسخ درست، بی‌دلیل غلط شمرده نشود.
class TextNormalizer {
  const TextNormalizer._();

  static const _zwnj = '\u200c';
  static const _zwnjAlt = '\u200d';

  /// کاراکترهای اعراب و تشدید و تنوین در بازه‌ی عربی.
  static final RegExp _diacritics = RegExp(r'[\u064B-\u0652\u0670\u0653-\u0655\u0640]');

  static final RegExp _punctuation = RegExp(r'[.,!?;:"«»„“”‌()\[\]{}<>،؛؟…\-\u2013\u2014_/\\|*#%$@&+=~^]');
  static final RegExp _spaces = RegExp(r'\s+');

  /// نرمال‌سازی متن فارسی برای مقایسه.
  static String normalizeFa(String input) {
    var text = input.trim().toLowerCase();
    // «ي» و «ى» (الف مقصوره) هر دو در تایپ عربی/موبایل برای «ی» می‌آیند.
    text = text
        .replaceAll('ي', 'ی')
        .replaceAll('ى', 'ی')
        .replaceAll('ك', 'ک');
    text = text.replaceAll('ۀ', 'ه').replaceAll('ة', 'ه');
    text = text.replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('آ', 'آ');
    text = text.replaceAll('ؤ', 'و').replaceAll('ئ', 'ی');
    text = text.replaceAll(_zwnj, '').replaceAll(_zwnjAlt, '');
    text = text.replaceAll(_diacritics, '');
    text = text.replaceAll(_punctuation, ' ');
    text = text.replaceAll('  ', ' ');
    text = text.replaceAll(_spaces, ' ');
    return text.trim();
  }

  /// نرمال‌سازی متن انگلیسی.
  static String normalizeEn(String input) {
    var text = input.trim().toLowerCase();
    text = text.replaceAll('\u2019', "'").replaceAll('\u2018', "'");
    text = text.replaceAll(_punctuation, ' ');
    text = text.replaceAll(_spaces, ' ');
    return text.trim();
  }

  /// نرمال‌سازی برای مقایسه‌ی جمله (حساس به ترتیب کلمات).
  static List<String> tokenizeEn(String input) =>
      normalizeEn(input).split(' ').where((t) => t.isNotEmpty).toList();

  static List<String> tokenizeFa(String input) =>
      normalizeFa(input).split(' ').where((t) => t.isNotEmpty).toList();

  /// فاصله‌ی لِوِنشتِین بین دو رشته.
  static int levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    final previous = List<int>.generate(b.length + 1, (i) => i);
    final current = List<int>.filled(b.length + 1, 0);
    for (var i = 0; i < a.length; i++) {
      current[0] = i + 1;
      for (var j = 0; j < b.length; j++) {
        final cost = a.codeUnitAt(i) == b.codeUnitAt(j) ? 0 : 1;
        final deletion = previous[j + 1] + 1;
        final insertion = current[j] + 1;
        final substitution = previous[j] + cost;
        var min = deletion < insertion ? deletion : insertion;
        if (substitution < min) min = substitution;
        current[j + 1] = min;
      }
      for (var j = 0; j <= b.length; j++) {
        previous[j] = current[j];
      }
    }
    return previous[b.length];
  }

  /// شباهت دو رشته در بازه‌ی ۰ تا ۱.
  static double similarity(String a, String b) {
    if (a.isEmpty && b.isEmpty) return 1;
    final maxLength = a.length > b.length ? a.length : b.length;
    if (maxLength == 0) return 1;
    return 1 - levenshtein(a, b) / maxLength;
  }

  /// آیا پاسخ تایپی کاربر با یکی از پاسخ‌های درست هم‌خوان است؟
  ///
  /// [threshold] آستانه‌ی بخشش خطای تایپی است (پیش‌فرض ۰٫۸۵). برای پاسخ‌های
  /// کوتاه‌تر از ۵ نویسه، آستانه سخت‌گیرانه‌تر می‌شود تا پاسخ‌های نادرست
  /// کوتاه (مثل do/go) اشتباهاً درست شمرده نشوند.
  static bool matchesFa(
    String userAnswer,
    List<String> accepted, {
    double threshold = 0.85,
  }) {
    final normalized = normalizeFa(userAnswer);
    if (normalized.isEmpty) return false;
    for (final raw in accepted) {
      for (final candidate in expandVariants(raw)) {
        if (candidate.isEmpty) continue;
        if (normalized == candidate) return true;
        final localThreshold = candidate.length <= 4 ? 0.99 : threshold;
        if (candidate.length >= 3 && similarity(normalized, candidate) >= localThreshold) {
          return true;
        }
        // اگر کاربر یکی از معنی‌ها را همراه توضیح نوشته باشد.
        if (candidate.length >= 3 && normalized.contains(candidate)) return true;
      }
    }
    return false;
  }

  /// آیا عبارت انگلیسی تایپ‌شده درست است؟
  static bool matchesEn(
    String userAnswer,
    List<String> accepted, {
    double threshold = 0.9,
  }) {
    final normalized = normalizeEn(userAnswer);
    if (normalized.isEmpty) return false;
    for (final raw in accepted) {
      final candidate = normalizeEn(raw);
      if (candidate.isEmpty) continue;
      if (normalized == candidate) return true;
      if (candidate.length >= 4 && similarity(normalized, candidate) >= threshold) {
        return true;
      }
    }
    return false;
  }

  /// پاسخ‌های چندگانه‌ی یک معنی را به واریانت‌های مستقل می‌شکند.
  ///
  /// مثال: «ساختن؛ درست کردن (to make)» → [ساختن, درست کردن, to make]
  static List<String> expandVariants(String raw) {
    final cleaned = raw
        .replaceAll('(', '\u0000')
        .replaceAll(')', '\u0000')
        .replaceAll('«', '\u0000')
        .replaceAll('»', '\u0000');
    final parts = cleaned.split(RegExp(r'[؛;،,\u0000/]|\s+یا\s+'));
    final variants = <String>[];
    for (final part in parts) {
      var value = part.trim();
      if (value.isEmpty) continue;
      // حذف توضیح‌های داخل گیومه مثل «کتاب»
      value = value.replaceAll(RegExp(r'^(به معنی|یعنی|معنی)\s+'), '');
      final normalized = normalizeFa(value);
      if (normalized.isEmpty) continue;
      variants.add(normalized);
      // «درست کردن» → «درستکردن» (با و بدون فاصله)
      variants.add(normalized.replaceAll(' ', ''));
      if (normalized.startsWith('به ') || normalized.startsWith('از ')) {
        variants.add(normalized.substring(3));
      }
    }
    return variants;
  }

  /// ترتیب کلمات جمله را با هم مقایسه می‌کند (برای تمرین جمله‌سازی).
  static bool sameWordOrder(List<String> userTokens, List<String> expectedTokens) {
    if (userTokens.length != expectedTokens.length) return false;
    for (var i = 0; i < userTokens.length; i++) {
      if (userTokens[i] != expectedTokens[i]) return false;
    }
    return true;
  }

  /// حذف علامت‌های پایان جمله برای نمایش در تمرین جمله‌سازی.
  ///
  /// هم نشانه‌های لاتین و هم نشانه‌های فارسی/عربی («؟»، «…») پاک می‌شوند.
  static String stripEndPunctuation(String text) =>
      text.replaceAll(RegExp(r'[.!?؟…،؛,]+$'), '').trim();
}
