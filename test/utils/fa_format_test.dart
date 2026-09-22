import 'package:flutter_test/flutter_test.dart';
import 'package:wordagent/core/utils/fa_format.dart';

void main() {
  group('FaFormat.digits', () {
    test('ارقام لاتین را فارسی می‌کند', () {
      expect(FaFormat.digits('2026'), '۲۰۲۶');
      expect(FaFormat.digits(42), '۴۲');
      expect(FaFormat.digits('درس ۳ از ۱۲'), 'درس ۳ از ۱۲');
    });

    test('متن بدون عدد را دست‌نخورده برمی‌گرداند', () {
      expect(FaFormat.digits('سلام دنیا'), 'سلام دنیا');
      expect(FaFormat.digits(null), 'null');
    });
  });

  group('FaFormat.toLatinDigits', () {
    test('ارقام فارسی را به لاتین برمی‌گرداند', () {
      expect(FaFormat.toLatinDigits('۱۲۳۴'), '1234');
    });

    test('ارقام عربی را هم پوشش می‌دهد', () {
      expect(FaFormat.toLatinDigits('٤٥٦'), '456');
    });

    test('تبدیل متقابل ارقام درست کار می‌کند', () {
      const source = '۱۴۰۵/۰۶/۳۱ — ۹۵٪';
      expect(FaFormat.toLatinDigits(source), '1405/06/31 — 95٪');
      expect(FaFormat.digits(FaFormat.toLatinDigits('۱٬۲۵۰')), '۱٬۲۵۰');
      expect(FaFormat.toLatinDigits('۱٬۲۵۰'), '1٬250');
    });
  });

  group('FaFormat.number', () {
    test('جداکننده‌ی هزارگان می‌گذارد', () {
      expect(FaFormat.number(1250), '۱٬۲۵۰');
      expect(FaFormat.number(999), '۹۹۹');
      expect(FaFormat.number(1000000), '۱٬۰۰۰٬۰۰۰');
    });

    test('اعشار را با ممیز فارسی نشان می‌دهد', () {
      expect(FaFormat.number(12.5, decimals: 1), '۱۲٫۵');
    });

    test('عدد منفی را با علامت فارسی برمی‌گرداند', () {
      expect(FaFormat.number(-15), '−۱۵');
    });

    test('حالت بدون ارقام فارسی برای محاسبات', () {
      expect(FaFormat.number(1250, persianDigits: false), '1٬250');
    });
  });

  group('FaFormat.percent', () {
    test('درصد ساده را گرد می‌کند', () {
      expect(FaFormat.percent(85), '۸۵٪');
      expect(FaFormat.percent(85.4), '۸۵٪');
      expect(FaFormat.percent(85.6), '۸۶٪');
    });

    test('حالت با علامت مثبت', () {
      expect(FaFormat.percent(12, withSign: true), '+۱۲٪');
      expect(FaFormat.percent(0, withSign: true), '۰٪');
    });
  });

  group('FaFormat.duration', () {
    test('بازه‌های زمانی را خوانا می‌کند', () {
      expect(FaFormat.duration(const Duration(seconds: 30)), 'لحظه‌ای');
      expect(FaFormat.duration(const Duration(minutes: 5)), '۵ دقیقه');
      expect(FaFormat.duration(const Duration(hours: 3)), '۳ ساعت');
      expect(FaFormat.duration(const Duration(days: 4)), '۴ روز');
      expect(FaFormat.duration(const Duration(days: 60)), '۲ ماه');
      expect(FaFormat.duration(const Duration(days: 730)), '۲ سال');
    });
  });

  group('FaFormat.dueLabel', () {
    test('برچسب مرور بر اساس فاصله‌ی زمانی', () {
      expect(FaFormat.dueLabel(const Duration(seconds: 10)), 'همین حالا');
      expect(FaFormat.dueLabel(const Duration(minutes: 20)), '۲۰ دقیقه‌ی دیگر');
      expect(FaFormat.dueLabel(const Duration(hours: 6)), '۶ ساعت‌ی دیگر');
      expect(FaFormat.dueLabel(const Duration(days: 3)), '۳ روز دیگر');
    });
  });

  group('FaFormat.compactNumber', () {
    test('عددهای کوچک دست‌نخورده می‌مانند', () {
      expect(FaFormat.compactNumber(950), '۹۵۰');
    });

    test('هزارگان و میلیون‌ها کوتاه می‌شوند', () {
      expect(FaFormat.compactNumber(12000), '۱۲ هزار');
      expect(FaFormat.compactNumber(250000), '۲۵۰ هزار');
      expect(FaFormat.compactNumber(3000000), '۳ میلیون');
    });

    test('عددهای شکسته اعشار می‌گیرند', () {
      expect(FaFormat.compactNumber(1500000), '۱٫۵ میلیون');
      expect(FaFormat.compactNumber(9500), '۹٫۵ هزار');
    });
  });
}
