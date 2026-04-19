import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/data/mock_data.dart';
import '../../core/services/auth_service.dart';
import '../../shared/widgets/abstract_background.dart';
import '../../shared/widgets/dashboard_hero_card.dart';
import '../../shared/widgets/dashboard_cards.dart';

/// Main dashboard screen — shown to returning users or after onboarding.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final _auth = AuthService();

  late final AnimationController _fade;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeIn = CurvedAnimation(parent: _fade, curve: Curves.easeOut);
    Future.delayed(const Duration(milliseconds: 100), () { if (mounted) _fade.forward(); });
  }

  @override
  void dispose() { _fade.dispose(); super.dispose(); }

  bool _isDesktop(BuildContext c) => MediaQuery.of(c).size.width >= 960;

  @override
  Widget build(BuildContext context) {
    final isD = _isDesktop(context);
    final user = _auth.currentUser;
    final displayName = user?.displayName ?? 'Student';

    return Scaffold(
      body: Stack(children: [
        const Positioned.fill(child: AbstractBackground()),
        SafeArea(child: FadeTransition(opacity: _fadeIn, child: Column(children: [
          _topBar(isD, displayName),
          Expanded(child: isD ? _desktopLayout(displayName) : _mobileLayout(displayName)),
        ]))),
      ]),
    );
  }

  // ── Top Bar ──────────────────────────────────────────────────
  Widget _topBar(bool isD, String name) => Padding(
    padding: EdgeInsets.symmetric(horizontal: isD ? 40 : 24, vertical: 16),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          color: AppColors.primarySurface,
        ),
        child: const Icon(Icons.psychology_rounded, color: AppColors.primary, size: 22),
      ),
      const SizedBox(width: 12),
      Text('Informatics AI Tutor', style: GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      const Spacer(),
      if (isD) ...[
        _NavPill(icon: Icons.home_rounded, label: 'Home', active: true),
        const SizedBox(width: 8),
        _NavPill(icon: Icons.menu_book_rounded, label: 'Lessons', active: false),
        const SizedBox(width: 8),
        _NavPill(icon: Icons.leaderboard_rounded, label: 'Progress', active: false),
        const SizedBox(width: 16),
      ],
      // Avatar
      MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
        onTap: () async => await _auth.signOut(),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.secondary.withOpacity(0.12),
            border: Border.all(color: AppColors.secondary.withOpacity(0.25)),
          ),
          child: Text(name[0].toUpperCase(), style: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.secondary)),
        ),
      )),
    ]),
  );

  // ── Desktop Layout ───────────────────────────────────────────
  Widget _desktopLayout(String name) => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _welcomeHeader(name),
      const SizedBox(height: 28),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Main column
        Expanded(flex: 6, child: Column(children: [
          DashboardHeroCard(
            subjectName: 'Algorithms',
            lessonTitle: 'Binary Search Deep Dive',
            description: 'Understand divide-and-conquer strategy, implement binary search, and analyze its O(log n) time complexity.',
            progress: 0.42,
            accentColor: AppColors.secondary,
            onContinue: () {},
          ),
          const SizedBox(height: 20),
          _recentActivity(),
        ])),
        const SizedBox(width: 24),
        // Side column
        Expanded(flex: 4, child: Column(children: [
          ProgressOverviewCard(subjects: MockData.subjects.take(4).toList()),
          const SizedBox(height: 20),
          const WeakTopicsCard(),
          const SizedBox(height: 20),
          const RecommendationCard(),
        ])),
      ]),
      const SizedBox(height: 40),
    ]),
  );

  // ── Mobile Layout ────────────────────────────────────────────
  Widget _mobileLayout(String name) => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _welcomeHeader(name),
      const SizedBox(height: 24),
      DashboardHeroCard(
        subjectName: 'Algorithms',
        lessonTitle: 'Binary Search Deep Dive',
        description: 'Understand divide-and-conquer strategy and O(log n) complexity.',
        progress: 0.42,
        accentColor: AppColors.secondary,
        onContinue: () {},
      ),
      const SizedBox(height: 20),
      ProgressOverviewCard(subjects: MockData.subjects.take(4).toList()),
      const SizedBox(height: 20),
      const WeakTopicsCard(),
      const SizedBox(height: 20),
      const RecommendationCard(),
      const SizedBox(height: 20),
      _recentActivity(),
      const SizedBox(height: 40),
    ]),
  );

  // ── Welcome Header ───────────────────────────────────────────
  Widget _welcomeHeader(String name) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Welcome back, $name 👋', style: GoogleFonts.inter(
        fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5)),
      const SizedBox(height: 6),
      Text('Here\'s your learning progress for today.',
        style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
    ],
  );

  // ── Recent Activity ──────────────────────────────────────────
  Widget _recentActivity() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: AppColors.backgroundCard,
      border: Border.all(color: AppColors.border),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 3))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.history_rounded, color: AppColors.textMuted, size: 20),
        const SizedBox(width: 10),
        Text('Recent Activity', style: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ]),
      const SizedBox(height: 16),
      _ActivityItem(time: '2h ago', title: 'Completed: Sorting Algorithms', icon: Icons.check_circle_rounded, color: AppColors.success),
      _ActivityItem(time: '5h ago', title: 'Started: SQL JOINs', icon: Icons.play_circle_rounded, color: AppColors.primary),
      _ActivityItem(time: 'Yesterday', title: 'Quiz: Data Types (85%)', icon: Icons.quiz_rounded, color: AppColors.secondary),
      _ActivityItem(time: 'Yesterday', title: 'Read: HTTP Basics', icon: Icons.menu_book_rounded, color: Color(0xFFFBBF24)),
    ]),
  );
}

class _ActivityItem extends StatelessWidget {
  final String time, title;
  final IconData icon;
  final Color color;
  const _ActivityItem({required this.time, required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary))),
        Text(time, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
      ]),
    );
  }
}

class _NavPill extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool active;
  const _NavPill({required this.icon, required this.label, required this.active});
  @override
  State<_NavPill> createState() => _NavPillState();
}

class _NavPillState extends State<_NavPill> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final a = widget.active;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: a ? AppColors.primarySurface : (_hovered ? AppColors.backgroundSubtle : Colors.transparent),
          border: Border.all(color: a ? AppColors.primary.withOpacity(0.2) : Colors.transparent),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(widget.icon, size: 16, color: a ? AppColors.primary : AppColors.textMuted),
          const SizedBox(width: 6),
          Text(widget.label, style: GoogleFonts.inter(
            fontSize: 13, fontWeight: a ? FontWeight.w600 : FontWeight.w400,
            color: a ? AppColors.primary : AppColors.textSecondary)),
        ]),
      ),
    );
  }
}
