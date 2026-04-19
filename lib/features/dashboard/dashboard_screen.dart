import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/student_service.dart';
import '../../shared/widgets/abstract_background.dart';
import '../../shared/widgets/dashboard_hero_card.dart';
import '../../shared/widgets/dashboard_cards.dart';
import '../../shared/widgets/gradient_button.dart';
import '../lessons/lesson_details_screen.dart';
import '../lessons/lessons_screen.dart';
import '../lessons/models/personalized_lesson.dart';
import '../lessons/services/firestore_lessons_service.dart';
import '../exercises/exercises_hub_screen.dart';
import '../progress/progress_screen.dart';
import '../profile/profile_screen.dart';

enum _Tab { home, lessons, progress, exercises, settings }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final _auth = AuthService();
  final _studentService = StudentService();
  final _lessonsService = FirestoreLessonsService();
  bool _sidebarExpanded = false;
  _Tab _activeTab = _Tab.home;
  StudentProfile? _profile;
  PersonalizedLesson? _lastEnteredLesson;
  bool _loading = true;
  bool _aiLoading = false;
  User? _settingsUser;
  bool _sendingVerification = false;
  bool _refreshingVerification = false;

  late final AnimationController _fade;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeIn = CurvedAnimation(parent: _fade, curve: Curves.easeOut);
    _settingsUser = _auth.currentUser;
    Future.delayed(const Duration(milliseconds: 100), () { if (mounted) _fade.forward(); });
    _loadProfile();
  }

  String _authErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'user-not-found':
        return 'No account was found for that email address.';
      case 'missing-email':
        return 'Email is required to continue.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'no-current-user':
        return 'You need to be signed in to use this action.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? const Color(0xFFB91C1C) : null,
      ),
    );
  }

  Future<void> _sendVerificationEmail() async {
    if (_sendingVerification) return;

    final user = _settingsUser ?? _auth.currentUser;
    if (user == null) {
      _showMessage('No signed-in account found.', error: true);
      return;
    }
    if (user.emailVerified) {
      _showMessage('Your email is already verified.');
      return;
    }

    setState(() => _sendingVerification = true);
    try {
      await _auth.sendEmailVerification();
      _showMessage('Verification email sent. Please check your inbox.');
    } on FirebaseAuthException catch (e) {
      _showMessage(_authErrorMessage(e), error: true);
    } catch (_) {
      _showMessage('Unable to send verification email. Please try again.', error: true);
    } finally {
      if (mounted) {
        setState(() => _sendingVerification = false);
      }
    }
  }

  Future<void> _refreshVerificationStatus() async {
    if (_refreshingVerification) return;

    setState(() => _refreshingVerification = true);
    try {
      final updatedUser = await _auth.reloadCurrentUser();
      if (!mounted) return;

      setState(() => _settingsUser = updatedUser);
      if (updatedUser?.emailVerified == true) {
        _showMessage('Email verified successfully.');
      } else {
        _showMessage('Verification status refreshed.');
      }
    } on FirebaseAuthException catch (e) {
      _showMessage(_authErrorMessage(e), error: true);
    } catch (_) {
      _showMessage('Could not refresh verification status.', error: true);
    } finally {
      if (mounted) {
        setState(() => _refreshingVerification = false);
      }
    }
  }

  Future<void> _showResetPasswordDialog() async {
    final initialEmail = (_settingsUser ?? _auth.currentUser)?.email ?? '';
    final emailController = TextEditingController(text: initialEmail);
    final formKey = GlobalKey<FormState>();
    var isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.backgroundCard,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Reset Password',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Confirm your email address to receive a password reset link.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      style: GoogleFonts.inter(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.backgroundSubtle,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) return 'Email is required.';
                        final isValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
                        if (!isValid) return 'Please enter a valid email address.';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(color: AppColors.textSecondary),
                  ),
                ),
                FilledButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!(formKey.currentState?.validate() ?? false)) return;

                          setDialogState(() => isSubmitting = true);
                          try {
                            await _auth.resetPassword(email: emailController.text.trim());
                            if (!mounted) return;
                            Navigator.of(dialogContext).pop();
                            _showMessage('Password reset email sent. Please check your inbox.');
                          } on FirebaseAuthException catch (e) {
                            _showMessage(_authErrorMessage(e), error: true);
                            if (Navigator.of(dialogContext).mounted) {
                              setDialogState(() => isSubmitting = false);
                            }
                          } catch (_) {
                            _showMessage('Unable to send password reset email.', error: true);
                            if (Navigator.of(dialogContext).mounted) {
                              setDialogState(() => isSubmitting = false);
                            }
                          }
                        },
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.email_outlined, size: 18),
                  label: Text(
                    isSubmitting ? 'Sending...' : 'Send Reset Email',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    emailController.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final p = await _studentService.getProfile();
      if (mounted) {
        setState(() { _profile = p; _loading = false; });
        await _syncLastEnteredLesson();
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
        await _syncLastEnteredLesson();
      }
    } catch (_) {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  Future<void> _syncLastEnteredLesson() async {
    try {
      final data = await _lessonsService.getPersonalizedLessons();
      if (!mounted) return;
      setState(() {
        _lastEnteredLesson = data.continueLearning.isNotEmpty
            ? data.continueLearning.first
            : null;
      });
    } catch (_) {
      // Keep existing fallback fields from profile if lessons query fails.
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
    if (_activeTab == _Tab.lessons) {
      return const LessonsScreen();
    }
    if (_activeTab == _Tab.progress) {
      return const ProgressScreen();
    }
    if (_activeTab == _Tab.exercises) {
      return const ExercisesHubScreen();
    }
    if (_activeTab == _Tab.settings) return _settingsView(isD);
    return _placeholder(isD, _activeTab);
  }

  // ── TOP BAR ──────────────────────────────────────────────────
  Widget _topBar(bool isD, String name) => Padding(
    padding: EdgeInsets.symmetric(horizontal: isD ? 28 : 16, vertical: 16),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          color: AppColors.primarySurface,
        ),
        child: Image.asset('assets/images/logo2.png', width: 48, height: 48),
      ),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('LOCK-IN', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: 1.5)),
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
    final last = _lastEnteredLesson;
    return DashboardHeroCard(
      subjectName: last?.lesson.skill.isNotEmpty == true
          ? last!.lesson.skill
          : (p?.currentLessonSubject ?? 'Getting Started'),
      lessonTitle: last?.lesson.title ?? p?.currentLessonTitle ?? 'Complete your onboarding',
      description: last?.lesson.description ?? p?.currentLessonDesc ?? 'Take the assessment quiz to personalize your dashboard.',
      progress: last != null
          ? (last.progress.completionPercent / 100).clamp(0.0, 1.0)
          : (p?.currentLessonProgress ?? 0.0),
      accentColor: AppColors.secondary,
      onContinue: _openCurrentLesson,
    );
  }

  Future<void> _openCurrentLesson() async {
    final profile = _profile;
    if (profile == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile is still loading. Please try again.')),
      );
      return;
    }

    try {
      final data = await _lessonsService.getPersonalizedLessons();
      PersonalizedLesson? match = _lastEnteredLesson;

      if (match != null) {
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => LessonDetailsScreen(item: match!)),
        );
        await _loadProfile();
        return;
      }

      final all = <PersonalizedLesson>[
        ...data.continueLearning,
        ...data.recommended,
        ...data.reviewWeakAreas,
      ];

      
      if (profile.currentLessonTitle.trim().isNotEmpty) {
        match = all.where((item) {
          return item.lesson.title.toLowerCase().trim() ==
              profile.currentLessonTitle.toLowerCase().trim();
        }).cast<PersonalizedLesson?>().firstWhere(
              (item) => item != null,
              orElse: () => null,
            );
      }

      match ??= data.continueLearning.isNotEmpty ? data.continueLearning.first : null;
      match ??= data.recommended.isNotEmpty ? data.recommended.first : null;

      if (match == null) {
        if (!mounted) return;
        setState(() => _activeTab = _Tab.lessons);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active lesson found. Browse lessons to continue.')),
        );
        return;
      }

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => LessonDetailsScreen(item: match!)),
      );
      await _loadProfile();
    } catch (_) {
      if (!mounted) return;
      setState(() => _activeTab = _Tab.lessons);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open current lesson. Showing lessons list instead.')),
      );
    }
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
    child: Builder(
      builder: (context) {
        final user = _settingsUser ?? _auth.currentUser;
        final email = user?.email ?? _profile?.email ?? 'No email found';
        final verified = user?.emailVerified ?? false;

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
          const SizedBox(height: 18),
          Container(
            padding: EdgeInsets.all(isD ? 24 : 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: AppColors.backgroundCard,
              border: Border.all(color: AppColors.border),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Email Verification',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  email,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: verified ? AppColors.success.withOpacity(0.14) : const Color(0xFFB45309).withOpacity(0.14),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: verified ? AppColors.success.withOpacity(0.4) : const Color(0xFFB45309).withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        verified ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                        size: 16,
                        color: verified ? AppColors.success : const Color(0xFFD97706),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          verified ? 'Email verified' : 'Your email is not verified',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: verified ? AppColors.success : const Color(0xFFD97706),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: (verified || user == null || _sendingVerification)
                          ? null
                          : _sendVerificationEmail,
                      icon: _sendingVerification
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.mark_email_unread_outlined, size: 18),
                      label: Text(
                        _sendingVerification
                            ? 'Sending...'
                            : 'Send Verification Email',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: (_refreshingVerification || user == null)
                          ? null
                          : _refreshVerificationStatus,
                      icon: _refreshingVerification
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(
                        _refreshingVerification
                            ? 'Refreshing...'
                            : 'Refresh Verification Status',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(color: AppColors.border),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: EdgeInsets.all(isD ? 24 : 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: AppColors.backgroundCard,
              border: Border.all(color: AppColors.border),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lock_reset_rounded, color: AppColors.secondary, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Password & Security',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Reset your password securely by sending a reset link to your email address.',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: user == null ? null : _showResetPasswordDialog,
                  icon: const Icon(Icons.key_rounded, size: 18),
                  label: Text(
                    'Reset Password',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.secondary),
                ),
                if (user == null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Sign in to manage password and verification settings.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 26),
        ]);
      },
    ),
  );

  // ── PLACEHOLDER ──────────────────────────────────────────────
  Widget _placeholder(bool isD, _Tab tab) {
    final data = {
      _Tab.lessons: ['Lessons', Icons.menu_book_rounded, 'Personalized learning tracks', 'Browse adaptive lessons curated by your learning level and recent performance.'],
      _Tab.progress: ['Progress', Icons.leaderboard_rounded, 'Insightful performance analytics', 'Track mastery, consistency streaks, and topic-level confidence trends over time.'],
      _Tab.exercises: ['Exercises', Icons.fitness_center_rounded, 'Practice with targeted challenges', 'Strengthen weak areas with AI-selected exercises tailored to your current skill gaps.'],
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
            _NavItem(icon: Icons.home_rounded, label: 'Home', active: activeTab == _Tab.home, expanded: expanded, onTap: () => onTab(_Tab.home)),
            _NavItem(icon: Icons.menu_book_rounded, label: 'Lessons', active: activeTab == _Tab.lessons, expanded: expanded, onTap: () => onTab(_Tab.lessons)),
            _NavItem(icon: Icons.leaderboard_rounded, label: 'Progress', active: activeTab == _Tab.progress, expanded: expanded, onTap: () => onTab(_Tab.progress)),
            _NavItem(icon: Icons.fitness_center_rounded, label: 'Exercises', active: activeTab == _Tab.exercises, expanded: expanded, onTap: () => onTab(_Tab.exercises)),
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
    final hoverOrActive = a || _hov;
    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap, behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _hov && !a ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220), curve: Curves.easeOut,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: hoverOrActive
                ? (a ? AppColors.primarySurface.withOpacity(0.95) : AppColors.backgroundSubtle.withOpacity(0.6))
                : Colors.transparent,
              border: Border.all(color: a ? AppColors.primary.withOpacity(0.35) : (_hov ? AppColors.primary.withOpacity(0.2) : Colors.transparent)),
              boxShadow: a
                ? [BoxShadow(color: AppColors.primary.withOpacity(0.22), blurRadius: 16, offset: const Offset(0, 4))]
                : (_hov ? [BoxShadow(color: AppColors.primary.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 2))] : null),
            ),
            child: Row(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Icon(widget.icon, size: 28,
                  color: hoverOrActive ? AppColors.primary : AppColors.textMuted),
              ),
              Flexible(child: ClipRect(child: AnimatedSize(
                duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic,
                child: SizedBox(width: widget.expanded ? 132 : 0,
                  child: AnimatedOpacity(duration: const Duration(milliseconds: 180), opacity: widget.expanded ? 1 : 0,
                    child: Padding(padding: const EdgeInsets.only(left: 14),
                      child: Text(widget.label, overflow: TextOverflow.ellipsis, softWrap: false,
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: a ? FontWeight.w600 : FontWeight.w500,
                          color: hoverOrActive ? AppColors.textPrimary : AppColors.textSecondary))))),
              ))),
            ]),
          ),
        ),
      ),
    );
  }
}
