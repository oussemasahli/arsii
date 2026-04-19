import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/ai_tutor_service.dart';
import '../../../core/theme/app_colors.dart';
import '../models/lesson.dart';
import '../models/tutor_message.dart';

class AiTutorPanel extends StatefulWidget {
  final Lesson? lesson;

  const AiTutorPanel({
    super.key,
    this.lesson,
  });

  @override
  State<AiTutorPanel> createState() => _AiTutorPanelState();
}

class _AiTutorPanelState extends State<AiTutorPanel> {
  final _service = AiTutorService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  bool _expanded = false;
  bool _loading = false;
  bool _historyLoading = true;
  List<TutorMessage> _messages = [];

  static const _suggestions = [
    'Explain this simply',
    'Quiz me on this lesson',
    'Give me a hint',
    'What should I study next?',
    'Why was this answer wrong?',
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void didUpdateWidget(covariant AiTutorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lesson?.id != widget.lesson?.id) {
      _loadHistory();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _historyLoading = true);

    try {
      final history = await _service.loadMessages(lessonId: widget.lesson?.id, limit: 30);
      if (!mounted) return;
      setState(() {
        _messages = history;
        _historyLoading = false;
      });
      _jumpToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages = [];
        _historyLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      width: _expanded ? 360 : 42,
      decoration: BoxDecoration(
        color: AppColors.backgroundCard.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: _expanded ? _expandedBody() : _collapsedRail(),
    );
  }

  Widget _collapsedRail() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => setState(() => _expanded = true),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.smart_toy_rounded, color: AppColors.primary),
          SizedBox(height: 10),
          RotatedBox(
            quarterTurns: 3,
            child: Text(
              'AI Tutor',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _expandedBody() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              const Icon(Icons.smart_toy_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Tutor',
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      widget.lesson?.title ?? 'General lessons guidance',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _expanded = false),
                icon: const Icon(Icons.chevron_right_rounded),
              )
            ],
          ),
        ),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _suggestions
                .map((s) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        backgroundColor: AppColors.backgroundSubtle,
                        side: const BorderSide(color: AppColors.border),
                        label: Text(
                          s,
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        onPressed: _loading ? null : () => _sendMessage(prefill: s),
                      ),
                    ))
                .toList(),
          ),
        ),
        Expanded(
          child: _historyLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _messages.isEmpty
                  ? Center(
                      child: Text(
                        'Ask about this lesson to get personalized help.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(color: AppColors.textMuted),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return _bubble(message);
                      },
                    ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: GoogleFonts.inter(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Ask the tutor...',
                    hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.backgroundSubtle,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  onSubmitted: _loading ? null : (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _loading ? null : _sendMessage,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded, size: 17),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bubble(TutorMessage message) {
    final user = message.role == TutorRole.user;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 286),
        decoration: BoxDecoration(
          color: user ? AppColors.primary.withValues(alpha: 0.16) : AppColors.backgroundSubtle,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: user ? AppColors.primary.withValues(alpha: 0.36) : AppColors.border,
          ),
        ),
        child: Text(
          message.text,
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Future<void> _sendMessage({String? prefill}) async {
    final message = (prefill ?? _controller.text).trim();
    if (message.isEmpty) return;

    if (widget.lesson == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select or open a lesson first to give tutor better context.')),
      );
      return;
    }

    setState(() {
      _loading = true;
      if (prefill == null) {
        _controller.clear();
      }
      _messages = [
        ..._messages,
        TutorMessage(
          id: 'local_${DateTime.now().microsecondsSinceEpoch}',
          role: TutorRole.user,
          text: message,
          createdAt: DateTime.now(),
        ),
      ];
    });

    _jumpToBottom();

    final reply = await _service.askTutor(
      lesson: widget.lesson!,
      userMessage: message,
    );

    if (!mounted) return;

    setState(() {
      _loading = false;
      _messages = [..._messages, reply];
    });

    _jumpToBottom();
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }
}
