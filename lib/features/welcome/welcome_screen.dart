import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../shared/widgets/abstract_background.dart';
import '../../shared/widgets/glow_card.dart';
import '../../shared/widgets/gradient_button.dart';
import '../../shared/widgets/styled_text_field.dart';
import '../auth/signup_screen.dart';

/// Welcome / Login screen.
/// Desktop: split layout — left (illustration + description) | right (login form)
/// Mobile:  stacked layout
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _auth = AuthService();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  late final AnimationController _leftFade;
  late final Animation<double> _leftFadeIn;
  late final Animation<Offset> _leftSlide;
  late final AnimationController _rightFade;
  late final Animation<double> _rightFadeIn;
  late final Animation<Offset> _rightSlide;

  @override
  void initState() {
    super.initState();
    _leftFade = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _leftFadeIn = CurvedAnimation(parent: _leftFade, curve: Curves.easeOut);
    _leftSlide = Tween<Offset>(begin: const Offset(-0.06, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _leftFade, curve: Curves.easeOut));
    _rightFade = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _rightFadeIn = CurvedAnimation(parent: _rightFade, curve: Curves.easeOut);
    _rightSlide = Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _rightFade, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 200), () { if (mounted) _leftFade.forward(); });
    Future.delayed(const Duration(milliseconds: 500), () { if (mounted) _rightFade.forward(); });
  }

  @override
  void dispose() {
    _leftFade.dispose(); _rightFade.dispose();
    _emailCtl.dispose(); _passCtl.dispose();
    super.dispose();
  }

  bool _isDesktop(BuildContext ctx) => MediaQuery.of(ctx).size.width >= 960;

  Future<void> _handleLogin() async {
    final email = _emailCtl.text.trim();
    final pass = _passCtl.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Please enter your email and password.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await _auth.signIn(email: email, password: pass);
      // Auth state listener in main.dart handles navigation
    } catch (e) {
      if (mounted) {
        String msg = 'Something went wrong. Please try again.';
        final s = e.toString();
        if (s.contains('user-not-found')) msg = 'No account found with this email.';
        else if (s.contains('wrong-password')) msg = 'Incorrect password.';
        else if (s.contains('invalid-email')) msg = 'Invalid email address.';
        else if (s.contains('invalid-credential')) msg = 'Invalid email or password.';
        else if (s.contains('too-many-requests')) msg = 'Too many attempts. Try again later.';
        setState(() { _error = msg; _loading = false; });
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailCtl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email first, then tap Forgot Password.');
      return;
    }
    try {
      await _auth.resetPassword(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Password reset email sent to $email'),
          backgroundColor: AppColors.backgroundElevated,
        ));
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not send reset email.');
    }
  }

  void _goToSignUp() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const SignUpScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isD = _isDesktop(context);
    return Scaffold(
      body: Stack(children: [
        const Positioned.fill(child: AbstractBackground()),
        SafeArea(child: Column(children: [
          _topBar(isD),
          Expanded(child: isD ? _desktop() : _mobile()),
        ])),
      ]),
    );
  }

  // ── Top Bar ──────────────────────────────────────────────────────
  Widget _topBar(bool isD) => Padding(
    padding: EdgeInsets.symmetric(horizontal: isD ? 48 : 24, vertical: 20),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          color: AppColors.primarySurface,
        ),
        child: Image.asset('assets/images/logo2.png', width: 48, height: 48),
      ),
      const SizedBox(width: 12),
      Text('LOCK-IN', style: GoogleFonts.inter(
        fontSize: isD ? 20 : 17, fontWeight: FontWeight.w800,
        color: AppColors.textPrimary, letterSpacing: 1.5)),
      const Spacer(),
      if (isD) ...[
        _NavLink(label: 'Features', onTap: _showFeaturesDialog),
        const SizedBox(width: 32),
        _NavLink(label: 'Curriculum', onTap: _showCurriculumDialog),
        const SizedBox(width: 32),
        _NavLink(label: 'About', onTap: _showAboutDialog),
        const SizedBox(width: 32),
      ],
    ]),
  );

  // ── Layouts ──────────────────────────────────────────────────────
  Widget _desktop() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 48),
    child: Row(children: [
      Expanded(flex: 5, child: FadeTransition(opacity: _leftFadeIn,
        child: SlideTransition(position: _leftSlide, child: _leftSide(true)))),
      const SizedBox(width: 60),
      Expanded(flex: 4, child: FadeTransition(opacity: _rightFadeIn,
        child: SlideTransition(position: _rightSlide, child: Center(child: _loginCard())))),
    ]),
  );

  Widget _mobile() => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Column(children: [
      const SizedBox(height: 16),
      FadeTransition(opacity: _leftFadeIn,
        child: SlideTransition(position: _leftSlide, child: _leftSide(false))),
      const SizedBox(height: 36),
      FadeTransition(opacity: _rightFadeIn,
        child: SlideTransition(position: _rightSlide, child: _loginCard())),
      const SizedBox(height: 48),
    ]),
  );

  // ── Left Side ────────────────────────────────────────────────────
  Widget _leftSide(bool isD) => Column(
    mainAxisAlignment: isD ? MainAxisAlignment.center : MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      _HeroIllustration(size: isD ? 320 : 240),
      SizedBox(height: isD ? 36 : 28),
      Text('Welcome to LOCK-IN', textAlign: TextAlign.center,
        style: GoogleFonts.inter(fontSize: isD ? 30 : 24, fontWeight: FontWeight.w800,
          color: AppColors.textPrimary, height: 1.2, letterSpacing: -0.8)),
      const SizedBox(height: 16),
      ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460),
        child: Text(
          'A personalized AI-powered learning platform that adapts '
          'lessons, exercises, and feedback to your pace — covering '
          'programming, algorithms, databases, and web fundamentals.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: isD ? 15 : 14,
            color: AppColors.textSecondary, height: 1.65))),
    ],
  );  // ── FEATURES DIALOG ──────────────────────────────────────────
  void _showFeaturesDialog() {
    showDialog(context: context, builder: (_) => Dialog(
      backgroundColor: AppColors.backgroundCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(
                gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20)),
              const SizedBox(width: 12),
              Text('Platform Features', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const Spacer(),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: AppColors.textMuted)),
            ]),
            const SizedBox(height: 24),
            Expanded(child: SingleChildScrollView(child: Column(children: [
              _featureRow(Icons.psychology_rounded, 'AI-Powered Tutoring', 'Personalized lessons and feedback adapted to your learning pace and weak areas using advanced AI.', AppColors.primary),
              _featureRow(Icons.assessment_rounded, 'Smart Evaluation', 'Take placement tests to determine your level. The platform continuously tracks your progress.', AppColors.secondary),
              _featureRow(Icons.menu_book_rounded, 'Structured Curriculum', '5 tracks covering Programming, Algorithms, Data Structures, Databases, and Web fundamentals.', const Color(0xFF10B981)),
              _featureRow(Icons.fitness_center_rounded, 'Targeted Exercises', 'Practice drills focused on your weak topics, generated dynamically based on your performance.', const Color(0xFFF59E0B)),
              _featureRow(Icons.leaderboard_rounded, 'Progress Analytics', 'Track mastery, streaks, and confidence trends across all subjects with visual dashboards.', const Color(0xFFEC4899)),
              _featureRow(Icons.verified_rounded, 'AI Recommendations', 'Get personalized study plans and next-step suggestions powered by AI analysis of your results.', const Color(0xFF8B5CF6)),
            ]))),
          ]),
        ),
      ),
    ));
  }

  Widget _featureRow(IconData icon, String title, String desc, Color c) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(
        color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(0.25))),
        child: Icon(icon, color: c, size: 22)),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text(desc, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
      ])),
    ]),
  );

  // ── CURRICULUM DIALOG ────────────────────────────────────────
  void _showCurriculumDialog() {
    final tracks = [
      {'icon': Icons.code_rounded, 'color': AppColors.primary, 'name': 'Programming',
        'lessons': ['Variables & Data Types', 'Conditionals & Decisions', 'Functions & Reuse']},
      {'icon': Icons.account_tree_rounded, 'color': AppColors.secondary, 'name': 'Algorithms',
        'lessons': ['Big O Intuition', 'Sorting Strategies', 'Recursion Foundations']},
      {'icon': Icons.storage_rounded, 'color': const Color(0xFF10B981), 'name': 'Data Structures',
        'lessons': ['Arrays vs Linked Lists', 'Stacks & Queues', 'Hash Tables Basics']},
      {'icon': Icons.table_chart_rounded, 'color': const Color(0xFFF59E0B), 'name': 'Databases',
        'lessons': ['Relational Model Essentials', 'SELECT & Filtering', 'JOINs Without Fear']},
      {'icon': Icons.language_rounded, 'color': const Color(0xFFEC4899), 'name': 'Web Fundamentals',
        'lessons': ['HTML Structure Basics', 'CSS Layout with Flexbox', 'JavaScript Async Concepts']},
    ];

    showDialog(context: context, builder: (_) => Dialog(
      backgroundColor: AppColors.backgroundCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(
                gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 20)),
              const SizedBox(width: 12),
              Text('Curriculum', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const Spacer(),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: AppColors.textMuted)),
            ]),
            const SizedBox(height: 8),
            Text('5 learning tracks · 15+ lessons · Beginner to Advanced',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
            const SizedBox(height: 20),
            Expanded(child: SingleChildScrollView(child: Column(
              children: tracks.map((t) => _trackSection(
                t['icon'] as IconData, t['name'] as String,
                t['lessons'] as List<String>, t['color'] as Color,
              )).toList(),
            ))),
          ]),
        ),
      ),
    ));
  }

  Widget _trackSection(IconData icon, String name, List<String> lessons, Color c) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: c.withOpacity(0.06),
        border: Border.all(color: c.withOpacity(0.18)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: c, size: 20),
          const SizedBox(width: 10),
          Text(name, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(
            color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
            child: Text('${lessons.length} lessons', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: c))),
        ]),
        const SizedBox(height: 10),
        ...lessons.map((l) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            Icon(Icons.play_circle_outline_rounded, size: 16, color: c.withOpacity(0.6)),
            const SizedBox(width: 8),
            Text(l, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
          ]),
        )),
      ]),
    ),
  );

  // ── ABOUT DIALOG ─────────────────────────────────────────────
  void _showAboutDialog() {
    showDialog(context: context, builder: (_) => Dialog(
      backgroundColor: AppColors.backgroundCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 480),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(
                gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.group_rounded, color: Colors.white, size: 20)),
              const SizedBox(width: 12),
              Text('About LOCK-IN', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const Spacer(),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: AppColors.textMuted)),
            ]),
            const SizedBox(height: 24),
            Expanded(child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Team
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(colors: [
                    AppColors.primary.withOpacity(0.08),
                    AppColors.secondary.withOpacity(0.06),
                  ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Team DigaDiga', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  const SizedBox(height: 8),
                  Text(
                    'We are a team of informatics students passionate about making '
                    'computer science education accessible, adaptive, and engaging. '
                    'LOCK-IN is our vision of what studying should feel like — '
                    'smart, personalized, and always in your corner.',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.6),
                  ),
                ]),
              ),
              const SizedBox(height: 20),
              // Mission
              Text('Our Mission', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text(
                'To build an AI-powered learning companion that understands each '
                'student\'s strengths and weaknesses, delivers tailored lessons and exercises, '
                'and provides real-time feedback — helping every learner master informatics '
                'at their own pace.',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.6),
              ),
              const SizedBox(height: 20),
              // What we cover
              Text('What We Cover', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _chip('Programming', Icons.code_rounded, AppColors.primary),
                _chip('Algorithms', Icons.account_tree_rounded, AppColors.secondary),
                _chip('Data Structures', Icons.storage_rounded, const Color(0xFF10B981)),
                _chip('Databases', Icons.table_chart_rounded, const Color(0xFFF59E0B)),
                _chip('Web Dev', Icons.language_rounded, const Color(0xFFEC4899)),
              ]),
              const SizedBox(height: 20),
              // Tech
              Text('Built With', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _chip('Flutter', Icons.flutter_dash_rounded, AppColors.primary),
                _chip('Firebase', Icons.cloud_rounded, const Color(0xFFF59E0B)),
                _chip('OpenRouter AI', Icons.psychology_rounded, AppColors.secondary),
              ]),
            ]))),
          ]),
        ),
      ),
    ));
  }

  Widget _chip(String label, IconData icon, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8),
      border: Border.all(color: c.withOpacity(0.25))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: c),
      const SizedBox(width: 6),
      Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: c)),
    ]),
  );


  // ── Login Card ───────────────────────────────────────────────────
  Widget _loginCard() => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 420),
    child: GlowCard(
      glowColor: AppColors.primary, borderRadius: 20,
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Text('Log In', style: GoogleFonts.inter(
          fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5))),
        const SizedBox(height: 6),
        Center(child: Text('Enter your credentials to access your account',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted))),
        const SizedBox(height: 32),

        // Error
        if (_error != null) ...[
          Container(width: double.infinity, padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.error.withOpacity(0.3))),
            child: Row(children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(_error!, style: GoogleFonts.inter(fontSize: 13, color: AppColors.error))),
            ])),
          const SizedBox(height: 16),
        ],

        // Email
        StyledFieldLabel(label: 'Email Address'),
        const SizedBox(height: 8),
        StyledTextField(controller: _emailCtl, hint: 'Enter your email',
          prefixIcon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 22),

        // Password
        StyledFieldLabel(label: 'Password'),
        const SizedBox(height: 8),
        StyledTextField(controller: _passCtl, hint: 'Enter your password',
          prefixIcon: Icons.lock_outline_rounded, obscureText: _obscure,
          suffixIcon: IconButton(
            icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: AppColors.textMuted, size: 20),
            onPressed: () => setState(() => _obscure = !_obscure))),
        const SizedBox(height: 12),

        // Forgot password
        Align(alignment: Alignment.centerRight,
          child: MouseRegion(cursor: SystemMouseCursors.click,
            child: GestureDetector(onTap: _handleForgotPassword,
              child: Text('Forgot Password?', style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.primary))))),
        const SizedBox(height: 28),

        // Login button
        SizedBox(width: double.infinity, child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))
          : GradientButton(label: 'Log In to Your Account', icon: Icons.login_rounded, onPressed: _handleLogin)),
        const SizedBox(height: 24),

        // Divider
        Row(children: [
          Expanded(child: Container(height: 1, color: AppColors.border)),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('OR', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMuted))),
          Expanded(child: Container(height: 1, color: AppColors.border)),
        ]),
        const SizedBox(height: 24),

        // Sign up
        Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text("Don't have an account? ", style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
          MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
            onTap: _goToSignUp,
            child: Text('Sign Up', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)))),
        ])),
      ]),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════
