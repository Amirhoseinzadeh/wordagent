import 'package:flutter_test/flutter_test.dart';
import 'package:wordagent/core/utils/jalali_date.dart';

void main() {
  group('تبدیل میلادی به شمسی', () {
    test('اول فروردین', () {
      final date = JalaliDate.fromDateTime(DateTime(2026, 3, 21));
      expect(date.year, 1405);
      expect(date.month, 1);
      expect(date.day, 1);
    });

    test('میانه‌ی سال', () {
      final date = JalaliDate.fromDateTime(DateTime(2026, 9, 22));
      expect(date.year, 1405);
      expect(date.month, 6);
      expect(date.day, 31);
    });

    test('روز نخست سال ۱۴۰۰', () {
      final date = JalaliDate.fromDateTime(DateTime(2021, 3, 21));
      expect(date.shortLabel, '۱۴۰۰/۰۱/۰۱');
    });

    test('اسفند و اوایل فروردین سال بعد', () {
      expect(JalaliDate.fromDateTime(DateTime(2026, 3, 20)).month, 12);
      expect(JalaliDate.fromDateTime(DateTime(2026, 3, 20)).day, 29);
    });
  });

  group('تبدیل شمسی به میلادی', () {
    test('رفت‌و‌برگشت برای چند تاریخ', () {
      for (final date in <DateTime>[
        DateTime(2024, 1, 1),
        DateTime(2025, 6, 15),
        DateTime(2026, 12, 31),
        DateTime(2020, 2, 29),
      ]) {
        final roundTrip = JalaliDate.fromDateTime(date).toDateTime();
        expect(roundTrip.year, date.year);
        expect(roundTrip.month, date.month);
        expect(roundTrip.day, date.day);
      }
    });

    test('ساخت مستقیم تاریخ شمسی', () {
      expect(const JalaliDate(1400, 1, 1).toDateTime(), DateTime(2021, 3, 21));
    });
  });

  group('سال کبیسه و طول ماه', () {
    test('طول ماه‌های شمسی', () {
      expect(JalaliDate.daysInMonth(1405, 1), 31);
      expect(JalaliDate.daysInMonth(1405, 6), 31);
      expect(JalaliDate.daysInMonth(1405, 7), 30);
      expect(JalaliDate.daysInMonth(1405, 11), 30);
    });

    test('اسفند در سال عادی ۲۹ روز دارد', () {
      expect(JalaliDate.daysInMonth(1405, 12), 29);
    });

    test('سال کبیسه اسفند ۳۰ روز دارد', () {
      expect(JalaliDate.isLeapYear(1403), isTrue);
      expect(JalaliDate.daysInMonth(1403, 12), 30);
    });

    test('سال‌های کبیسه‌ی شمسی با تقویم رسمی هم‌خوان است', () {
      expect(JalaliDate.isLeapYear(1399), isTrue);
      expect(JalaliDate.isLeapYear(1403), isTrue);
      expect(JalaliDate.isLeapYear(1408), isTrue);
      expect(JalaliDate.isLeapYear(1404), isFalse);
    });
  });

  group('قالب‌بندی', () {
    final date = JalaliDate.fromDateTime(DateTime(2026, 9, 22));

    test('عنوان کامل', () {
      expect(date.longLabel, '۳۱ شهریور ۱۴۰۵');
    });

    test('عنوان کوتاه و روز-ماه', () {
      expect(date.shortLabel, '۱۴۰۵/۰۶/۳۱');
      expect(date.dayMonthLabel, '۳۱ شهریور');
    });

    test('نام روز هفته', () {
      // ۲۲ سپتامبر ۲۰۲۶ سه‌شنبه است.
      expect(date.weekDayName, 'سه‌شنبه');
      expect(date.weekDayShortName, 'سه');
    });

    test('toString برابر قالب کوتاه است', () {
      expect(date.toString(), date.shortLabel);
    });
  });

  group('مقایسه', () {
    test('ترتیب زمانی', () {
      const earlier = JalaliDate(1405, 1, 1);
      const later = JalaliDate(1405, 6, 31);
      expect(earlier.compareTo(later), lessThan(0));
      expect(later.compareTo(earlier), greaterThan(0));
      expect(earlier.compareTo(const JalaliDate(1405, 1, 1)), 0);
      expect(earlier == const JalaliDate(1405, 1, 1), isTrue);
      expect(earlier.hashCode, const JalaliDate(1405, 1, 1).hashCode);
    });

    test('ترتیب فهرست‌ها با sort', () {
      final dates = <JalaliDate>[
        const JalaliDate(1405, 6, 1),
        const JalaliDate(1404, 12, 29),
        const JalaliDate(1405, 1, 1),
      ]..sort();
      expect(dates.first.year, 1404);
      expect(dates.last.month, 6);
    });
  });
}
