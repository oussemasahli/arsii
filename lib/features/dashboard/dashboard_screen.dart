import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/student_service.dart';
import '../../shared/widgets/abstract_background.dart';
import '../../shared/widgets/dashboard_hero_card.dart';
import '../../shared/widgets/dashboard_cards.dart';
import '../../shared/widgets/gradient_button.dart';
import '../profile/profile_screen.dart';

enum _Tab { home, lessons, progress, exercises, aiTutor, settings }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final _auth = AuthService();
  final _studentService = StudentService();
  bool _sidebarExpanded = false;
  _Tab _activeTab = _Tab.home;
  StudentProfile? _profile;
  bool _loading = true;
  bool _aiLoading = false;

  late final AnimationController _fade;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeIn = CurvedAnimation(parent: _fade, curve: Curves.easeOut);
    Future.delayed(const Duration(milliseconds: 100), () { if (mounted) _fade.forward(); });
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final p = await _studentService.getProfile();
      if (mounted) {
        setState(() { _profile = p; _loading = false; });
        // Refresh AI content in the background
        _refreshAi();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Fetches AI-generated recommendations in the background and updates the UI.
  Future<void> _refreshAi() async {
    if (_profile == null) return;
    setState(() => _aiLoading = true);
    try {
      final updated = await _studentService.refreshAiContent();
      if (mounted && updated != null) {
        setState(() { _profile = updated; _aiLoading = false; });
      }
    } catch (_) {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  @override
  void dispose() { _fade.dispose(); super.dispose(); }

  bool _isDesktop(BuildContext c) => MediaQuery.of(c).size.width >= 960;

  String _tabLabel() {
    switch (_activeTab) {
      case _Tab.home: return 'Home';
      case _Tab.lessons: return 'Lessons';
      case _Tab.progress: return 'Progress';
      case _Tab.exercises: return 'Exercises';
      case _Tab.aiTutor: return 'AI Tutor';
      case _Tab.settings: return 'Settings';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isD = _isDesktop(context);
    final user = _auth.currentUser;
    final name = _profile?.name ?? user?.displayName ?? 'Student';
    final sidebarW = isD ? (_sidebarExpanded ? 228.0 : 80.0) : 72.0;

    return Scaffold(
      body: Stack(children: [
        const Positioned.fill(child: AbstractBackground()),
        SafeArea(child: Row(children: [
          _Sidebar(
            width: sidebarW, expanded: isD && _sidebarExpanded,
            activeTab: _activeTab,
            onTab: (t) => setState(() => _activeTab = t),
            onExpand: (v) { if (isD) setState(() => _sidebarExpanded = v); },
          ),
          Expanded(child: FadeTransition(opacity: _fadeIn, child: Column(children: [
            _topBar(isD, name),
            Expanded(child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: KeyedSubtree(key: ValueKey(_activeTab), child: _body(isD, name)),
            )),
          ]))),
        ])),
      ]),
    );
  }

  Widget _body(bool isD, String name) {
    if (_activeTab == _Tab.home) {
      if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5));
      return isD ? _desktopHome(name) : _mobileHome(name);
    }
    if (_activeTab == _Tab.settings) return _settingsView(isD);
    return _placeholder(isD, _activeTab);
  }

  // ── TOP BAR ──────────────────────────────────────────────────
  Widget _topBar(bool isD, String name) => Padding(
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
        Text('Informatics AI Tutor', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        Text(_tabLabel(), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMuted)),
      ]),
      const Spacer(),
      if (_profile != null) Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: _levelColor(_profile!.level).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _levelColor(_profile!.level).withOpacity(0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.local_fire_department_rounded, size: 14, color: const Color(0xFFFB923C)),
          const SizedBox(width: 4),
          Text('${_profile!.streakDays}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ]),
      ),
      // Avatar → Profile
      MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.secondary.withOpacity(0.12),
            border: Border.all(color: AppColors.secondary.withOpacity(0.25)),
          ),
          child: Text(name[0].toUpperCase(), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.secondary)),
        ),
      )),
    ]),
  );

  Color _levelColor(String level) {
    if (level == 'Advanced') return AppColors.success;
    if (level == 'Intermediate') return AppColors.primary;
    return AppColors.secondary;
  }

  // ── DESKTOP HOME ─────────────────────────────────────────────
  Widget _desktopHome(String name) => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _welcome(name),
      const SizedBox(height: 20),
      if (_profile != null) StatsCard(
        streakDays: _profile!.streakDays,
        level: _profile!.level,
        totalSubjects: _profile!.subjects.length,
        lastActiveAt: _profile!.lastActiveAt,
      ),
      const SizedBox(height: 20),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 6, child: Column(children: [
          _heroCard(),
          const SizedBox(height: 20),
          _activityList(),
        ])),
        const SizedBox(width: 24),
        Expanded(flex: 4, child: Column(children: [
          ProgressOverviewCard(subjects: _profile?.subjects ?? []),
          const SizedBox(height: 20),
          WeakTopicsCard(weakTopics: _profile?.weakTopics ?? [], isLoading: _aiLoading),
          const SizedBox(height: 20),
          RecommendationCard(recommendations: _profile?.recommendations ?? [], isLoading: _aiLoading),
        ])),
      ]),
      const SizedBox(height: 40),
    ]),
  );

  // ── MOBILE HOME ──────────────────────────────────────────────
  Widget _mobileHome(String name) => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _welcome(name),
      const SizedBox(height: 20),
      if (_profile != null) StatsCard(
        streakDays: _profile!.streakDays,
        level: _profile!.level,
        totalSubjects: _profile!.subjects.length,
        lastActiveAt: _profile!.lastActiveAt,
      ),
      const SizedBox(height: 20),
      _heroCard(),
      const SizedBox(height: 20),
      ProgressOverviewCard(subjects: _profile?.subjects ?? []),
      const SizedBox(height: 20),
      WeakTopicsCard(weakTopics: _profile?.weakTopics ?? [], isLoading: _aiLoading),
      const SizedBox(height: 20),
      RecommendationCard(recommendations: _profile?.recommendations ?? [], isLoading: _aiLoading),
      const SizedBox(height: 20),
      _activityList(),
      const SizedBox(height: 40),
    ]),
  );

  // ── WELCOME ──────────────────────────────────────────────────
  Widget _welcome(String name) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('$greeting, $name 👋', style: GoogleFonts.inter(
        fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5)),
      const SizedBox(height: 6),
      Text(_profile != null
        ? 'You\'re on a ${_profile!.streakDays}-day streak — keep it up!'
        : 'Here\'s your learning progress for today.',
        style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
    ]);
  }

  // ── HERO CARD ────────────────────────────────────────────────
  Widget _heroCard() {
    final p = _profile;
    return DashboardHeroCard(
      subjectName: p?.currentLessonSubject ?? 'Getting Started',
      lessonTitle: p?.currentLessonTitle ?? 'Complete your onboarding',
      description: p?.currentLessonDesc ?? 'Take the assessment quiz to personalize your dashboard.',
      progress: p?.currentLessonProgress ?? 0.0,
      accentColor: AppColors.secondary,
      onContinue: () {},
    );
  }

  // ── ACTIVITY ─────────────────────────────────────────────────
  Widget _activityList() {
    final items = _profile?.recentActivity ?? [];
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
          const Icon(Icons.history_rounded, color: AppColors.textMuted, size: 20),
          const SizedBox(width: 10),
          Text('Recent Activity', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ]),
        const SizedBox(height: 16),
        if (items.isEmpty)
          Text('No activity yet — start a lesson!', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
        ...items.take(5).map((a) => _ActivityRow(item: a)),
      ]),
    );
  }

  // ── SETTINGS ─────────────────────────────────────────────────
  Widget _settingsView(bool isD) => SingleChildScrollView(
    padding: EdgeInsets.symmetric(horizontal: isD ? 28 : 16, vertical: 8),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 8),
      Container(
        padding: EdgeInsets.all(isD ? 28 : 22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppColors.backgroundCard,
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 18, offset: const Offset(0, 6))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Account Settings', style: GoogleFonts.inter(fontSize: isD ? 30 : 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.7)),
          const SizedBox(height: 8),
          if (_profile != null) ...[
            Text('${_profile!.name}  •  ${_profile!.email}', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text('Level: ${_profile!.level}  •  ${_profile!.subjects.length} subjects enrolled', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
          ],
          const SizedBox(height: 26),
          GradientButton(label: 'Log Out', icon: Icons.logout_rounded, onPressed: () async => await _auth.signOut()),
        ]),
      ),
    ]),
  );

  // ── PLACEHOLDER ──────────────────────────────────────────────
  Widget _placeholder(bool isD, _Tab tab) {
    final data = {
      _Tab.lessons: ['Lessons', Icons.menu_book_rounded, 'Personalized learning tracks', 'Browse adaptive lessons curated by your learning level and recent performance.'],
      _Tab.progress: ['Progress', Icons.leaderboard_rounded, 'Insightful performance analytics', 'Track mastery, consistency streaks, and topic-level confidence trends over time.'],
      _Tab.exercises: ['Exercises', Icons.fitness_center_rounded, 'Practice with targeted challenges', 'Strengthen weak areas with AI-selected exercises tailored to your current skill gaps.'],
      _Tab.aiTutor: ['AI Tutor', Icons.smart_toy_rounded, 'On-demand guidance and feedback', 'Ask questions, get step-by-step explanations, and receive hints designed for your pace.'],
    };
    final d = data[tab]!;
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isD ? 28 : 16, vertical: 8),
      child: Container(
        padding: EdgeInsets.all(isD ? 28 : 22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20), color: AppColors.backgroundCard,
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 18, offset: const Offset(0, 6))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 54, height: 54, decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14), color: AppColors.primarySurface,
            border: Border.all(color: AppColors.primary.withOpacity(0.25))),
            child: Icon(d[1] as IconData, color: AppColors.primary, size: 26)),
          const SizedBox(height: 18),
          Text(d[0] as String, style: GoogleFonts.inter(fontSize: isD ? 30 : 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.7)),
          const SizedBox(height: 8),
          Text(d[2] as String, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary)),
          const SizedBox(height: 12),
          Text(d[3] as String, style: GoogleFonts.inter(fontSize: 14, height: 1.6, color: AppColors.textSecondary)),
        ]),
      ),
    );
  }
}

