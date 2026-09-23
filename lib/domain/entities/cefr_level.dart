/// سطح‌های استاندارد اروپایی (CEFR) از A1 تا C2.
///
/// برچسب‌های فارسی عمداً داخل همین enum نگه داشته شده‌اند تا عنوان سطح
/// در کل اپلیکیشن یک منبع حقیقت داشته باشد.
enum CefrLevel {
  a1(
    code: 'A1',
    faTitle: 'مبتدی',
    faDescription: 'واژه‌های پایه و پرکاربرد روزمره',
    difficulty: 1,
  ),
  a2(
    code: 'A2',
    faTitle: 'پایه',
    faDescription: 'مکالمه‌ی ساده‌ی روزمره',
    difficulty: 2,
  ),
  b1(
    code: 'B1',
    faTitle: 'متوسط',
    faDescription: 'موقعیت‌های آشنا و سفر',
    difficulty: 3,
  ),
  b2(
    code: 'B2',
    faTitle: 'متوسط بالا',
    faDescription: 'متن‌های تخصصی و بحث جدی',
    difficulty: 4,
  ),
  c1(
    code: 'C1',
    faTitle: 'پیشرفته',
    faDescription: 'نوشتار آکادمیک و ادبی',
    difficulty: 5,
  ),
  c2(
    code: 'C2',
    faTitle: 'تسلط کامل',
    faDescription: 'واژگان نادر، اصطلاحات و ظرافت‌ها',
    difficulty: 6,
  );

  const CefrLevel({
    required this.code,
    required this.faTitle,
    required this.faDescription,
    required this.difficulty,
  });

  /// کد استاندارد سطح (A1 … C2).
  final String code;

  /// عنوان فارسی سطح.
  final String faTitle;

  /// توضیح یک‌خطی سطح.
  final String faDescription;

  /// عدد دشواری ۱ تا ۶ برای مقایسه و مرتب‌سازی.
  final int difficulty;

  /// سطح بعدی (اگر وجود داشته باشد).
  CefrLevel? get next {
    final index = CefrLevel.values.indexOf(this);
    if (index < 0 || index >= CefrLevel.values.length - 1) return null;
    return CefrLevel.values[index + 1];
  }

  /// سطح قبلی.
  CefrLevel? get previous {
    final index = CefrLevel.values.indexOf(this);
    if (index <= 0) return null;
    return CefrLevel.values[index - 1];
  }

  /// برچسب ترکیبی: «B1 — متوسط»
  String get fullLabel => '$code — $faTitle';

  static CefrLevel fromCode(String? code, {CefrLevel fallback = CefrLevel.a1}) {
    if (code == null) return fallback;
    final normalized = code.trim().toUpperCase();
    for (final level in CefrLevel.values) {
      if (level.code == normalized) return level;
    }
    return fallback;
  }

  /// نزدیک‌ترین سطح به یک عدد دشواری پیوسته (برای آزمون تعیین سطح).
  static CefrLevel fromDifficulty(double value) {
    final index = (value.round() - 1).clamp(0, CefrLevel.values.length - 1);
    return CefrLevel.values[index];
  }
}
