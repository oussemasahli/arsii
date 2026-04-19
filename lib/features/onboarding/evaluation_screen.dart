import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/data/mock_data.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/student_service.dart';
import '../../shared/widgets/abstract_background.dart';
import '../../shared/widgets/gradient_button.dart';
import '../dashboard/dashboard_screen.dart';

/// Onboarding Step 2 — AI-powered level evaluation with instant feedback.
class EvaluationScreen extends StatefulWidget {
  final List<Subject> selectedSubjects;
  const EvaluationScreen({super.key, required this.selectedSubjects});
  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen>
    with TickerProviderStateMixin {
  final _ai = AiService();
  final _studentService = StudentService();

  // State
  List<AiQuestion> _questions = [];
  bool _loading = true;
  String? _loadError;
  int _currentQ = 0;
  final Map<int, int> _answers = {};
  int? _selectedOption;    // currently selected but not yet confirmed
  bool _answered = false;  // whether current question has been answered
  EvaluationResult? _result;

  // Animations
  late AnimationController _fadeCtl;
  late Animation<double> _fadeIn;
  late AnimationController _shakeCtl;
  late Animation<double> _shakeAnim;
  late AnimationController _pulseCtl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeIn = CurvedAnimation(parent: _fadeCtl, curve: Curves.easeOut);
    _shakeCtl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _shakeCtl, curve: Curves.elasticIn));
    _pulseCtl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(CurvedAnimation(parent: _pulseCtl, curve: Curves.easeInOut));

    _fadeCtl.forward();
    _generateQuiz();
  }

  @override
  void dispose() {
    _fadeCtl.dispose();
    _shakeCtl.dispose();
    _pulseCtl.dispose();
    super.dispose();
  }

  Future<void> _generateQuiz() async {
    try {
      final subjectNames = widget.selectedSubjects.map((s) => s.name).toList();
      final questions = await _ai.generateQuiz(subjectNames);
      if (mounted) setState(() { _questions = questions; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loadError = e.toString(); _loading = false; });
    }
  }

  void _selectAnswer(int idx) {
    if (_answered) return;
    setState(() {
      _selectedOption = idx;
      _answered = true;
      _answers[_currentQ] = idx;
    });

    final isCorrect = idx == _questions[_currentQ].correctIndex;
    if (isCorrect) {
      _pulseCtl.forward().then((_) => _pulseCtl.reverse());
    } else {
      _shakeCtl.forward().then((_) => _shakeCtl.reset());
    }

    // Auto-advance after delay
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      if (_currentQ < _questions.length - 1) {
        setState(() { _currentQ++; _answered = false; _selectedOption = null; });
      } else {
        _showResults();
      }
    });
  }

  void _showResults() {
    final subjectNames = widget.selectedSubjects.map((s) => s.name).toList();
    final result = _ai.evaluateResults(
      questions: _questions,
      answers: _answers,
      subjectNames: subjectNames,
    );
    setState(() => _result = result);
  }

  bool _saving = false;

  void _goToDashboard() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      // Save evaluation results to Firestore with a timeout
      final subjectNames = widget.selectedSubjects.map((s) => s.name).toList();
      final subjectIds = widget.selectedSubjects.map((s) => s.id).toList();
      await _studentService.saveOnboardingResults(
        level: _result!.level,
        subjectScores: _result!.subjectScores,
        subjectNames: subjectNames,
        subjectIds: subjectIds,
      ).timeout(const Duration(seconds: 8));
    } catch (_) {
      // Even if Firestore save fails or times out, still navigate
    }

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
      (_) => false,
    );
  }

  bool _isDesktop(BuildContext c) => MediaQuery.of(c).size.width >= 960;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        const Positioned.fill(child: AbstractBackground()),
        SafeArea(child: FadeTransition(opacity: _fadeIn, child: _buildBody())),
      ]),
    );
  }

  Widget _buildBody() {
    if (_loading) return _loadingView();
    if (_loadError != null) return _errorView();
    if (_result != null) return _resultsView();
    return _quizView();
  }

  // ── Loading ───────────────────────────────────────────────────
  Widget _loadingView() => Center(child: Column(
    mainAxisSize: MainAxisSize.min, children: [
      const SizedBox(width: 48, height: 48, child: CircularProgressIndicator(
        color: AppColors.primary, strokeWidth: 2.5)),
      const SizedBox(height: 24),
      Text('Generating your personalized quiz...', style: GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      Text('Our AI is crafting questions based on your selected subjects',
        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
    ],
  ));

  Widget _errorView() => Center(child: Column(
    mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline, color: AppColors.error, size: 48),
      const SizedBox(height: 16),
      Text('Failed to generate quiz', style: GoogleFonts.inter(
        fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      Text(_loadError!, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
      const SizedBox(height: 24),
      GradientButton(label: 'Retry', icon: Icons.refresh_rounded,
        onPressed: () { setState(() { _loading = true; _loadError = null; }); _generateQuiz(); }),
    ],
  ));

  // ── Quiz ──────────────────────────────────────────────────────
  Widget _quizView() {
    final isD = _isDesktop(context);
    final q = _questions[_currentQ];
    final progress = (_currentQ + 1) / _questions.length;

    return Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 900),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isD ? 32 : 20, vertical: 16),
        child: Column(children: [
          _stepBar(),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: progress, minHeight: 4,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary))),
          const SizedBox(height: 8),
          Row(children: [
            Text('Question ${_currentQ + 1} of ${_questions.length}',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.secondary.withOpacity(0.2))),
              child: Text(q.subject, style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.secondary)),
            ),
          ]),
          const SizedBox(height: 20),
          Expanded(child: isD
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (isD) SizedBox(width: 200, child: _sideProgress()),
                if (isD) const SizedBox(width: 28),
                Expanded(child: _questionCard(q)),
              ])
            : SingleChildScrollView(child: _questionCard(q))),
        ]),
      ),
    ));
  }

  Widget _questionCard(AiQuestion q) {
    final isCorrect = _answered && _selectedOption == q.correctIndex;
    final isWrong = _answered && _selectedOption != q.correctIndex;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.backgroundCard,
        border: Border.all(color: _answered
          ? (isCorrect ? AppColors.success.withOpacity(0.4) : AppColors.error.withOpacity(0.4))
          : AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 4)),
          if (_answered && isCorrect)
            BoxShadow(color: AppColors.success.withOpacity(0.1), blurRadius: 24, spreadRadius: -4),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(q.question, style: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.4)),
        const SizedBox(height: 24),
        ...List.generate(q.options.length, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _OptionTile(
            label: q.options[i],
            index: i,
            selected: _selectedOption == i,
            answered: _answered,
            isCorrectAnswer: i == q.correctIndex,
            wasChosen: _selectedOption == i,
            onTap: () => _selectAnswer(i),
            shakeAnimation: (_selectedOption == i && _answered && i != q.correctIndex) ? _shakeAnim : null,
            pulseAnimation: (i == q.correctIndex && _answered) ? _pulseAnim : null,
          ),
        )),
        // Explanation after answering
        if (_answered) ...[
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isCorrect
                ? AppColors.success.withOpacity(0.08)
                : AppColors.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isCorrect
                ? AppColors.success.withOpacity(0.2)
                : AppColors.error.withOpacity(0.2)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(isCorrect ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                size: 18, color: isCorrect ? AppColors.success : AppColors.error),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(isCorrect ? 'Correct!' : 'Incorrect',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700,
                    color: isCorrect ? AppColors.success : AppColors.error)),
                const SizedBox(height: 4),
                Text(q.explanation, style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
              ])),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _sideProgress() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text("Let's assess your\ncurrent level",
      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800,
        color: AppColors.textPrimary, height: 1.2)),
    const SizedBox(height: 16),
    ...List.generate(_questions.length, (i) {
      final answered = _answers.containsKey(i);
      final correct = answered && _answers[i] == _questions[i].correctIndex;
      final isCurrent = i == _currentQ;
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCurrent ? AppColors.primary
                : answered ? (correct ? AppColors.success : AppColors.error).withOpacity(0.15)
                : AppColors.backgroundSubtle,
              border: Border.all(color: isCurrent ? AppColors.primary
                : answered ? (correct ? AppColors.success : AppColors.error)
                : AppColors.border),
            ),
            alignment: Alignment.center,
            child: answered
              ? Icon(correct ? Icons.check_rounded : Icons.close_rounded,
                  size: 14, color: correct ? AppColors.success : AppColors.error)
              : Text('${i + 1}', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600,
                  color: isCurrent ? AppColors.textOnPrimary : AppColors.textMuted)),
          ),
          const SizedBox(width: 8),
          if (i < _questions.length)
            Expanded(child: Text(_questions[i].subject, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted))),
        ]),
      );
    }),
  ]);

  Widget _stepBar() => Row(children: [
    _StepDot(label: '1', title: 'Choose', active: false, done: true),
    Expanded(child: Container(height: 1, color: AppColors.primary.withOpacity(0.3))),
    _StepDot(label: '2', title: 'Evaluate', active: true, done: false),
    Expanded(child: Container(height: 1, color: AppColors.border)),
    _StepDot(label: '3', title: 'Dashboard', active: false, done: false),
  ]);

  // ── Results ───────────────────────────────────────────────────
  Widget _resultsView() {
    final r = _result!;
    final levelColor = r.level == 'Advanced' ? AppColors.success
        : r.level == 'Intermediate' ? AppColors.primary : AppColors.secondary;

    return Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(children: [
          // Level badge
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: levelColor.withOpacity(0.1),
              border: Border.all(color: levelColor.withOpacity(0.4), width: 3),
              boxShadow: [BoxShadow(color: levelColor.withOpacity(0.15), blurRadius: 32)],
            ),
            child: Icon(
              r.level == 'Advanced' ? Icons.emoji_events_rounded
                : r.level == 'Intermediate' ? Icons.trending_up_rounded : Icons.school_rounded,
              color: levelColor, size: 48),
          ),
          const SizedBox(height: 24),
          Text('Your Level: ${r.level}', style: GoogleFonts.inter(
            fontSize: 28, fontWeight: FontWeight.w800, color: levelColor)),
          const SizedBox(height: 12),
          Text(r.summary, textAlign: TextAlign.center, style: GoogleFonts.inter(
            fontSize: 15, color: AppColors.textSecondary, height: 1.6)),
          const SizedBox(height: 28),

          // Score card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border)),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _scoreStat('Score', '${(r.percentage * 100).toInt()}%', levelColor),
                Container(width: 1, height: 40, color: AppColors.border),
                _scoreStat('Correct', '${r.correctAnswers}/${r.totalQuestions}', AppColors.success),
              ]),
              const SizedBox(height: 20),
              // Per-subject breakdown
              ...r.subjectScores.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(e.key, style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.textPrimary))),
                    Text('${(e.value * 100).toInt()}%', style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: e.value >= 0.6 ? AppColors.success : AppColors.error)),
                  ]),
                  const SizedBox(height: 4),
                  ClipRRect(borderRadius: BorderRadius.circular(4),
                    child: Stack(children: [
                      Container(height: 5, color: AppColors.border.withOpacity(0.3)),
                      FractionallySizedBox(widthFactor: e.value,
                        child: Container(height: 5, decoration: BoxDecoration(
                          color: e.value >= 0.6 ? AppColors.success : AppColors.error,
                          borderRadius: BorderRadius.circular(4)))),
                    ])),
                ]),
              )),
            ]),
          ),
          const SizedBox(height: 32),
          GradientButton(label: 'Go to My Dashboard', icon: Icons.auto_awesome_rounded,
            onPressed: _goToDashboard),
        ]),
      ),
    ));
  }

  Widget _scoreStat(String label, String value, Color color) => Column(children: [
    Text(value, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
    const SizedBox(height: 4),
    Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
  ]);
}

