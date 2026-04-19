import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/ai_service.dart';
import '../../core/theme/app_colors.dart';
import '../exercises/exercises_screen.dart';
import 'models/personalized_lesson.dart';
import 'services/firestore_lessons_service.dart';
import 'widgets/ai_tutor_panel.dart';

class LessonDetailsScreen extends StatefulWidget {
  final PersonalizedLesson item;

  const LessonDetailsScreen({
    super.key,
    required this.item,
  });

  @override
  State<LessonDetailsScreen> createState() => _LessonDetailsScreenState();
}

class _LessonDetailsScreenState extends State<LessonDetailsScreen> {
  final _lessonsService = FirestoreLessonsService();
  final _aiService = AiService();

  bool _processingSimple = false;
  bool _processingExample = false;

  @override
  void initState() {
    super.initState();
    _markOpened();
  }

  Future<void> _markOpened() async {
    await _lessonsService.markLessonOpened(
      lesson: widget.item.lesson,
      progress: widget.item.progress,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.item.lesson;
    final progress = widget.item.progress;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Lesson Details',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final content = SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lesson.title,
              style: GoogleFonts.inter(
                fontSize: 28,
                height: 1.15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              lesson.description,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(Icons.category_rounded, lesson.skill.isNotEmpty ? lesson.skill : lesson.topicId),
                _chip(Icons.trending_up_rounded, lesson.difficulty),
                _chip(Icons.timer_outlined, '${lesson.estimatedMinutes} minutes'),
                _chip(Icons.flag_rounded, _statusText(progress.completionPercent)),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (progress.completionPercent.clamp(0, 100)) / 100,
                minHeight: 8,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 22),
            _sectionTitle('Main lesson content'),
            const SizedBox(height: 8),
            _contentCard(
              child: Text(
                lesson.content.isNotEmpty
                    ? lesson.content
                    : 'No lesson content has been provided yet.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _sectionTitle('Key concepts'),
            const SizedBox(height: 8),
            _contentCard(
              child: lesson.keyConcepts.isEmpty
                  ? Text(
                      'No key concepts listed yet.',
                      style: GoogleFonts.inter(color: AppColors.textMuted),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: lesson.keyConcepts
                          .map((k) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 6),
                                      child: Icon(Icons.circle, size: 7, color: AppColors.primary),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        k,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
            ),
            const SizedBox(height: 14),
            _sectionTitle('Examples'),
            const SizedBox(height: 8),
            _contentCard(
              child: lesson.examples.isEmpty
                  ? Text(
                      'No examples listed yet.',
                      style: GoogleFonts.inter(color: AppColors.textMuted),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: lesson.examples
                          .asMap()
                          .entries
                          .map((entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  '${entry.key + 1}. ${entry.value}',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                    height: 1.55,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: _processingSimple ? null : _explainSimpler,
                  icon: _processingSimple
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_fix_high_rounded),
                  label: const Text('Explain simpler with AI'),
                ),
                OutlinedButton.icon(
                  onPressed: _processingExample ? null : _anotherExample,
                  icon: _processingExample
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lightbulb_outline_rounded),
                  label: const Text('Give me another example'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ExercisesScreen(lesson: lesson),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_circle_outline_rounded),
                  label: const Text('Start Exercises'),
                ),
              ],
            ),
          ],
        ),
      );

          final showSideTutor = constraints.maxWidth >= 1180;
          if (!showSideTutor) {
            return Stack(
              children: [
                Positioned.fill(child: content),
                Positioned(
                  right: 10,
                  bottom: 16,
                  child: SizedBox(
                    width: 44,
                    height: 152,
                    child: AiTutorPanel(lesson: lesson),
                  ),
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: content),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(right: 10, bottom: 14, top: 14),
                child: AiTutorPanel(lesson: lesson),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _explainSimpler() async {
    setState(() => _processingSimple = true);
    final lesson = widget.item.lesson;

    final text = await _aiService.explainLessonSimpler(
      lessonTitle: lesson.title,
      lessonContent: lesson.content,
      studentLevel: lesson.targetLevels.isNotEmpty ? lesson.targetLevels.first : lesson.difficulty,
    );

    if (!mounted) return;
    setState(() => _processingSimple = false);
    _showAiResult(title: 'Simplified Explanation', content: text);
  }

  Future<void> _anotherExample() async {
    setState(() => _processingExample = true);
    final lesson = widget.item.lesson;

    final text = await _aiService.generateAnotherLessonExample(
      lessonTitle: lesson.title,
      lessonContent: lesson.content,
      skill: lesson.skill,
      studentLevel: lesson.targetLevels.isNotEmpty ? lesson.targetLevels.first : lesson.difficulty,
    );

    if (!mounted) return;
    setState(() => _processingExample = false);
    _showAiResult(title: 'Another Tailored Example', content: text);
  }

  void _showAiResult({required String title, required String content}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            16,
            18,
            18 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  content,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _contentCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.backgroundSubtle,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _statusText(double percent) {
    if (percent >= 100) return 'Completed';
    if (percent > 0) return 'In Progress';
    return 'Not Started';
  }
}
