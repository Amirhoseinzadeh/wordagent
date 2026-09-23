import 'fa_format.dart';

/// تاریخ شمسی (جلالی) — تبدیل و قالب‌بندی.
///
/// الگوریتم تبدیل، پورت دقیق الگوریتم شناخته‌شده‌ی Borkowski/jalaali است
/// که خطای آن برای بازه‌ی سال‌های ۱۱۷۸ تا ۳۱۷۷ میلادی صفر است.
class JalaliDate implements Comparable<JalaliDate> {
  const JalaliDate(this.year, this.month, this.day);

  final int year;
  final int month;
  final int day;

  static const _breaks = <int>[
    -61, 9, 38, 199, 426, 686, 756, 818, 1111, 1181,
    1210, 1635, 2060, 2097, 2192, 2262, 2324, 2394, 2456, 3178,
  ];

  static const monthNames = <String>[
    'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
    'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند',
  ];

  static const weekDayNames = <String>[
    'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه', 'شنبه', 'یکشنبه',
  ];

  /// نام روز هفته به فارسی (شنبه تا جمعه).
  static const shortWeekDayNames = <String>[
    'دو', 'سه', 'چهار', 'پنج', 'جمعه', 'شنبه', 'یک',
  ];

  static int _div(int a, int b) => a ~/ b;

  static int _mod(int a, int b) => a.remainder(b);

  /// تبدیل تاریخ میلادی به شمسی.
  factory JalaliDate.fromDateTime(DateTime date) {
    final jdn = _g2d(date.year, date.month, date.day);
    final result = _d2j(jdn);
    return JalaliDate(result[0], result[1], result[2]);
  }

  /// تبدیل تاریخ شمسی به میلادی.
  DateTime toDateTime() {
    final g = _d2g(_j2d(year, month, day));
    return DateTime(g[0], g[1], g[2]);
  }

  /// آیا سال شمسی کبیسه است؟ (مقدار ۰ در خروجی الگوریتم یعنی سال کبیسه)
  static bool isLeapYear(int year) => _jalCal(year)[0] == 0;

  static int daysInMonth(int year, int month) {
    if (month <= 6) return 31;
    if (month <= 11) return 30;
    return isLeapYear(year) ? 30 : 29;
  }

  /// قالب‌بندی کامل: «۳۱ شهریور ۱۴۰۵»
  String get longLabel => '${FaFormat.digits(day)} ${monthNames[month - 1]} ${FaFormat.digits(year)}';

  /// قالب‌بندی کوتاه: «۱۴۰۵/۰۶/۳۱»
  String get shortLabel =>
      '${FaFormat.digits(year)}/${FaFormat.digits(_two(month))}/${FaFormat.digits(_two(day))}';

  /// «۳۱ شهریور»
  String get dayMonthLabel => '${FaFormat.digits(day)} ${monthNames[month - 1]}';

  String get weekDayName => weekDayNames[(toDateTime().weekday - 1) % 7];

  String get weekDayShortName => shortWeekDayNames[(toDateTime().weekday - 1) % 7];

  static String _two(int value) => value < 10 ? '0$value' : '$value';

