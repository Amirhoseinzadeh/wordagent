import '../../domain/entities/chat_message.dart';
import '../../domain/entities/review_state.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/word.dart';
import '../../domain/engines/ai_tutor_engine.dart';
import '../../domain/engines/weakness_engine.dart';
import '../../domain/repositories/ai_repository.dart';

/// دستیار آموزشی محلی (روی دستگاه، آفلاین).
///
/// چرا روی دستگاه؟ چون:
///  * پاسخ لحظه‌ای است و به اینترنت وابسته نیست،
///  * داده‌ی یادگیری کاربر از دستگاه بیرون نمی‌رود،
///  * و هزینه‌ی سرور برای هر پیام صفر است.
/// برای پاسخ‌های خلاقانه‌تر (مثال‌سازی آزاد، ترجمه‌ی فارسی متن)، در فاز
/// بک‌اند یک پیاده‌سازی دورکار از همین قرارداد اضافه می‌شود و در صورت
/// نبود اینترنت، همین موتور محلی پاسخ می‌دهد.
class LocalAiRepository implements AiRepository {
  LocalAiRepository({
    required List<Word> words,
    required Map<String, ReviewState> states,
    required UserProfile profile,
    WeaknessReport? weakness,
  })  : _words = words,
        _states = states,
        _profile = profile,
        _weakness = weakness ?? WeaknessReport.empty();

  final List<Word> _words;
  final Map<String, ReviewState> _states;
  final UserProfile _profile;
  final WeaknessReport _weakness;

  @override
  bool get isReady => _words.isNotEmpty;

  @override
  String get engineLabel => 'دستیار محلی واژه‌یار';

  AiTutorEngine _engine() => AiTutorEngine(
        words: _words,
        states: _states,
        profile: _profile,
        weakness: _weakness,
      );

  @override
  Future<AiReply> ask({
    required String message,
    Word? contextWord,
    List<ChatMessage> history = const <ChatMessage>[],
  }) async {
    // کمی تأخیر طبیعی تا حس گفت‌وگو حفظ شود (و رابط کاربری فرصت انیمیشن بگیرد).
    await Future<void>.delayed(const Duration(milliseconds: 280));
    return _engine().respond(message, contextWord: contextWord);
  }

  @override
  Future<String> buildExample(Word word) async {
    final reply = _engine().respond('برای ${word.term} مثال بساز');
    return reply.text;
  }

  @override
  Future<String> simplify(Word word) async {
    final reply = _engine().respond('${word.term} را ساده‌تر توضیح بده');
    return reply.text;
  }
}