// ═══════════════════════════════════════════════════════════════════
// Option tile with correct/wrong animations
// ═══════════════════════════════════════════════════════════════════
class _OptionTile extends StatefulWidget {
  final String label;
  final int index;
  final bool selected;
  final bool answered;
  final bool isCorrectAnswer;
  final bool wasChosen;
  final VoidCallback onTap;
  final Animation<double>? shakeAnimation;
  final Animation<double>? pulseAnimation;

  const _OptionTile({
    required this.label, required this.index, required this.selected,
    required this.answered, required this.isCorrectAnswer,
    required this.wasChosen, required this.onTap,
    this.shakeAnimation, this.pulseAnimation,
  });

  @override
  State<_OptionTile> createState() => _OptionTileState();
}

class _OptionTileState extends State<_OptionTile> {
  bool _hovered = false;
  static const _letters = ['A', 'B', 'C', 'D'];

  Color get _borderColor {
    if (!widget.answered) return _hovered ? AppColors.borderLight : AppColors.border;
    if (widget.isCorrectAnswer) return AppColors.success.withOpacity(0.6);
    if (widget.wasChosen) return AppColors.error.withOpacity(0.6);
    return AppColors.border;
  }

  Color get _bgColor {
    if (!widget.answered) return AppColors.backgroundSubtle;
    if (widget.isCorrectAnswer) return AppColors.success.withOpacity(0.08);
    if (widget.wasChosen) return AppColors.error.withOpacity(0.08);
    return AppColors.backgroundSubtle;
  }