  @override
  int compareTo(JalaliDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is JalaliDate && other.year == year && other.month == month && other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => shortLabel;

  // ------------------------------------------------------------- تبدیل‌ها

  /// خروجی: [leap, gregorianYear, marchDay]
  static List<int> _jalCal(int jy) {
    var leapJ = -14;
    var jp = _breaks[0];
    var jump = 0;
    var i = 1;
    for (; i < _breaks.length; i++) {
      final jm = _breaks[i];
      jump = jm - jp;
      if (jy < jm) break;
      leapJ = leapJ + _div(jump, 33) * 8 + _div(_mod(jump, 33), 4);
      jp = jm;
    }
    var n = jy - jp;
    leapJ = leapJ + _div(n, 33) * 8 + _div(_mod(n, 33) + 3, 4);
    if (_mod(jump, 33) == 4 && jump - n == 4) {
      leapJ += 1;
    }
    final gregorianYear = jy + 621;
    final leapG = _div(gregorianYear, 4) - _div((_div(gregorianYear, 100) + 1) * 3, 4) - 150;
    final march = 20 + leapJ - leapG;
    if (jump - n < 6) {
      n = n - jump + _div(jump + 4, 33) * 33;
    }
    var leap = _mod(_mod(n + 1, 33) - 1, 4);
    if (leap == -1) leap = 4;
    return [leap, gregorianYear, march];
  }

  /// شماره‌ی روز مطلق (Julian day number) از تاریخ میلادی.
  static int _g2d(int gy, int gm, int gd) {
    var d = _div((gy + _div(gm - 8, 6) + 100100) * 1461, 4) +
        _div(153 * _mod(gm + 9, 12) + 2, 5) +
        gd -
        34840408;
    d = d - _div(_div(gy + 100100 + _div(gm - 8, 6), 100) * 3, 4) + 752;
    return d;
  }

  /// تاریخ میلادی از شماره‌ی روز مطلق.
  static List<int> _d2g(int jdn) {
    var j = 4 * jdn + 139361631;
    j = j + _div(_div(4 * jdn + 183187720, 146097) * 3, 4) * 4 - 3908;
    final i = _div(_mod(j, 1461), 4) * 5 + 308;
    final gd = _div(_mod(i, 153), 5) + 1;
    final gm = _mod(_div(i, 153), 12) + 1;
    final gy = _div(j, 1461) - 100100 + _div(8 - gm, 6);
    return [gy, gm, gd];
  }

  /// شماره‌ی روز مطلق از تاریخ شمسی.
  static int _j2d(int jy, int jm, int jd) {
    final r = _jalCal(jy);
    return _g2d(r[1], 3, r[2]) + (jm - 1) * 31 - _div(jm, 7) * (jm - 7) + jd - 1;
  }

  /// تاریخ شمسی از شماره‌ی روز مطلق.
  static List<int> _d2j(int jdn) {
    var gy = _d2g(jdn)[0];
    var jy = gy - 621;
    final r = _jalCal(jy);
    final jdn1f = _g2d(gy, 3, r[2]);
    var k = jdn - jdn1f;
    if (k >= 0) {
      if (k <= 185) {
        return [jy, 1 + _div(k, 31), _mod(k, 31) + 1];
      }
      k -= 186;
    } else {
      jy -= 1;
      k += 179;
      if (r[0] == 1) k += 1;
    }
    return [jy, 7 + _div(k, 30), _mod(k, 30) + 1];
  }
}

/// کمک‌کننده‌های نمایش تاریخ و زمان به فارسی.
class FaDate {
  const FaDate._();

  /// «امروز»، «دیروز»، «۳ روز پیش» یا تاریخ کامل.
  static String relative(DateTime date, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final today = DateTime(reference.year, reference.month, reference.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return 'امروز';
    if (diff == 1) return 'دیروز';
    if (diff == 2) return 'پریروز';
    if (diff == -1) return 'فردا';
    if (diff > 0 && diff < 7) return '${FaFormat.digits(diff)} روز پیش';
    if (diff < 0 && diff > -7) return '${FaFormat.digits(-diff)} روز دیگر';
    return JalaliDate.fromDateTime(date).longLabel;
  }

  /// تاریخ شمسی کوتاه به همراه روز هفته: «شنبه ۳۱ شهریور»
  static String weekDayAndDate(DateTime date) {
    final jalali = JalaliDate.fromDateTime(date);
    return '${jalali.weekDayName} ${jalali.dayMonthLabel}';
  }

  /// ساعت به شکل «۱۴:۳۰»
  static String timeOfDay(DateTime date) {
    final hour = date.hour < 10 ? '0${date.hour}' : '${date.hour}';
    final minute = date.minute < 10 ? '0${date.minute}' : '${date.minute}';
    return FaFormat.digits('$hour:$minute');
  }

  /// کلید یکتا برای یک روز (بر اساس ساعت شروع روز مطالعه در اپ).
  static String dayKey(DateTime date, {int startHour = 4}) {
    final shifted = date.subtract(Duration(hours: startHour));
    final y = shifted.year;
    final m = shifted.month < 10 ? '0${shifted.month}' : '${shifted.month}';
    final d = shifted.day < 10 ? '0${shifted.day}' : '${shifted.day}';
    return '$y-$m-$d';
  }

  /// تعداد روزهای فاصله بین دو تاریخ (بر مبنای روز تقویمی).
  static int daysBetween(DateTime a, DateTime b) {
    final first = DateTime(a.year, a.month, a.day);
    final second = DateTime(b.year, b.month, b.day);
    return second.difference(first).inDays;
  }
}
