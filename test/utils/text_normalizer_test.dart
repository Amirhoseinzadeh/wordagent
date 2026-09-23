import 'package:flutter_test/flutter_test.dart';
import 'package:wordagent/core/utils/text_normalizer.dart';

void main() {
  group('normalizeFa', () {
    test('حرف عربی «ي» و «ك» را به فارسی تبدیل می‌کند', () {
      expect(TextNormalizer.normalizeFa('يكي'), TextNormalizer.normalizeFa('یکی'));
    });

    test('حرکت‌ها و کشیده را حذف می‌کند', () {
      expect(TextNormalizer.normalizeFa('کِتَابْ'), 'کتاب');
    });

    test('نیم‌فاصله را یکدست می‌کند', () {
      // نیم‌فاصله حذف می‌شود؛ «می‌رود» و «میرود» یکسان دیده می‌شوند.
      expect(TextNormalizer.normalizeFa('می‌رود'), 'میرود');
      expect(
        TextNormalizer.normalizeFa('می‌رود'),
        TextNormalizer.normalizeFa('میرود'),
      );
    });

    test('نشانه‌گذاری و فاصله‌های اضافه را پاک می‌کند', () {
      expect(TextNormalizer.normalizeFa('  سلام،   دنیا!  '), 'سلام دنیا');
    });

    test('«ه» و «هٔ» را با هم یکسان می‌کند', () {
      expect(TextNormalizer.normalizeFa('خانۀ من'), TextNormalizer.normalizeFa('خانه من'));
    });

    test('متن خالی را خالی برمی‌گرداند', () {
      expect(TextNormalizer.normalizeFa('   '), '');
    });
  });

  group('normalizeEn', () {
    test('حروف بزرگ را کوچک و فاصله‌ها را یکدست می‌کند', () {
      expect(TextNormalizer.normalizeEn('  Hello   WORLD! '), 'hello world');
    });

    test('نشانه‌گذاری انگلیسی حذف می‌شود', () {
      expect(TextNormalizer.normalizeEn('Hello, world!'), 'hello world');
      expect(TextNormalizer.normalizeEn('Ready?'), 'ready');
    });
  });

  group('tokenize', () {
    test('جمله‌ی انگلیسی به کلمه‌ها می‌شکند', () {
      expect(
        TextNormalizer.tokenizeEn('She is resilient, after every failure!'),
        <String>['she', 'is', 'resilient', 'after', 'every', 'failure'],
      );
    });

    test('جمله‌ی فارسی به کلمه‌ها می‌شکند', () {
      expect(
        TextNormalizer.tokenizeFa('او هر روز تمرین می‌کند.'),
        <String>['او', 'هر', 'روز', 'تمرین', 'میکند'],
      );
    });
  });

  group('levenshtein و similarity', () {
    test('فاصله‌ی ویرایشی درست حساب می‌شود', () {
      expect(TextNormalizer.levenshtein('kitten', 'sitting'), 3);
      expect(TextNormalizer.levenshtein('book', 'book'), 0);
      expect(TextNormalizer.levenshtein('', 'abc'), 3);
    });

    test('شباهت بین ۰ و ۱ است', () {
      expect(TextNormalizer.similarity('resilient', 'resilient'), 1);
      expect(TextNormalizer.similarity('resilient', 'resiliant'), greaterThan(0.7));
      expect(TextNormalizer.similarity('resilient', 'resilence'), closeTo(0.67, 0.02));
      expect(TextNormalizer.similarity('book', 'elephant'), lessThan(0.3));
    });

    test('دو رشته‌ی خالی شباهت کامل دارند', () {
      expect(TextNormalizer.similarity('', ''), 1);
    });
  });

  group('matchesEn', () {
    test('پاسخ دقیق پذیرفته می‌شود', () {
      expect(TextNormalizer.matchesEn('resilient', <String>['resilient']), isTrue);
    });

    test('حرف بزرگ و فاصله‌ی اضافه مشکلی ایجاد نمی‌کند', () {
      expect(TextNormalizer.matchesEn('  Resilient ', <String>['resilient']), isTrue);
    });

    test('خطای تایپی کوچک در واژه‌های بلند بخشیده می‌شود', () {
      expect(
        TextNormalizer.matchesEn('extraordinry', <String>['extraordinary']),
        isTrue,
      );
    });

    test('واژه‌ی بی‌ربط رد می‌شود', () {
      expect(TextNormalizer.matchesEn('fragile', <String>['resilient']), isFalse);
      expect(TextNormalizer.matchesEn('', <String>['resilient']), isFalse);
    });

    test('یکی از چند پاسخ پذیرفته‌شده کافی است', () {
      expect(
        TextNormalizer.matchesEn('make', <String>['make', 'create']),
        isTrue,
      );
    });
  });

  group('matchesFa', () {
    test('فاصله به‌جای نیم‌فاصله مشکلی ندارد', () {
      expect(TextNormalizer.matchesFa('تاب آور', <String>['تاب‌آور']), isTrue);
    });

    test('واژه‌ی درست با «ی» عربی هم پذیرفته می‌شود', () {
      expect(TextNormalizer.matchesFa('ضرورى', <String>['ضروری']), isTrue);
    });

    test('نیم‌فاصله و اعراب مانع پذیرش نیست', () {
      expect(TextNormalizer.matchesFa('خانه', <String>['خانۀ']), isTrue);
    });

    test('معنی اشتباه رد می‌شود', () {
      expect(TextNormalizer.matchesFa('درخت', <String>['تاب‌آور']), isFalse);
      expect(TextNormalizer.matchesFa('', <String>['تاب‌آور']), isFalse);
    });
  });

  group('expandVariants', () {
    test('چند معنی جداشده با «؛» را می‌شکند', () {
      final variants = TextNormalizer.expandVariants('ساختن؛ درست کردن');
      expect(variants, contains('ساختن'));
      expect(variants, contains('درست کردن'));
    });

    test('توضیح داخل پرانتز را جدا می‌کند', () {
      final variants = TextNormalizer.expandVariants('رفتن (to go)');
      expect(variants, contains('رفتن'));
      expect(variants, contains('to go'));
    });

    test('پیشوند «به معنی» را پاک می‌کند', () {
      expect(TextNormalizer.expandVariants('به معنی بزرگ'), contains('بزرگ'));
    });

    test('نسخه‌ی بدون فاصله هم ساخته می‌شود', () {
      expect(TextNormalizer.expandVariants('درست کردن'), contains('درستکردن'));
    });
  });

  group('sameWordOrder', () {
    test('ترتیب درست تأیید می‌شود', () {
      expect(
        TextNormalizer.sameWordOrder(
          <String>['she', 'is', 'happy'],
          <String>['she', 'is', 'happy'],
        ),
        isTrue,
      );
    });

    test('ترتیب نادرست یا طول متفاوت رد می‌شود', () {
      expect(
        TextNormalizer.sameWordOrder(
          <String>['is', 'she', 'happy'],
          <String>['she', 'is', 'happy'],
        ),
        isFalse,
      );
      expect(
        TextNormalizer.sameWordOrder(<String>['she'], <String>['she', 'is']),
        isFalse,
      );
    });
  });

  group('stripEndPunctuation', () {
    test('نشانه‌های پایان جمله حذف می‌شوند', () {
      expect(TextNormalizer.stripEndPunctuation('I am happy.'), 'I am happy');
      expect(TextNormalizer.stripEndPunctuation('آیا آماده‌ای؟'), 'آیا آماده‌ای');
      expect(TextNormalizer.stripEndPunctuation('چه خبر...'), 'چه خبر');
      expect(TextNormalizer.stripEndPunctuation('بدون نشانه'), 'بدون نشانه');
    });
  });
}
