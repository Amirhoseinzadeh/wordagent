import 'package:flutter_test/flutter_test.dart';
import 'package:wordagent/data/mappers/json_utils.dart';

void main() {
  group('JsonUtils — خواندن امن مقادیر', () {
    test('asMap برای ورودی نامعتبر نقشه‌ی خالی می‌دهد', () {
      expect(JsonUtils.asMap(<String, dynamic>{'a': 1}), <String, dynamic>{'a': 1});
      expect(JsonUtils.asMap(null), isEmpty);
      expect(JsonUtils.asMap('متن'), isEmpty);
      expect(JsonUtils.asMap(<dynamic>[1, 2]), isEmpty);
      expect(
        JsonUtils.asMap(<dynamic, dynamic>{1: 'یک'}),
        <String, dynamic>{'1': 'یک'},
        reason: 'کلیدهای غیر‌رشته‌ای به رشته تبدیل می‌شوند',
      );
    });

    test('asMapList فقط نقشه‌ها را نگه می‌دارد', () {
      final result = JsonUtils.asMapList(<dynamic>[
        <String, dynamic>{'id': 'a'},
        'رشته',
        42,
        <String, dynamic>{'id': 'b'},
      ]);
      expect(result.length, 2);
      expect(result.first['id'], 'a');
      expect(JsonUtils.asMapList(null), isEmpty);
    });

    test('asStringList مقادیر غیر‌رشته‌ای را به رشته تبدیل می‌کند', () {
      expect(
        JsonUtils.asStringList(<dynamic>['a', 1, true, null, '']),
        <String>['a', '1', 'true'],
      );
      expect(JsonUtils.asStringList('تنها'), <String>['تنها']);
      expect(JsonUtils.asStringList(null), isEmpty);
    });

    test('asString و asNullableString رفتار درست دارند', () {
      expect(JsonUtils.asString('سلام'), 'سلام');
      expect(JsonUtils.asString(12), '12');
      expect(JsonUtils.asString(null, fallback: 'پیش‌فرض'), 'پیش‌فرض');
      expect(JsonUtils.asNullableString(''), isNull);
      expect(JsonUtils.asNullableString('  متن  '), 'متن');
      expect(JsonUtils.asNullableString(null), isNull);
    });

    test('asInt و asDouble اعداد متنی را هم می‌فهمند', () {
      expect(JsonUtils.asInt(5), 5);
      expect(JsonUtils.asInt('7'), 7);
      expect(JsonUtils.asInt(null, fallback: 3), 3);
      expect(JsonUtils.asInt('abc', fallback: 9), 9);
      expect(JsonUtils.asDouble('2.5'), 2.5);
      expect(JsonUtils.asDouble(3), 3.0);
      expect(JsonUtils.asDouble(null, fallback: 1.5), 1.5);
    });

    test('asBool مقادیر رایج را می‌فهمد', () {
      expect(JsonUtils.asBool(true), isTrue);
      expect(JsonUtils.asBool('true'), isTrue);
      expect(JsonUtils.asBool(1), isTrue);
      expect(JsonUtils.asBool('1'), isTrue);
      expect(JsonUtils.asBool('YES'), isTrue);
      expect(JsonUtils.asBool(0), isFalse);
      expect(JsonUtils.asBool(false), isFalse);
      expect(JsonUtils.asBool('no'), isFalse);
      expect(JsonUtils.asBool(null), isFalse);
      expect(JsonUtils.asBool('نامشخص'), isFalse, reason: 'مقدار ناشناخته پیش‌فرض را برمی‌گرداند');
      expect(JsonUtils.asBool(null, fallback: true), isTrue);
    });

    test('asDateTime قالب ISO را می‌خواند', () {
      expect(JsonUtils.asDateTime('2026-09-22T09:00:00.000'), DateTime(2026, 9, 22, 9));
      expect(JsonUtils.asDateTime(DateTime(2026, 1, 1)), DateTime(2026, 1, 1));
      expect(JsonUtils.asDateTime('نامعتبر'), isNull);
      expect(JsonUtils.asDateTime(null), isNull);
    });

    test('asIntMap مقادیر ناخوانا را صفر می‌کند', () {
      final result = JsonUtils.asIntMap(<String, dynamic>{'a': 2, 'b': '3', 'c': 'x'});
      expect(result['a'], 2);
      expect(result['b'], 3);
      expect(result['c'], 0);
      expect(JsonUtils.asIntMap(null), isEmpty);
    });

    test('mapWith فقط کلیدهای null را حذف می‌کند', () {
      final map = JsonUtils.mapWith(<(String, dynamic)>[
        ('id', 'w1'),
        ('empty', ''),
        ('none', null),
        ('zero', 0),
      ]);
      expect(map['id'], 'w1');
      expect(map.containsKey('empty'), isTrue);
      expect(map.containsKey('none'), isFalse);
      expect(map['zero'], 0);
    });
  });
}
