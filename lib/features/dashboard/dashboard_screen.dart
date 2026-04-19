import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/data/mock_data.dart';
import '../../core/services/auth_service.dart';
import '../../shared/widgets/abstract_background.dart';
import '../../shared/widgets/dashboard_hero_card.dart';
import '../../shared/widgets/dashboard_cards.dart';

enum _DashboardTab { home, lessons, progress, exercises, aiTutor, settings }

/// Main dashboard screen — shown to returning users or after onboarding.
class DashboardScreen extends StatefulWidget {
  final _DashboardTab initialTab;
  const DashboardScreen({super.key, this.initialTab = _DashboardTab.home});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final _auth = AuthService();
  bool _sidebarExpanded = false;
  late _DashboardTab _activeTab;

  late final AnimationController _fade;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
    _fade = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeIn = CurvedAnimation(parent: _fade, curve: Curves.easeOut);
    Future.delayed(const Duration(milliseconds: 100), () { if (mounted) _fade.forward(); });
  }

  @override
  void dispose() { _fade.dispose(); super.dispose(); }

  bool _isDesktop(BuildContext c) => MediaQuery.of(c).size.width >= 960;

  void _goToTab(_DashboardTab tab) {
    if (tab == _activeTab) {
      return;
    }
    setState(() => _activeTab = tab);
  }

  String _sectionTitle() {
    switch (_activeTab) {
      case _DashboardTab.home:
        return 'Home';
      case _DashboardTab.lessons:
        return 'Lessons';
      case _DashboardTab.progress:
        return 'Progress';
      case _DashboardTab.exercises:
        return 'Exercises';
      case _DashboardTab.aiTutor:
        return 'AI Tutor';
      case _DashboardTab.settings:
        return 'Settings';
    }
  }

  Widget _tabContent(bool isD, String name) {
    switch (_activeTab) {
      case _DashboardTab.home:
        return isD ? _desktopLayout(name) : _mobileLayout(name);
      case _DashboardTab.lessons:
        return _featurePlaceholder(
          isD: isD,
          icon: Icons.menu_book_rounded,
          title: 'Lessons',
          subtitle: 'Personalized learning tracks',
          body: 'Browse adaptive lessons curated by your learning level and recent performance.',
        );
      case _DashboardTab.progress:
        return _featurePlaceholder(
          isD: isD,
          icon: Icons.leaderboard_rounded,
          title: 'Progress',
          subtitle: 'Insightful performance analytics',
          body: 'Track mastery, consistency streaks, and topic-level confidence trends over time.',
        );
      case _DashboardTab.exercises:
        return _featurePlaceholder(
          isD: isD,
          icon: Icons.fitness_center_rounded,
          title: 'Exercises',
          subtitle: 'Practice with targeted challenges',
          body: 'Strengthen weak areas with AI-selected exercises tailored to your current skill gaps.',
        );
      case _DashboardTab.aiTutor:
        return _featurePlaceholder(
          isD: isD,
          icon: Icons.smart_toy_rounded,
          title: 'AI Tutor',
          subtitle: 'On-demand guidance and feedback',
          body: 'Ask questions, get step-by-step explanations, and receive hints designed for your pace.',
        );
      case _DashboardTab.settings:
        return _featurePlaceholder(
          isD: isD,
          icon: Icons.settings_rounded,
          title: 'Settings',
          subtitle: 'Control your learning experience',
          body: 'Manage account preferences, notification behavior, and AI personalization settings.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isD = _isDesktop(context);
    final user = _auth.currentUser;
    final displayName = user?.displayName ?? 'Student';
    final sidebarWidth = isD ? (_sidebarExpanded ? 228.0 : 80.0) : 72.0;
    final showSidebarLabels = isD && _sidebarExpanded;

    return Scaffold(
      body: Stack(children: [
        const Positioned.fill(child: AbstractBackground()),
        SafeArea(
          child: Row(children: [
            _DashboardSidebar(
              width: sidebarWidth,
              expanded: showSidebarLabels,
              activeTab: _activeTab,
              onTabSelected: _goToTab,
              onExpandedChanged: (expanded) {
                if (!isD) {
                  return;
                }
                setState(() => _sidebarExpanded = expanded);
              },
            ),
            Expanded(
              child: FadeTransition(
                opacity: _fadeIn,
                child: Column(children: [
                  _topBar(isD, displayName, _sectionTitle()),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: KeyedSubtree(
                        key: ValueKey(_activeTab),
                        child: _tabContent(isD, displayName),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Top Bar ──────────────────────────────────────────────────
  Widget _topBar(bool isD, String name, String sectionLabel) => Padding(
    padding: EdgeInsets.symmetric(horizontal: isD ? 28 : 16, vertical: 16),
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
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Informatics AI Tutor', style: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        Text(sectionLabel, style: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMuted)),
      ]),
      const Spacer(),
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
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
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
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  Widget _featurePlaceholder({
    required bool isD,
    required IconData icon,
    required String title,
    required String subtitle,
    required String body,
  }) => SingleChildScrollView(
    padding: EdgeInsets.symmetric(horizontal: isD ? 28 : 16, vertical: 8),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 8),
      Container(
        padding: EdgeInsets.all(isD ? 28 : 22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppColors.backgroundCard,
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppColors.primarySurface,
              border: Border.all(color: AppColors.primary.withOpacity(0.25)),
            ),
            child: Icon(icon, color: AppColors.primary, size: 26),
          ),
          const SizedBox(height: 18),
          Text(title, style: GoogleFonts.inter(
            fontSize: isD ? 30 : 24,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.7,
          )),
          const SizedBox(height: 8),
          Text(subtitle, style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          )),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Text(body, style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.6,
              color: AppColors.textSecondary,
            )),
          ),
          const SizedBox(height: 22),
          Wrap(spacing: 12, runSpacing: 12, children: [
            _MetaChip(icon: Icons.auto_awesome_rounded, label: 'Adaptive'),
            _MetaChip(icon: Icons.flash_on_rounded, label: 'AI-powered'),
            _MetaChip(icon: Icons.bar_chart_rounded, label: 'Data-informed'),
          ]),
        ]),
      ),
      const SizedBox(height: 24),
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

class _DashboardSidebar extends StatelessWidget {
  final double width;
  final bool expanded;
  final _DashboardTab activeTab;
  final ValueChanged<_DashboardTab> onTabSelected;
  final ValueChanged<bool> onExpandedChanged;
  const _DashboardSidebar({
    required this.width,
    required this.expanded,
    required this.activeTab,
    required this.onTabSelected,
    required this.onExpandedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onExpandedChanged(true),
      onExit: (_) => onExpandedChanged(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppColors.backgroundCard.withOpacity(0.9),
          border: Border.all(color: AppColors.primary.withOpacity(0.16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.32),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: AppColors.primary.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.24),
                      AppColors.secondary.withOpacity(0.18),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: AppColors.primary.withOpacity(0.28)),
                ),
                child: const Icon(Icons.psychology_alt_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(height: 18),
              _SideNavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                active: activeTab == _DashboardTab.home,
                expanded: expanded,
                onTap: () => onTabSelected(_DashboardTab.home),
              ),
              _SideNavItem(
                icon: Icons.menu_book_rounded,
                label: 'Lessons',
                active: activeTab == _DashboardTab.lessons,
                expanded: expanded,
                onTap: () => onTabSelected(_DashboardTab.lessons),
              ),
              _SideNavItem(
                icon: Icons.leaderboard_rounded,
                label: 'Progress',
                active: activeTab == _DashboardTab.progress,
                expanded: expanded,
                onTap: () => onTabSelected(_DashboardTab.progress),
              ),
              _SideNavItem(
                icon: Icons.fitness_center_rounded,
                label: 'Exercises',
                active: activeTab == _DashboardTab.exercises,
                expanded: expanded,
                onTap: () => onTabSelected(_DashboardTab.exercises),
              ),
              _SideNavItem(
                icon: Icons.smart_toy_rounded,
                label: 'AI Tutor',
                active: activeTab == _DashboardTab.aiTutor,
                expanded: expanded,
                onTap: () => onTabSelected(_DashboardTab.aiTutor),
              ),
              const Spacer(),
              _SideNavItem(
                icon: Icons.settings_rounded,
                label: 'Settings',
                active: activeTab == _DashboardTab.settings,
                expanded: expanded,
                onTap: () => onTabSelected(_DashboardTab.settings),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool expanded;
  final VoidCallback onTap;
  const _SideNavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.expanded,
    required this.onTap,
  });

  @override
  State<_SideNavItem> createState() => _SideNavItemState();
}

class _SideNavItemState extends State<_SideNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.active;
    final showHighlight = a || _hovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: showHighlight
                ? (a
                      ? AppColors.primarySurface.withOpacity(0.95)
                      : AppColors.backgroundSubtle.withOpacity(0.6))
                : Colors.transparent,
            border: Border.all(
              color: a ? AppColors.primary.withOpacity(0.35) : Colors.transparent,
            ),
            boxShadow: a
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.22),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(children: [
            Icon(widget.icon, size: 18, color: a ? AppColors.textPrimary : AppColors.textMuted),
            ClipRect(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                child: SizedBox(
                  width: widget.expanded ? 132 : 0,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: widget.expanded ? 1 : 0,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 18),
                      child: Text(widget.label, overflow: TextOverflow.fade, softWrap: false, style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: a ? FontWeight.w600 : FontWeight.w500,
                        color: a ? AppColors.textPrimary : AppColors.textSecondary,
                      )),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AppColors.backgroundSubtle,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        )),
      ]),
    );
  }
}