// Helper Widgets
// ═══════════════════════════════════════════════════════════════════════

/// Circular hero illustration with pulsing glow and floating subject icons.
class _HeroIllustration extends StatefulWidget {
  final double size;
  const _HeroIllustration({required this.size});

  @override
  State<_HeroIllustration> createState() => _HeroIllustrationState();
}

class _HeroIllustrationState extends State<_HeroIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
  }

  @override
  void dispose() { _pulse.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = _pulse.value;
        return Container(
          width: widget.size, height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [AppColors.backgroundElevated, AppColors.backgroundCard, AppColors.backgroundDark],
              stops: [0.0, 0.7, 1.0]),
            border: Border.all(
              color: Color.lerp(AppColors.primary.withOpacity(0.25), AppColors.secondary.withOpacity(0.25), t)!, width: 2),
            boxShadow: [
              BoxShadow(color: AppColors.primary.withOpacity(0.08 + 0.06 * t), blurRadius: 40 + 20 * t, spreadRadius: -5),
              BoxShadow(color: AppColors.secondary.withOpacity(0.06 + 0.04 * t), blurRadius: 60, spreadRadius: -10, offset: const Offset(10, 20)),
            ],
          ),
          child: child,
        );
      },
      child: _content(),
    );
  }

  Widget _content() {
    final s = widget.size;
    return Stack(alignment: Alignment.center, children: [
      Icon(Icons.desktop_mac_rounded, size: s * 0.32, color: AppColors.primary.withOpacity(0.7)),
      _ico(Icons.code_rounded, AppColors.primary, -0.5, s),
      _ico(Icons.account_tree_rounded, AppColors.secondary, 0.4, s),
      _ico(Icons.storage_rounded, AppColors.tertiary, 1.8, s),
      _ico(Icons.language_rounded, AppColors.primary, 2.8, s),
      _ico(Icons.auto_awesome_rounded, AppColors.secondary, -1.6, s),
      _ico(Icons.psychology_alt_rounded, AppColors.tertiary, 3.6, s),
    ]);
  }

  Widget _ico(IconData icon, Color c, double angle, double s) {
    return Transform.translate(
      offset: Offset(cos(angle) * s * 0.33, sin(angle) * s * 0.33),
      child: Container(
        padding: EdgeInsets.all(s * 0.04),
        decoration: BoxDecoration(
          color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(s * 0.035),
          border: Border.all(color: c.withOpacity(0.2))),
        child: Icon(icon, size: s * 0.07, color: c.withOpacity(0.8)),
      ),
    );
  }
}

class _NavLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _NavLink({required this.label, required this.onTap});
  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: widget.onTap,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 180),
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500,
            color: _hovered ? AppColors.primary : AppColors.textSecondary),
          child: Text(widget.label))),
    );
  }
}
