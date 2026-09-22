/// ابزارهای قالب‌بندی اعداد و متن فارسی.
///
/// در سراسر اپلیکیشن اعداد با ارقام فارسی نمایش داده می‌شوند؛ همه‌ی
/// تبدیل‌ها از همین فایل عبور می‌کنند تا رفتار یکدست بماند.
class FaFormat {
  const FaFormat._();

  static const _faDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  static const _arDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

  /// ارقام لاتین موجود در متن را به ارقام فارسی تبدیل می‌کند.
  static String digits(Object? value) {
    final text = '$value';
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      final index = _faDigits.indexOf(char);
      if (index >= 0) {
        buffer.write(_faDigits[index]);
      } else if (char.codeUnitAt(0) >= 0x30 && char.codeUnitAt(0) <= 0x39) {
        buffer.write(_faDigits[char.codeUnitAt(0) - 0x30]);
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  /// ارقام فارسی/عربی موجود در متن را به ارقام لاتین تبدیل می‌کند (برای محاسبات).
  static String toLatinDigits(String text) {
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      final faIndex = _faDigits.indexOf(char);
      final arIndex = _arDigits.indexOf(char);
      if (faIndex >= 0) {
        buffer.write(faIndex);
      } else if (arIndex >= 0) {
        buffer.write(arIndex);
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  /// عدد را با جداکننده‌ی هزارگان و ارقام فارسی برمی‌گرداند (۱۲٬۵۰۰).
  static String number(num value, {int decimals = 0, bool persianDigits = true}) {
    final raw = value.abs().toStringAsFixed(decimals);
    final parts = raw.split('.');
    final buffer = StringBuffer();
    final intPart = parts.first;
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) {
        buffer.write('٬');
      }
      buffer.write(intPart[i]);
    }
    var out = buffer.toString();
    if (parts.length > 1 && decimals > 0) {
      out = '$out٫${parts[1]}';
    }
    if (value < 0) {
      out = '−$out';
    }
    return persianDigits ? digits(out) : out;
  }

  /// درصد فارسی: ۸۵٪
  static String percent(num value, {bool withSign = false}) {
    final rounded = value.round();
    final sign = withSign && rounded > 0 ? '+' : '';
    return '$sign${digits(rounded)}٪';
  }

  /// فاصله‌ی زمانی را به متن خوانا تبدیل می‌کند: «۳ روز»، «۲ هفته».
  static String duration(Duration duration) {
    final minutes = duration.inMinutes;
    if (minutes < 1) return 'لحظه‌ای';
    if (minutes < 60) return '${digits(minutes)} دقیقه';
    final hours = duration.inHours;
    if (hours < 24) return '${digits(hours)} ساعت';
    final days = duration.inDays;
    if (days < 30) return '${digits(days)} روز';
    final months = (days / 30).round();
    if (months < 12) return '${digits(months)} ماه';
    final years = (days / 365).round();
    return '${digits(years)} سال';
  }

  /// فاصله تا موعد مرور به شکل کوتاه: «۱۰ دقیقه»، «۳ روز»، «حالا».
  static String dueLabel(Duration until) {
    if (until.inSeconds <= 60) return 'همین حالا';
    if (until.inMinutes < 60) return '${digits(until.inMinutes)} دقیقه‌ی دیگر';
    if (until.inHours < 24) return '${digits(until.inHours)} ساعت‌ی دیگر';
    return '${digits(until.inDays)} روز دیگر';
  }

  /// امتیاز عددی بزرگ را کوتاه می‌کند: ۱۲k → ۱۲ هزار.
  static String compactNumber(num value) {
    if (value.abs() < 1000) return number(value);
    if (value.abs() < 1000000) {
      final thousands = value / 1000;
      final fixed = thousands.abs() >= 100 ? thousands.round() : thousands;
      return '${number(fixed, decimals: fixed is int ? 0 : 1)} هزار';
    }
    return '${number(value / 1000000, decimals: 1)} میلیون';
  }
}
