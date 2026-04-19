import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../lessons/models/personalized_lesson.dart';
import '../lessons/services/firestore_lessons_service.dart';
import 'exercises_screen.dart';

class ExercisesHubScreen extends StatefulWidget {
  const ExercisesHubScreen({super.key});

  @override
  State<ExercisesHubScreen> createState() => _ExercisesHubScreenState();
}

class _ExercisesHubScreenState extends State<ExercisesHubScreen> {
  final _lessonsService = FirestoreLessonsService();

  bool _loading = true;
  String? _error;
  PersonalizedLessonsData? _data;

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
      final data = await _lessonsService.getPersonalizedLessons();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Could not load exercises feed\n$_error',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            )
          ],
        ),
      );
    }

    final data = _data;
    if (data == null || data.isEmpty) {
      return Center(
        child: Text(
          'No lesson context available yet. Start from Lessons first.',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
      );
    }

    final all = [
      ...data.continueLearning,
      ...data.recommended,
      ...data.reviewWeakAreas,
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.16),
                AppColors.secondary.withValues(alpha: 0.08),
              ],
            ),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Adaptive Exercise Lab',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Practice sessions are generated from your current lesson state, weak skills, and recent mistakes.',
                style: GoogleFonts.inter(color: AppColors.textSecondary, height: 1.45),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...all.take(8).map((item) => _exerciseTile(item)),
      ],
    );
  }

  Widget _exerciseTile(PersonalizedLesson item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.lesson.title,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.lesson.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ExercisesScreen(lesson: item.lesson),
                ),
              );
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }
}
