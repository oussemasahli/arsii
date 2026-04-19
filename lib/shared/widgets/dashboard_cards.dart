import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/data/mock_data.dart';

/// Card showing mastery overview across enrolled subjects.
class ProgressOverviewCard extends StatelessWidget {
  final List<Subject> subjects;
  const ProgressOverviewCard({super.key, required this.subjects});

  @override
  Widget build(BuildContext context) {
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
        ]),
        const SizedBox(height: 20),
        ...subjects.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _SubjectRow(subject: s),
        )),
      ]),
    );
  }
}

class _SubjectRow extends StatelessWidget {
  final Subject subject;
  const _SubjectRow({required this.subject});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(subject.icon, size: 16, color: subject.color),
        const SizedBox(width: 8),
        Expanded(child: Text(subject.name, style: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary))),
        Text('${(subject.mastery * 100).toInt()}%', style: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w700, color: subject.color)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(borderRadius: BorderRadius.circular(4),
        child: Stack(children: [
          Container(height: 5, color: subject.color.withOpacity(0.1)),
          FractionallySizedBox(widthFactor: subject.mastery,
            child: Container(height: 5, decoration: BoxDecoration(
              color: subject.color, borderRadius: BorderRadius.circular(4)))),
        ])),
    ]);
  }
}

/// Card highlighting weak topics that need improvement.
class WeakTopicsCard extends StatelessWidget {
  const WeakTopicsCard({super.key});

  static const _weakTopics = [
    {'topic': 'Recursion', 'subject': 'Algorithms', 'score': 32},
    {'topic': 'Binary Trees', 'subject': 'Data Structures', 'score': 41},
    {'topic': 'CSS Flexbox', 'subject': 'Web Basics', 'score': 45},
  ];

  @override
  Widget build(BuildContext context) {
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
        ..._weakTopics.map((t) => Padding(
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
                child: Text('${t['score']}%', style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.error))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t['topic'] as String, style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text(t['subject'] as String, style: GoogleFonts.inter(
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

/// Card showing AI-recommended next actions.
class RecommendationCard extends StatelessWidget {
  const RecommendationCard({super.key});

  @override
  Widget build(BuildContext context) {
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
          Text('AI Recommendation', style: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ]),
        const SizedBox(height: 16),
        _RecommendationItem(title: 'Practice Recursion', desc: 'You scored low — 3 focused exercises can help.', icon: Icons.refresh_rounded),
        const SizedBox(height: 10),
        _RecommendationItem(title: 'Review SQL JOINs', desc: 'Reinforce before the next database module.', icon: Icons.storage_rounded),
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
