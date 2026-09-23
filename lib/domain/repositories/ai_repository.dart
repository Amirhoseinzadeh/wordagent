import '../entities/chat_message.dart';
import '../entities/word.dart';
import '../engines/ai_tutor_engine.dart';

/// قرارداد دستیار آموزشی.
///
/// پیاده‌سازی محلی (`LocalAiRepository`) روی دستگاه و آفلاین کار می‌کند.
/// در فاز بک‌اند می‌توان همان قرارداد را با یک پیاده‌سازی متصل به مدل زبانی
/// ابری جایگزین کرد؛ رابط کاربری تغییری نمی‌خواهد.
abstract class AiRepository {
  /// آیا دستیار آماده است؟
  bool get isReady;

  /// نام موتور پاسخ‌دهی (برای نمایش در رابط کاربری).
  String get engineLabel;

  /// پاسخ به پیام کاربر.
  Future<AiReply> ask({
    required String message,
    Word? contextWord,
    List<ChatMessage> history = const <ChatMessage>[],
  });

  /// ساخت مثال تازه در سطح کاربر (برای صفحه‌ی واژه).
  Future<String> buildExample(Word word);

  /// توضیح ساده‌تر یک واژه.
  Future<String> simplify(Word word);
}
