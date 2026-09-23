/// کمک‌کننده‌های ایمن خواندن JSON.
///
/// داده‌ی محتوا ممکن است در آینده از سرور بیاید و شکل آن تغییر کند؛ این
/// توابع هرگز استثنا پرتاب نمی‌کنند و در بدترین حالت مقدار پیش‌فرض می‌دهند
/// تا یک فیلد ناقص، کل اپ را از کار نیندازد.
class JsonUtils {
  const JsonUtils._();

  static Map<String, dynamic> asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry('$key', item));
    }
    return <String, dynamic>{};
  }

  static List<Map<String, dynamic>> asMapList(dynamic value) {
    if (value is! List) return <Map<String, dynamic>>[];
    return value.map(asMap).where((item) => item.isNotEmpty).toList(growable: false);
  }

  static List<String> asStringList(dynamic value) {
    if (value is String) {
      return value
          .split('؛')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    if (value is! List) return <String>[];
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static String asString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static String? asNullableString(dynamic value) {
    final text = asString(value);
    return text.isEmpty ? null : text;
  }

  static int asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is bool) return value ? 1 : 0;
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) return parsed;
      final asDouble = double.tryParse(value.trim());
      if (asDouble != null) return asDouble.round();
    }
    return fallback;
  }

  static double asDouble(dynamic value, {double fallback = 0}) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  static bool asBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') return true;
      if (normalized == 'false' || normalized == '0' || normalized == 'no') return false;
    }
    return fallback;
  }

  static DateTime? asDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) {
      if (value.trim().isEmpty) return null;
      final millis = int.tryParse(value.trim());
      if (millis != null) return DateTime.fromMillisecondsSinceEpoch(millis);
      return DateTime.tryParse(value);
    }
    return null;
  }

  static Map<String, int> asIntMap(dynamic value) {
    final map = asMap(value);
    final result = <String, int>{};
    map.forEach((key, item) {
      result[key] = asInt(item);
    });
    return result;
  }

  static Map<String, dynamic> mapWith(List<(String, dynamic)> entries) {
    final result = <String, dynamic>{};
    for (final entry in entries) {
      if (entry.$2 == null) continue;
      result[entry.$1] = entry.$2;
    }
    return result;
  }
}
