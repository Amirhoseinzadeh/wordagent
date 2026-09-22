import 'package:flutter/foundation.dart';

/// فرستنده‌ی پیام در گفت‌وگوی آموزشی.
enum ChatAuthor { user, tutor }

/// یک پیام در گفت‌وگو با دستیار هوشمند.
@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.author,
    required this.text,
    required this.createdAt,
    this.wordId,
    this.suggestions = const <String>[],
    this.isFallback = false,
  });

  final String id;
  final ChatAuthor author;
  final String text;
  final DateTime createdAt;

  /// اگر پیام درباره‌ی واژه‌ی خاصی باشد.
  final String? wordId;

  /// پیشنهادهای آماده برای پیام بعدی کاربر.
  final List<String> suggestions;

  /// آیا پاسخ با موتور محلی و بدون مدل ابری تولید شده است؟
  final bool isFallback;

  bool get isUser => author == ChatAuthor.user;

  ChatMessage copyWith({
    String? id,
    ChatAuthor? author,
    String? text,
    DateTime? createdAt,
    String? wordId,
    List<String>? suggestions,
    bool? isFallback,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      author: author ?? this.author,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      wordId: wordId ?? this.wordId,
      suggestions: suggestions ?? this.suggestions,
      isFallback: isFallback ?? this.isFallback,
    );
  }

  @override
  bool operator ==(Object other) => other is ChatMessage && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
