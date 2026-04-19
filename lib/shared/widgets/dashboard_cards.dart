import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/student_service.dart';

/// Card showing mastery overview across enrolled subjects — PERSONALIZED.
class ProgressOverviewCard extends StatelessWidget {
  final List<StudentSubject> subjects;
  const ProgressOverviewCard({super.key, required this.subjects});

  @override
  Widget build(BuildContext context) {
    if (subjects.isEmpty) {
      return _emptyCard('No subjects enrolled', 'Complete onboarding to see your progress.');
    }

    // Calculate overall mastery
    final overall = subjects.fold(0.0, (sum, s) => sum + s.mastery) / subjects.length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.backgroundCard,
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.pie_chart_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Text('Mastery Overview', style: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _levelColor(overall).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _levelColor(overall).withOpacity(0.3)),
            ),
            child: Text('${(overall * 100).toInt()}% avg', style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w700, color: _levelColor(overall))),
          ),
        ]),
        const SizedBox(height: 20),
        ...subjects.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _SubjectProgressRow(subject: s),
        )),
      ]),
    );
  }

  Color _levelColor(double val) {
    if (val >= 0.7) return AppColors.success;
    if (val >= 0.4) return AppColors.primary;
    return AppColors.error;
  }
}

class _SubjectProgressRow extends StatelessWidget {
  final StudentSubject subject;
  const _SubjectProgressRow({required this.subject});

  static const _subjectColors = {
    'programming': AppColors.primary,
    'algorithms': AppColors.secondary,
    'data_structures': Color(0xFF06B6D4),
    'databases': AppColors.tertiary,
    'web': Color(0xFFFBBF24),
  };

  static const _subjectIcons = {
    'programming': Icons.code_rounded,
    'algorithms': Icons.account_tree_rounded,
    'data_structures': Icons.hub_rounded,
    'databases': Icons.storage_rounded,
    'web': Icons.language_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final color = _subjectColors[subject.id] ?? AppColors.primary;
    final icon = _subjectIcons[subject.id] ?? Icons.book_rounded;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(subject.name, style: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary))),
        Text('${(subject.mastery * 100).toInt()}%', style: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      ]),
      const SizedBox(height: 4),
      Row(children: [
        const SizedBox(width: 24),
        Expanded(child: Text('${subject.completedLessons}/${subject.totalLessons} lessons',
          style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted))),
      ]),
      const SizedBox(height: 4),
      ClipRRect(borderRadius: BorderRadius.circular(4),
        child: Stack(children: [
          Container(height: 5, color: color.withOpacity(0.1)),
          FractionallySizedBox(widthFactor: subject.mastery.clamp(0.0, 1.0),
            child: Container(height: 5, decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(4)))),
        ])),
    ]);
  }
}

/// Card highlighting weak topics — PERSONALIZED from Firestore data.
class WeakTopicsCard extends StatelessWidget {
  final List<WeakTopic> weakTopics;
  final bool isLoading;
  const WeakTopicsCard({super.key, required this.weakTopics, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    if (weakTopics.isEmpty) {
      return _emptyCard('No weak areas found', 'Great job — keep learning to maintain your streak!');
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.backgroundCard,
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade400, size: 20),
          const SizedBox(width: 10),
          Text('Needs Improvement', style: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ]),
        const SizedBox(height: 18),
        ...weakTopics.take(4).map((t) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundSubtle,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                alignment: Alignment.center,
                child: Text('${t.score}%', style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.error))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.topic, style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text(t.subject, style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.textMuted)),
              ])),
              const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMuted),
            ]),
          ),
        )),
      ]),
    );
  }
}

/// Card showing AI-recommended next actions — PERSONALIZED.
class RecommendationCard extends StatelessWidget {
  final List<Recommendation> recommendations;
  final bool isLoading;
  const RecommendationCard({super.key, required this.recommendations, this.isLoading = false});