// ── Activity Row ────────────────────────────────────────────────
class _ActivityRow extends StatelessWidget {
  final ActivityItem item;
  const _ActivityRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final iconMap = {'completed': Icons.check_circle_rounded, 'started': Icons.play_circle_rounded, 'quiz': Icons.quiz_rounded, 'read': Icons.menu_book_rounded};
    final colorMap = {'completed': AppColors.success, 'started': AppColors.primary, 'quiz': AppColors.secondary, 'read': const Color(0xFFFBBF24)};
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Icon(iconMap[item.type] ?? Icons.circle, size: 18, color: colorMap[item.type] ?? AppColors.textMuted),
        const SizedBox(width: 12),
        Expanded(child: Text(item.title, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary))),
        Text(_timeAgo(item.timestamp), style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
      ]),
    );
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }
}

// ── Sidebar ─────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final double width;
  final bool expanded;
  final _Tab activeTab;
  final ValueChanged<_Tab> onTab;
  final ValueChanged<bool> onExpand;
  const _Sidebar({required this.width, required this.expanded, required this.activeTab, required this.onTab, required this.onExpand});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onExpand(true),
      onExit: (_) => onExpand(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic,
        margin: const EdgeInsets.fromLTRB(12, 10, 12, 10), width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppColors.backgroundCard.withOpacity(0.9),
          border: Border.all(color: AppColors.primary.withOpacity(0.16)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.32), blurRadius: 24, offset: const Offset(0, 12)),
            BoxShadow(color: AppColors.primary.withOpacity(0.12), blurRadius: 24),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Column(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.24), AppColors.secondary.withOpacity(0.18)]),
              border: Border.all(color: AppColors.primary.withOpacity(0.28))),
              child: const Icon(Icons.psychology_alt_rounded, color: AppColors.primary, size: 22)),
            const SizedBox(height: 18),
            _NavItem(icon: Icons.home_rounded, label: 'Home', active: activeTab == _Tab.home, expanded: expanded, onTap: () => onTab(_Tab.home)),
            _NavItem(icon: Icons.menu_book_rounded, label: 'Lessons', active: activeTab == _Tab.lessons, expanded: expanded, onTap: () => onTab(_Tab.lessons)),
            _NavItem(icon: Icons.leaderboard_rounded, label: 'Progress', active: activeTab == _Tab.progress, expanded: expanded, onTap: () => onTab(_Tab.progress)),
            _NavItem(icon: Icons.fitness_center_rounded, label: 'Exercises', active: activeTab == _Tab.exercises, expanded: expanded, onTap: () => onTab(_Tab.exercises)),
            _NavItem(icon: Icons.smart_toy_rounded, label: 'AI Tutor', active: activeTab == _Tab.aiTutor, expanded: expanded, onTap: () => onTab(_Tab.aiTutor)),
            const Spacer(),
            _NavItem(icon: Icons.settings_rounded, label: 'Settings', active: activeTab == _Tab.settings, expanded: expanded, onTap: () => onTab(_Tab.settings)),
          ]),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon; final String label; final bool active, expanded; final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.active, required this.expanded, required this.onTap});
  @override State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hov = false;
  @override
  Widget build(BuildContext context) {
    final a = widget.active;
    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap, behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220), curve: Curves.easeOut,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: (a || _hov) ? (a ? AppColors.primarySurface.withOpacity(0.95) : AppColors.backgroundSubtle.withOpacity(0.6)) : Colors.transparent,
            border: Border.all(color: a ? AppColors.primary.withOpacity(0.35) : Colors.transparent),
            boxShadow: a ? [BoxShadow(color: AppColors.primary.withOpacity(0.22), blurRadius: 16, offset: const Offset(0, 4))] : null,
          ),
          child: Row(children: [
            Icon(widget.icon, size: 18, color: a ? AppColors.textPrimary : AppColors.textMuted),
            ClipRect(child: AnimatedSize(
              duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic,
              child: SizedBox(width: widget.expanded ? 132 : 0,
                child: AnimatedOpacity(duration: const Duration(milliseconds: 180), opacity: widget.expanded ? 1 : 0,
                  child: Padding(padding: const EdgeInsets.only(left: 18),
                    child: Text(widget.label, overflow: TextOverflow.fade, softWrap: false,
                      style: GoogleFonts.inter(fontSize: 20, fontWeight: a ? FontWeight.w600 : FontWeight.w500, color: a ? AppColors.textPrimary : AppColors.textSecondary))))),
            )),
          ]),
        ),
      ),
    );
  }
}