  Color get _circleColor {
    if (!widget.answered) return widget.selected ? AppColors.primary : AppColors.backgroundElevated;
    if (widget.isCorrectAnswer) return AppColors.success;
    if (widget.wasChosen) return AppColors.error;
    return AppColors.backgroundElevated;
  }

  @override
  Widget build(BuildContext context) {
    Widget tile = MouseRegion(
      onEnter: (_) { if (!widget.answered) setState(() => _hovered = true); },
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.answered ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.answered ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: _bgColor,
            border: Border.all(color: _borderColor, width: widget.answered && (widget.isCorrectAnswer || widget.wasChosen) ? 1.5 : 1),
          ),
          child: Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle, color: _circleColor,
                border: Border.all(color: _circleColor)),
              alignment: Alignment.center,
              child: widget.answered && widget.isCorrectAnswer
                ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                : widget.answered && widget.wasChosen && !widget.isCorrectAnswer
                  ? const Icon(Icons.close_rounded, size: 16, color: Colors.white)
                  : Text(_letters[widget.index], style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: widget.selected ? AppColors.textOnPrimary : AppColors.textMuted)),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(widget.label, style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: widget.answered && widget.isCorrectAnswer ? FontWeight.w700 : FontWeight.w400,
              color: widget.answered && widget.isCorrectAnswer ? AppColors.success
                : widget.answered && widget.wasChosen ? AppColors.error
                : AppColors.textSecondary))),
            if (widget.answered && widget.isCorrectAnswer)
              const Icon(Icons.check_circle_rounded, size: 20, color: AppColors.success),
            if (widget.answered && widget.wasChosen && !widget.isCorrectAnswer)
              const Icon(Icons.cancel_rounded, size: 20, color: AppColors.error),
          ]),
        ),
      ),
    );

    // Shake animation for wrong answer
    if (widget.shakeAnimation != null && widget.wasChosen && !widget.isCorrectAnswer) {
      tile = AnimatedBuilder(
        animation: widget.shakeAnimation!,
        builder: (ctx, child) {
          final t = widget.shakeAnimation!.value;
          return Transform.translate(
            offset: Offset(sin(t * pi * 4) * 8 * (1 - t), 0),
            child: child,
          );
        },
        child: tile,
      );
    }

    // Pulse animation for correct answer
    if (widget.pulseAnimation != null && widget.isCorrectAnswer && widget.answered) {
      tile = AnimatedBuilder(
        animation: widget.pulseAnimation!,
        builder: (ctx, child) => Transform.scale(scale: widget.pulseAnimation!.value, child: child),
        child: tile,
      );
    }

    return tile;
  }
}

class _StepDot extends StatelessWidget {
  final String label, title;
  final bool active, done;
  const _StepDot({required this.label, required this.title, required this.active, required this.done});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? AppColors.primary : done ? AppColors.primary.withOpacity(0.15) : AppColors.backgroundElevated,
          border: Border.all(color: active || done ? AppColors.primary : AppColors.border, width: 2)),
        alignment: Alignment.center,
        child: done
          ? const Icon(Icons.check_rounded, size: 14, color: AppColors.primary)
          : Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700,
              color: active ? AppColors.textOnPrimary : AppColors.textMuted)),
      ),
      const SizedBox(height: 4),
      Text(title, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500,
        color: active ? AppColors.primary : done ? AppColors.textSecondary : AppColors.textMuted)),
    ]);
  }
}
