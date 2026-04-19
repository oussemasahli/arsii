import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/exercise_service.dart';
import '../../core/theme/app_colors.dart';
import '../lessons/models/lesson.dart';
import 'models/exercise.dart';
import 'models/exercise_attempt.dart';

class ExercisesScreen extends StatefulWidget {
  final Lesson lesson;

  const ExercisesScreen({
    super.key,
    required this.lesson,
  });

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  final _service = ExerciseService();
  final _shortAnswerController = TextEditingController();

  bool _loading = true;
  String? _error;
  List<Exercise> _exercises = const [];

  int _index = 0;
  String _sessionId = '';
  bool _submitted = false;
  bool _submitting = false;
  String? _selectedAnswer;
  ExerciseEvaluation? _feedback;

  final Map<String, String> _answers = {};
  final Map<String, ExerciseEvaluation> _evaluations = {};

  bool _sessionCompleted = false;
  ExerciseSessionResult? _sessionResult;

  @override
  void initState() {
    super.initState();
    _sessionId = 'sess_${widget.lesson.id}_${DateTime.now().millisecondsSinceEpoch}';
    _loadExercises();
  }

  @override
  void dispose() {
    _shortAnswerController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await _service.loadExercisesForLesson(lesson: widget.lesson, minCount: 5);
      if (!mounted) return;
      setState(() {
        _exercises = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load exercises. $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _ScaffoldShell(
        lesson: widget.lesson,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_error != null) {
      return _ScaffoldShell(
        lesson: widget.lesson,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _loadExercises,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_sessionCompleted && _sessionResult != null) {
      return _ScaffoldShell(
        lesson: widget.lesson,
        child: _buildSummary(_sessionResult!),
      );
    }

    if (_exercises.isEmpty) {
      return _ScaffoldShell(
        lesson: widget.lesson,
        child: Center(
          child: Text(
            'No exercises available for this lesson yet.',
            style: GoogleFonts.inter(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final exercise = _exercises[_index];
    final progress = (_index + 1) / _exercises.length;

    return _ScaffoldShell(
      lesson: widget.lesson,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _lessonHeader(progress),
            const SizedBox(height: 16),
            _questionCard(exercise),
            const SizedBox(height: 14),
            _answerInput(exercise),
            const SizedBox(height: 12),
            _actionBar(exercise),
            if (_feedback != null) ...[
              const SizedBox(height: 14),
              _feedbackCard(_feedback!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _lessonHeader(double progress) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.14),
            AppColors.secondary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.lesson.title,
            style: GoogleFonts.inter(
              fontSize: 22,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Question ${_index + 1} of ${_exercises.length}',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _questionCard(Exercise exercise) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: AppColors.backgroundSubtle,
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              '${exercise.skill.isNotEmpty ? exercise.skill : widget.lesson.skill} • ${_exerciseLabel(exercise.type)}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            exercise.question,
            style: GoogleFonts.inter(
              fontSize: 18,
              height: 1.35,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _answerInput(Exercise exercise) {
    if (exercise.type == ExerciseType.shortAnswer) {
      return TextField(
        controller: _shortAnswerController,
        minLines: 3,
        maxLines: 6,
        style: GoogleFonts.inter(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Write your answer in your own words...',
          hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
          filled: true,
          fillColor: AppColors.backgroundCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
      );
    }

    return Column(
      children: exercise.options.map((option) {
        final isSelected = _selectedAnswer == option.text;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _submitted
                ? null
                : () {
                    setState(() {
                      _selectedAnswer = option.text;
                    });
                  },
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.16)
                    : AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSubtle,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      option.id,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      option.text,
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _actionBar(Exercise exercise) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: _submitted || _submitting ? null : () => _submitAnswer(exercise),
          icon: _submitting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_circle_outline_rounded),
          label: const Text('Submit Answer'),
        ),
        OutlinedButton.icon(
          onPressed: _submitting ? null : () => _askHint(exercise),
          icon: const Icon(Icons.tips_and_updates_outlined),
          label: const Text('Need a hint?'),
        ),
        if (_submitted)
          OutlinedButton.icon(
            onPressed: _nextQuestion,
            icon: Icon(_index == _exercises.length - 1
                ? Icons.emoji_events_rounded
                : Icons.arrow_forward_rounded),
            label: Text(_index == _exercises.length - 1 ? 'Finish Session' : 'Next Question'),
          ),
      ],
    );
  }

  Widget _feedbackCard(ExerciseEvaluation feedback) {
    final color = feedback.isCorrect ? AppColors.success : AppColors.warning;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                feedback.isCorrect ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                feedback.isCorrect ? 'Correct' : 'Not quite yet',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                'Score ${(feedback.score * 100).round()}%',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            feedback.explanation,
            style: GoogleFonts.inter(color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 6),
          Text(
            feedback.feedback,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAnswer(Exercise exercise) async {
    final answer = exercise.type == ExerciseType.shortAnswer
        ? _shortAnswerController.text.trim()
        : (_selectedAnswer ?? '').trim();

    if (answer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide an answer first.')),
      );
      return;
    }

    setState(() => _submitting = true);

    final evaluation = await _service.evaluateAnswer(
      exercise: exercise,
      userAnswer: answer,
      lesson: widget.lesson,
    );

    await _service.saveAttempt(
      sessionId: _sessionId,
      exercise: exercise,
      userAnswer: answer,
      evaluation: evaluation,
    );

    if (!mounted) return;

    setState(() {
      _submitting = false;
      _submitted = true;
      _feedback = evaluation;
      _answers[exercise.id] = answer;
      _evaluations[exercise.id] = evaluation;
    });
  }

  Future<void> _askHint(Exercise exercise) async {
    final hint = await _service.getHint(exercise: exercise, lesson: widget.lesson);
    if (!mounted) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hint',
              style: GoogleFonts.inter(
                fontSize: 18,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hint,
              style: GoogleFonts.inter(color: AppColors.textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _nextQuestion() async {
    if (_index == _exercises.length - 1) {
      await _finishSession();
      return;
    }

    final next = _index + 1;
    final nextExercise = _exercises[next];

    setState(() {
      _index = next;
      _submitted = _evaluations.containsKey(nextExercise.id);
      _feedback = _evaluations[nextExercise.id];
      _selectedAnswer = _answers[nextExercise.id];
      _shortAnswerController.text = _answers[nextExercise.id] ?? '';
    });
  }

  Future<void> _finishSession() async {
    final total = _exercises.length;
    final results = _exercises
        .where((e) => _evaluations.containsKey(e.id))
        .map((e) => MapEntry(e, _evaluations[e.id]!))
        .toList();

    final correct = results.where((entry) => entry.value.isCorrect).length;
    final totalScore = results.fold<double>(0, (sum, entry) => sum + entry.value.score);

    final mistakesByConcept = <String, int>{};
    for (final entry in results) {
      if (entry.value.isCorrect) continue;
      final skill = entry.key.skill.isNotEmpty ? entry.key.skill : 'General';
      mistakesByConcept[skill] = (mistakesByConcept[skill] ?? 0) + 1;
    }

    final weakAreas = mistakesByConcept.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final result = ExerciseSessionResult(
      sessionId: _sessionId,
      lessonId: widget.lesson.id,
      topicId: widget.lesson.topicId,
      totalQuestions: total,
      correctAnswers: correct,
      totalScore: total == 0 ? 0 : totalScore / total,
      mistakesByConcept: mistakesByConcept,
      weakAreas: weakAreas.take(3).map((e) => e.key).toList(),
      recommendedNextAction: weakAreas.isEmpty
          ? 'Advance to the next lesson and keep the momentum.'
          : 'Review ${weakAreas.first.key} and retry one focused exercise set.',
    );

    await _service.saveSessionResult(result);

    if (!mounted) return;
    setState(() {
      _sessionCompleted = true;
      _sessionResult = result;
    });
  }

  Widget _buildSummary(ExerciseSessionResult result) {
    final accuracy = (result.accuracy * 100).round();
    final finalScore = (result.totalScore * 100).round();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [
                  AppColors.success.withValues(alpha: 0.2),
                  AppColors.primary.withValues(alpha: 0.14),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Session Complete',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Final score: $finalScore% • Accuracy: $accuracy% • ${result.correctAnswers}/${result.totalQuestions} correct',
                  style: GoogleFonts.inter(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _summarySection(
            'Weak areas detected',
            result.weakAreas.isEmpty
                ? ['No major weak areas detected. Great consistency.']
                : result.weakAreas,
          ),
          const SizedBox(height: 10),
          _summarySection(
            'Mistakes by concept',
            result.mistakesByConcept.isEmpty
                ? ['No concept-level mistakes in this session.']
                : result.mistakesByConcept.entries
                    .map((e) => '${e.key}: ${e.value}')
                    .toList(),
          ),
          const SizedBox(height: 10),
          _summarySection('Recommended next action', [result.recommendedNextAction]),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.menu_book_rounded),
                label: const Text('Back to Lessons'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _sessionId = 'sess_${widget.lesson.id}_${DateTime.now().millisecondsSinceEpoch}';
                    _index = 0;
                    _submitted = false;
                    _submitting = false;
                    _selectedAnswer = null;
                    _feedback = null;
                    _answers.clear();
                    _evaluations.clear();
                    _sessionCompleted = false;
                    _sessionResult = null;
                    _shortAnswerController.clear();
                  });
                },
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Retry session'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summarySection(String title, List<String> lines) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '• $line',
                style: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _exerciseLabel(ExerciseType type) {
    return switch (type) {
      ExerciseType.multipleChoice => 'Multiple Choice',
      ExerciseType.trueFalse => 'True / False',
      ExerciseType.shortAnswer => 'Short Answer',
    };
  }
}

class _ScaffoldShell extends StatelessWidget {
  final Lesson lesson;
  final Widget child;

  const _ScaffoldShell({
    required this.lesson,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Exercises',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: child,
    );
  }
}
