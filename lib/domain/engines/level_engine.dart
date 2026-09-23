import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../entities/cefr_level.dart';
import '../entities/quiz_question.dart';
import '../entities/word.dart';
import 'quiz_engine.dart';

/// نتیجه‌ی آزمون تعیین سطح.
@immutable
class PlacementResult {
  const PlacementResult({
    required this.level,
    required this.ability,
    required this.score,
    required this.correctCount,
    required this.totalQuestions,
    required this.confidence,
  });

  final CefrLevel level;

  /// توانایی برآوردشده روی مقیاس ۱ (A1) تا ۶ (C2).
  final double ability;

  /// امتیاز ۰ تا ۱۰۰ برای نمایش در صفحه‌ی نتیجه.
  final int score;

  final int correctCount;
  final int totalQuestions;

  /// میزان اطمینان آزمون (۰ تا ۱).
  final double confidence;

  String get summaryFa {
    if (score >= 80) {
      return 'تسلط تو عالی است؛ تمرکز برنامه روی واژگان ظریف و اصطلاحات خواهد بود.';
    }
    if (score >= 60) {
      return 'پایه‌ات محکم است؛ روی واژه‌های کم‌کاربردتر و کالوکیشن‌ها کار می‌کنیم.';
    }
    if (score >= 35) {
      return 'خوب پیش می‌روی؛ برنامه از واژه‌های پرکاربرد روزمره شروع و پله‌پله جلو می‌رود.';
    }
    return 'از پایه شروع می‌کنیم و با تمرین کوتاه روزانه، خیلی سریع پیشرفت را می‌بینی.';
  }
}

/// موتور آزمون تعیین سطح تطبیقی.
///
/// روش: مدل ساده‌ی «Elo/Rasch» — هر واژه یک دشواری ۱ تا ۶ دارد و بعد از
/// هر پاسخ، توانایی کاربر به‌سمت نتیجه‌ی واقعی حرکت می‌کند. انتخاب سؤال بعدی
/// نزدیک‌ترین دشواری به توانایی فعلی است (تست تطبیقی)، بنابراین با ۱۲ تا ۲۰
/// سؤال می‌توان سطح کاربر را با دقت خوبی تخمین زد — بدون آن‌که سؤال‌های
/// بسیار ساده یا بسیار سخت، کاربر را بی‌انگیزه کند.
class PlacementEngine {
  PlacementEngine({
    required List<Word> words,
    QuizFactory? factory,
    math.Random? random,
    this.maxQuestions = 18,
  })  : _bank = words.where((w) => w.faMeanings.isNotEmpty).toList(growable: false),
        _factory = factory ?? QuizFactory(random: random),
        _random = random ?? math.Random() {
    _ability = _initialAbility;
  }

  final List<Word> _bank;
  final QuizFactory _factory;
  final math.Random _random;
  final int maxQuestions;

  final Set<String> _askedIds = <String>{};
  final List<bool> _history = <bool>[];
  late double _ability;
  QuizQuestion? _current;

  /// توانایی تخمینی جاری (۱ تا ۶).
  double get ability => _ability;

  int get answeredCount => _history.length;

  int get correctCount => _history.where((value) => value).length;

  bool get isFinished => answeredCount >= maxQuestions || _bank.isEmpty;

  double get progress =>
      maxQuestions == 0 ? 0 : (answeredCount / maxQuestions).clamp(0.0, 1.0);

  /// اگر بانک واژه خالی باشد، آزمون معنی ندارد.
  bool get isUsable => _bank.length >= 8;

  /// سؤال جاری (به‌صورت تنبل ساخته می‌شود).
  QuizQuestion? get currentQuestion {
    if (isFinished && _current == null) return null;
    _current ??= _pickQuestion();
    return _current;
  }

  /// پاسخ سؤال جاری را ثبت می‌کند.
  void submit({required bool isCorrect}) {
    final question = _current;
    if (question == null) return;
    _history.add(isCorrect);
    _updateAbility(isCorrect: isCorrect, difficulty: _difficultyOf(question.word));
    _askedIds.add(question.word.id);
    _current = null;
  }

  /// پایان آزمون و ساخت نتیجه.
  PlacementResult get result {
    final level = _levelForAbility(_ability);
    final score = ((_ability - 1) / 5 * 100).clamp(0, 100).round();
    final confidence = (answeredCount / 12).clamp(0.0, 1.0);
    return PlacementResult(
      level: level,
      ability: _ability,
      score: score,
      correctCount: correctCount,
      totalQuestions: answeredCount,
      confidence: confidence,
    );
  }

  // --------------------------------------------------------------- داخلی

  double get _initialAbility {
    // شروع از سطح متوسط‌پایین (A2/B1) و تطبیق سریع در دو سؤال اول.
    if (_bank.isEmpty) return 2.0;
    final average = _bank
            .map((word) => _difficultyOf(word))
            .reduce((a, b) => a + b) /
        _bank.length;
    return average.clamp(1.5, 4.0);
  }

  double _difficultyOf(Word word) => word.level.difficulty.toDouble();

  static const double _slope = 1.1;

  void _updateAbility({required bool isCorrect, required double difficulty}) {
    final expected = 1 / (1 + math.exp(-(_ability - difficulty) * _slope));
    final actual = isCorrect ? 1.0 : 0.0;
    // نرخ یادگیری در ابتدا بزرگ‌تر و در ادامه کوچک‌تر می‌شود.
    final progressRatio = answeredCount / maxQuestions;
    final learningRate = 0.95 - 0.45 * progressRatio;
    _ability = (_ability + learningRate * (actual - expected)).clamp(1.0, 6.0);
  }

  QuizQuestion? _pickQuestion() {
    if (_bank.isEmpty) return null;
    final target = _ability + (_random.nextDouble() - 0.5) * 0.5;
    final candidates = _bank
        .where((word) => !_askedIds.contains(word.id))
        .toList(growable: false);
    if (candidates.isEmpty) return null;

    candidates.sort((a, b) {
      final da = (_difficultyOf(a) - target).abs();
      final db = (_difficultyOf(b) - target).abs();
      if (da != db) return da.compareTo(db);
      return a.frequencyRank.compareTo(b.frequencyRank);
    });

    // از میان چند گزینه‌ی نزدیک، یکی را تصادفی برمی‌گزینیم تا آزمون
    // در هر اجرا تازه باشد.
    final window = candidates.take(math.min(5, candidates.length)).toList(growable: false);
    final word = window[_random.nextInt(window.length)];
    return _factory.build(
      word: word,
      type: QuizType.meaningChoice,
      pool: _bank,
    );
  }

  static CefrLevel _levelForAbility(double ability) {
    if (ability < 1.55) return CefrLevel.a1;
    if (ability < 2.35) return CefrLevel.a2;
    if (ability < 3.3) return CefrLevel.b1;
    if (ability < 4.3) return CefrLevel.b2;
    if (ability < 5.3) return CefrLevel.c1;
    return CefrLevel.c2;
  }
}
