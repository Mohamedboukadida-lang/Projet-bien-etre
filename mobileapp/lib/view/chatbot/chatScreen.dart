import 'package:fitnessapp/config/api_config.dart';
import 'package:fitnessapp/service/HydrationService.dart';
import 'package:fitnessapp/service/chat_service.dart';
import 'package:fitnessapp/utils/app_colors.dart';
import 'package:flutter/material.dart';

/// AI well-being coach backed by the AI service (Hugging Face chat model).
class ChatScreen extends StatefulWidget {
  static String routeName = "/Chatbot";

  const ChatScreen({super.key, this.chatService, this.hydrationService});

  /// Injectable for tests; defaults to the real services.
  final ChatService? chatService;
  final HydrationService? hydrationService;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const List<String> _suggestions = [
    "How much water should I drink today?",
    "Tips to fall asleep faster",
    "A 5-minute breathing exercise",
    "Healthy snack ideas after a workout",
  ];

  late final ChatService _chatService = widget.chatService ?? ChatService();
  late final HydrationService _hydrationService =
      widget.hydrationService ?? HydrationService();

  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<ChatMessage> _messages = [];

  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Facts the coach can use to personalise answers. Failures are ignored:
  /// the chat still works when the hydration service is down.
  Future<String?> _userContext() async {
    try {
      final results = await Future.wait([
        _hydrationService.fetchCurrentIntake(ApiConfig.userId),
        _hydrationService.fetchDailyGoal(ApiConfig.userId),
      ]);
      return "Water drunk today: ${results[0].toStringAsFixed(2)} L; "
          "daily hydration goal: ${results[1].toStringAsFixed(2)} L.";
    } catch (_) {
      return null;
    }
  }

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _sending) return;
    _input.clear();
    setState(() {
      _messages.add(ChatMessage.user(trimmed));
      _error = null;
    });
    await _requestReply();
  }

  Future<void> _requestReply() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    _scrollToBottom();
    try {
      final context = await _userContext();
      final reply =
          await _chatService.send(List.of(_messages), context: context);
      if (!mounted) return;
      setState(() => _messages.add(ChatMessage.assistant(reply)));
    } on ChatException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut);
      }
    });
  }

  void _clear() {
    setState(() {
      _messages.clear();
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrayColor,
      appBar: AppBar(
        elevation: 0,
        foregroundColor: AppColors.whiteColor,
        flexibleSpace: Container(
          decoration:
              const BoxDecoration(gradient: LinearGradient(colors: [AppColors.primaryColor1, AppColors.primaryColor2])),
        ),
        title: const Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white24,
              child: Icon(Icons.spa_rounded, color: AppColors.whiteColor),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Well-Being Coach",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.whiteColor)),
                Text("AI assistant · not medical advice",
                    style:
                        TextStyle(fontSize: 11, color: AppColors.whiteColor)),
              ],
            ),
          ],
        ),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              tooltip: "New conversation",
              onPressed: _sending ? null : _clear,
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? _WelcomeView(suggestions: _suggestions, onTap: _send)
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                      itemCount: _messages.length +
                          (_sending ? 1 : 0) +
                          (_error != null ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < _messages.length) {
                          return _MessageBubble(message: _messages[index]);
                        }
                        if (_sending) return const _TypingBubble();
                        return _ErrorBubble(
                            message: _error!, onRetry: _requestReply);
                      },
                    ),
            ),
            _InputBar(
              controller: _input,
              enabled: !_sending,
              onSend: () => _send(_input.text),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeView extends StatelessWidget {
  const _WelcomeView({required this.suggestions, required this.onTap});

  final List<String> suggestions;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: AppColors.secondaryG),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.spa_rounded,
                color: AppColors.whiteColor, size: 36),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "Hi! I'm your well-being coach.",
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.blackColor),
        ),
        const SizedBox(height: 8),
        const Text(
          "Ask me about hydration, sleep, exercise, stress or healthy habits. "
          "I can see today's water intake to personalise my tips.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.grayColor),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final s in suggestions)
              ActionChip(
                label: Text(s),
                labelStyle: const TextStyle(
                    color: AppColors.primaryColor1, fontSize: 13),
                backgroundColor: AppColors.whiteColor,
                side: const BorderSide(color: AppColors.primaryColor1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                onPressed: () => onTap(s),
              ),
          ],
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    // Models often emit Markdown bold markers; show plain text instead.
    final text = message.content.replaceAll('**', '');
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          decoration: BoxDecoration(
            gradient: isUser ? LinearGradient(colors: AppColors.primaryG) : null,
            color: isUser ? null : AppColors.whiteColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isUser ? 18 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 18),
            ),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
            ],
          ),
          child: SelectableText(
            text,
            style: TextStyle(
              color: isUser ? AppColors.whiteColor : AppColors.blackColor,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))
    ..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        key: const Key('typing-indicator'),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final t = (_controller.value * 3 - i).clamp(0.0, 1.0);
              final opacity = 0.3 + 0.7 * (1 - (2 * t - 1).abs());
              return Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor1.withValues(alpha: opacity),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _ErrorBubble extends StatelessWidget {
  const _ErrorBubble({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(fontSize: 13, color: AppColors.blackColor)),
          ),
          TextButton(onPressed: onRetry, child: const Text("Retry")),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar(
      {required this.controller, required this.enabled, required this.onSend});

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: const BoxDecoration(
        color: AppColors.whiteColor,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              maxLength: 4000,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: "Ask your coach…",
                counterText: "",
                filled: true,
                fillColor: AppColors.lightGrayColor,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: enabled
                      ? AppColors.primaryG
                      : [AppColors.midGrayColor, AppColors.midGrayColor]),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              tooltip: "Send",
              onPressed: enabled ? onSend : null,
              icon: const Icon(Icons.send_rounded, color: AppColors.whiteColor),
            ),
          ),
        ],
      ),
    );
  }
}
