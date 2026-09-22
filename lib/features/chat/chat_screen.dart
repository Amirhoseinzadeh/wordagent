import 'package:flutter/material.dart';

import '../../core/di/app_container.dart';
import '../../core/routing/app_router.dart';
import '../../core/state/value_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/fa_format.dart';
import '../../domain/engines/ai_tutor_engine.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/word.dart';
import '../../l10n/strings.dart';
import '../../widgets/animations.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/states.dart';
import '../word_detail/word_detail_screen.dart';

/// گفت‌وگو با دستیار آموزشی: توضیح واژه، مثال تازه، ساده‌سازی معنی،
/// پیشنهاد تمرین و تحلیل نقطه‌ضعف.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.contextWord});

  /// اگر از صفحه‌ی یک واژه آمده باشیم، گفت‌وگو درباره‌ی همان واژه است.
  final Word? contextWord;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<String> _suggestions = <String>[...AiTutorEngine.defaultSuggestions];
  bool _thinking = false;
  Word? _contextWord;

  @override
  void initState() {
    super.initState();
    _contextWord = widget.contextWord;
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _thinking) return;
    final container = AppScope.of(context);
    _input.clear();
    setState(() => _thinking = true);
    _scrollToEnd();

    try {
      final reply = await container.controller.sendChatMessage(
        text,
        contextWord: _contextWord,
      );
      if (!mounted) return;
      setState(() {
        _thinking = false;
        if (reply.suggestions.isNotEmpty) {
          _suggestions
            ..clear()
            ..addAll(reply.suggestions);
        }
        if (reply.wordId != null) {
          _contextWord = container.controller.allWords.firstWhere(
            (word) => word.id == reply.wordId,
            orElse: () => _contextWord ?? container.controller.allWords.first,
          );
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _thinking = false);
      showToast(context, S.somethingWentWrong);
    }
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: AppDurations.normal,
        curve: AppDurations.standardCurve,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final container = AppScope.of(context);
    final palette = AppPalette.of(context);

    return StoreBuilder<List<ChatMessage>>(
      store: container.stores.chatStore,
      builder: (context, messages) {
        return AppScaffold(
          title: S.chatTitle,
          subtitle: widget.contextWord == null
              ? 'درباره‌ی هر واژه یا گرامر بپرس'
              : 'در حال گفت‌وگو درباره‌ی «${widget.contextWord!.term}»',
          showBack: true,
          padding: EdgeInsets.zero,
          actions: <Widget>[
            CircleIconButton(
              icon: Icons.delete_sweep_outlined,
              tooltip: S.chatClear,
              onPressed: messages.isEmpty
                  ? null
                  : () async {
                      await container.controller.clearChat();
                      if (!mounted) return;
                      showToast(context, 'گفت‌وگو پاک شد.');
                    },
            ),
          ],
          body: Column(
            children: <Widget>[
              if (_contextWord != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.xs,
                    AppSpacing.md,
                    0,
                  ),
                  child: AppCard(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    onTap: () => Navigator.of(context).push(
                      AppRouter.build<void>(
                        settings:
                            const RouteSettings(name: AppRoutes.wordDetail),
                        builder: (_) =>
                            WordDetailScreen(args: WordDetailArgs(word: _contextWord!)),
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.push_pin_rounded,
                          size: 16,
                          color: AppColors.brand,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'واژه‌ی گفت‌وگو: ${_contextWord!.term} — '
                            '${_contextWord!.primaryMeaning}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: palette.textSecondary,
                                    ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _contextWord = null),
                          child: const Text('برداشتن'),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: messages.isEmpty
                    ? _EmptyChat(onSuggestion: _send)
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm,
                          AppSpacing.md,
                          AppSpacing.md,
                        ),
                        itemCount: messages.length + (_thinking ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= messages.length) {
                            return const _TypingBubble();
                          }
                          final message = messages[index];
                          final isLast = index == messages.length - 1;
                          return _MessageBubble(
                            message: message,
                            showSuggestions: isLast && !message.isUser,
                            onSuggestion: _send,
                            onOpenWord: _openWord,
                          );
                        },
                      ),
              ),
              if (_suggestions.isNotEmpty)
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    children: <Widget>[
                      for (final suggestion in _suggestions)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 6),
                          child: TagChip(
                            label: suggestion,
                            color: AppColors.brand,
                            icon: Icons.bolt_rounded,
                            dense: true,
                            onTap: () => _send(suggestion),
                          ),
                        ),
                    ],
                  ),
                ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.xs,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: _input,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          decoration: InputDecoration(
                            hintText: S.chatHint,
                            filled: true,
                            fillColor: palette.surface,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              borderSide: BorderSide(color: palette.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              borderSide: BorderSide(color: palette.border),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      CircleIconButton(
                        icon: _thinking
                            ? Icons.hourglass_bottom_rounded
                            : Icons.send_rounded,
                        size: 46,
                        background: AppColors.brand,
                        foreground: Colors.white,
                        onPressed: _thinking ? null : () => _send(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openWord(Word word) {
    setState(() => _contextWord = word);
    Navigator.of(context).push(
      AppRouter.build<void>(
        settings: const RouteSettings(name: AppRoutes.wordDetail),
        builder: (_) => WordDetailScreen(args: WordDetailArgs(word: word)),
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({required this.onSuggestion});

  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: <Widget>[
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            alignment: Alignment.center,
            child: const Text('🤖', style: TextStyle(fontSize: 34)),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          S.chatWelcome,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: palette.textPrimary,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'می‌توانی معنی یک واژه را بپرسی، مثال تازه بخواهی، یا بگویی '
          '«نقاط ضعفم را نشان بده».',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: palette.textSecondary,
                height: 1.8,
              ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final suggestion in AiTutorEngine.defaultSuggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: AppCard(
              onTap: () => onSuggestion(suggestion),
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      suggestion,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: palette.textPrimary,
                          ),
                    ),
                  ),
                  Icon(Icons.chevron_left_rounded, color: palette.textTertiary),
                ],
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        InfoBanner(
          text: S.chatOfflineNote,
          icon: Icons.wifi_tethering_rounded,
          color: palette.info,
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.showSuggestions,
    required this.onSuggestion,
    required this.onOpenWord,
  });

  final ChatMessage message;
  final bool showSuggestions;
  final ValueChanged<String> onSuggestion;
  final ValueChanged<Word> onOpenWord;

  @override
  Widget build(BuildContext context) {
    final container = AppScope.maybeOf(context);
    final palette = AppPalette.of(context);
    final isUser = message.isUser;
    final word = _wordFor(container, message.wordId);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        // پیام کاربر راست‌چین و پاسخ استاد چپ‌چین می‌شود.
        children: <Widget>[
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              if (!isUser)
                Container(
                  width: 30,
                  height: 30,
                  margin: const EdgeInsetsDirectional.only(end: 6),
                  decoration: BoxDecoration(
                    gradient: AppColors.accentGradient,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text('🤖', style: TextStyle(fontSize: 15)),
                ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.brand : palette.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(AppRadius.md),
                      topRight: const Radius.circular(AppRadius.md),
                      bottomLeft: Radius.circular(isUser ? AppRadius.md : 4),
                      bottomRight: Radius.circular(isUser ? 4 : AppRadius.md),
                    ),
                    border: Border.all(
                      color: isUser ? AppColors.brand : palette.border,
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isUser ? Colors.white : palette.textPrimary,
                          height: 1.85,
                        ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 3, right: 36, left: 36),
            child: Text(
              _timeLabel(message),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: palette.textTertiary,
                    fontSize: 9,
                  ),
            ),
          ),
          if (word != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 36),
              child: AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 6,
                ),
                onTap: () => onOpenWord(word),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.menu_book_rounded,
                      size: 14,
                      color: AppColors.brand,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${word.term} — ${word.primaryMeaning}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: palette.textSecondary,
                          ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_left_rounded,
                      size: 15,
                      color: AppColors.brand,
                    ),
                  ],
                ),
              ),
            ),
          if (showSuggestions && message.suggestions.isNotEmpty) ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 36),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  for (final suggestion in message.suggestions.take(3))
                    TagChip(
                      label: suggestion,
                      color: AppColors.info,
                      dense: true,
                      onTap: () => onSuggestion(suggestion),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Word? _wordFor(AppContainer? container, String? id) {
    if (container == null || id == null) return null;
    for (final word in container.controller.allWords) {
      if (word.id == id) return word;
    }
    return null;
  }

  static String _timeLabel(ChatMessage message) {
    final hour = message.createdAt.hour.toString().padLeft(2, '0');
    final minute = message.createdAt.minute.toString().padLeft(2, '0');
    return FaFormat.digits('$hour:$minute');
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsetsDirectional.only(end: 6),
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text('🤖', style: TextStyle(fontSize: 15)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              children: <Widget>[
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  S.chatThinking,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: palette.textTertiary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