  static const _iconMap = {
    'refresh': Icons.refresh_rounded,
    'storage': Icons.storage_rounded,
    'school': Icons.school_rounded,
    'fitness_center': Icons.fitness_center_rounded,
    'emoji_events': Icons.emoji_events_rounded,
    'trending_up': Icons.trending_up_rounded,
    'auto_awesome': Icons.auto_awesome_rounded,
  };

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) {
      return _emptyCard('No recommendations yet', 'Complete some lessons to get AI-powered suggestions.');
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: [
          AppColors.secondary.withOpacity(0.06),
          AppColors.backgroundCard,
        ], begin: Alignment.topLeft, end: Alignment.bottomRight),
        border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: AppColors.secondary.withOpacity(0.05), blurRadius: 20, spreadRadius: -4)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(
            gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18)),
          const SizedBox(width: 12),
          Text('AI Recommendations', style: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          if (isLoading) ...[
            const SizedBox(width: 10),
            const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(
              color: AppColors.secondary, strokeWidth: 2)),
          ],
        ]),
        const SizedBox(height: 16),
        ...recommendations.take(3).map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _RecommendationItem(
            title: r.title,
            desc: r.description,
            icon: _iconMap[r.icon] ?? Icons.auto_awesome_rounded,
          ),
        )),
      ]),
    );
  }
}

class _RecommendationItem extends StatelessWidget {
  final String title, desc;
  final IconData icon;
  const _RecommendationItem({required this.title, required this.desc, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSubtle, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border)),
      child: Row(children: [
        Icon(icon, size: 18, color: AppColors.secondary),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          Text(desc, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted, height: 1.4)),
        ])),
        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMuted),
      ]),
    );
  }
}

/// Streak & stats card
class StatsCard extends StatelessWidget {
  final int streakDays;
  final String level;
  final int totalSubjects;
  final DateTime? lastActiveAt;

  const StatsCard({
    super.key,
    required this.streakDays,
    required this.level,
    required this.totalSubjects,
    this.lastActiveAt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: [
          AppColors.primary.withOpacity(0.06),
          AppColors.backgroundCard,
        ], begin: Alignment.topLeft, end: Alignment.bottomRight),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFB923C), size: 20),
          const SizedBox(width: 10),
          Text('Your Stats', style: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ]),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: _StatTile(
            value: '$streakDays',
            label: 'Day Streak',
            icon: Icons.local_fire_department_rounded,
            color: const Color(0xFFFB923C),
          )),
          const SizedBox(width: 12),
          Expanded(child: _StatTile(
            value: level,
            label: 'Level',
            icon: Icons.emoji_events_rounded,
            color: _levelColor(level),
          )),
          const SizedBox(width: 12),
          Expanded(child: _StatTile(
            value: '$totalSubjects',
            label: 'Subjects',
            icon: Icons.school_rounded,
            color: AppColors.primary,
          )),
        ]),
      ]),
    );
  }

  Color _levelColor(String level) {
    switch (level) {
      case 'Advanced': return AppColors.success;
      case 'Intermediate': return AppColors.primary;
      default: return AppColors.secondary;
    }
  }
}

class _StatTile extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  const _StatTile({required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(
          fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textMuted)),
      ]),
    );
  }
}

// ── Empty state card ──────────────────────────────────────────────
Widget _emptyCard(String title, String subtitle) => Container(
  padding: const EdgeInsets.all(24),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    color: AppColors.backgroundCard,
    border: Border.all(color: AppColors.border),
  ),
  child: Column(children: [
    const Icon(Icons.inbox_rounded, color: AppColors.textMuted, size: 32),
    const SizedBox(height: 12),
    Text(title, style: GoogleFonts.inter(
      fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
    const SizedBox(height: 4),
    Text(subtitle, textAlign: TextAlign.center, style: GoogleFonts.inter(
      fontSize: 12, color: AppColors.textMuted)),
  ]),
);
