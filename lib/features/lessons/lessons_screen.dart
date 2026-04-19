import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import 'lesson_details_screen.dart';
import 'models/personalized_lesson.dart';
import 'services/firestore_lessons_service.dart';
import 'widgets/ai_tutor_panel.dart';
import 'widgets/lesson_card.dart';

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  final _service = FirestoreLessonsService();

  bool _loading = true;
  String? _error;
  PersonalizedLessonsData? _data;
  PersonalizedLesson? _tutorContextLesson;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _service.getPersonalizedLessons();
      if (!mounted) return;
      setState(() {
        _data = data;
        _tutorContextLesson = _pickTutorContext(data);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2.6,
        ),
      );
    }

    if (_error != null) {
      return _ErrorState(
        message: 'Could not load lessons.\n$_error',
        onRetry: _load,
      );
    }

    final data = _data;
    if (data == null || data.isEmpty) {
      return _EmptyState(onRefresh: _load);
    }

    final content = RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 30),
        children: [
          _header(),
          const SizedBox(height: 20),
          _section(
            title: 'Recommended for you',
            subtitle: 'Best next lessons based on your profile and level',
            items: data.recommended,
          ),
          const SizedBox(height: 18),
          _section(
            title: 'Continue learning',
            subtitle: 'Pick up exactly where you left off',
            items: data.continueLearning,
          ),
          const SizedBox(height: 18),
          _section(
            title: 'Review weak areas',
            subtitle: 'Target skills from your diagnostic performance',
            items: data.reviewWeakAreas,
          ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
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
                  child: AiTutorPanel(lesson: _tutorContextLesson?.lesson),
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
              child: AiTutorPanel(lesson: _tutorContextLesson?.lesson),
            ),
          ],
        );
      },
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.14),
            AppColors.secondary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.primarySurface,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.28)),
            ),
            child: const Icon(Icons.auto_stories_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adaptive Lessons',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your curated path evolves from your progress and weak-skill signals.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required String subtitle,
    required List<PersonalizedLesson> items,
  }) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'No lessons here yet. Complete more activity to unlock this section.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
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
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 274,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return LessonCard(
                item: item,
                onTap: () async {
                  setState(() => _tutorContextLesson = item);
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LessonDetailsScreen(item: item),
                    ),
                  );
                  _load();
                },
              );
            },
          ),
        ),
      ],
    );
  }

  PersonalizedLesson? _pickTutorContext(PersonalizedLessonsData data) {
    if (_tutorContextLesson != null) return _tutorContextLesson;
    if (data.continueLearning.isNotEmpty) return data.continueLearning.first;
    if (data.recommended.isNotEmpty) return data.recommended.first;
    if (data.reviewWeakAreas.isNotEmpty) return data.reviewWeakAreas.first;
    return null;
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 42, color: AppColors.error),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _EmptyState({
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppColors.primarySurface,
              ),
              child: const Icon(Icons.menu_book_rounded, color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            Text(
              'No lessons found for your profile yet',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add lesson documents under topics/{topicId}/lessons and they will appear here automatically.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}
