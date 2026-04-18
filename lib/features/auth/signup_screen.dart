import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../shared/widgets/abstract_background.dart';
import '../../shared/widgets/glow_card.dart';
import '../../shared/widgets/gradient_button.dart';
import '../../shared/widgets/styled_text_field.dart';

/// Sign-up screen — same layout pattern as login but with registration form.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with TickerProviderStateMixin {
  final _nameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _confirmCtl = TextEditingController();
  final _auth = AuthService();
  bool _hidePass = true;
  bool _hideConfirm = true;
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
    _nameCtl.dispose(); _emailCtl.dispose();
    _passCtl.dispose(); _confirmCtl.dispose();
    super.dispose();
  }

  bool _isDesktop(BuildContext ctx) => MediaQuery.of(ctx).size.width >= 960;

  Future<void> _handleSignUp() async {
    final name = _nameCtl.text.trim();
    final email = _emailCtl.text.trim();
    final pass = _passCtl.text;
    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Please fill in all fields.'); return;
    }
    if (pass.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.'); return;
    }
    if (pass != _confirmCtl.text) {
      setState(() => _error = 'Passwords do not match.'); return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final cred = await _auth.signUp(email: email, password: pass);
      await cred.user?.updateDisplayName(name);
      // Auth state listener in main.dart handles navigation
    } catch (e) {
      if (mounted) {
        String msg = 'Something went wrong.';
        final s = e.toString();
        if (s.contains('email-already-in-use')) msg = 'An account with this email already exists.';
        else if (s.contains('invalid-email')) msg = 'Invalid email address.';
        else if (s.contains('weak-password')) msg = 'Password too weak.';
        setState(() { _error = msg; _loading = false; });
      }
    }
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
        child: const Icon(Icons.psychology_rounded, color: AppColors.primary, size: 24),
      ),
      const SizedBox(width: 12),
      Text('Informatics AI Tutor', style: GoogleFonts.inter(
        fontSize: isD ? 18 : 15, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary, letterSpacing: -0.3,
      )),
      const Spacer(),
    ]),
  );

  Widget _desktop() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 48),
    child: Row(children: [
      Expanded(flex: 5, child: FadeTransition(opacity: _leftFadeIn,
        child: SlideTransition(position: _leftSlide, child: _leftSide(true)))),
      const SizedBox(width: 60),
      Expanded(flex: 4, child: FadeTransition(opacity: _rightFadeIn,
        child: SlideTransition(position: _rightSlide, child: Center(child: _card())))),
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
        child: SlideTransition(position: _rightSlide, child: _card())),
      const SizedBox(height: 48),
    ]),
  );

  Widget _leftSide(bool isD) => Column(
    mainAxisAlignment: isD ? MainAxisAlignment.center : MainAxisAlignment.start,
    children: [
      Icon(Icons.school_rounded, size: isD ? 120 : 80, color: AppColors.secondary.withOpacity(0.5)),
      SizedBox(height: isD ? 36 : 28),
      Text('Start Your Learning Journey', textAlign: TextAlign.center,
        style: GoogleFonts.inter(fontSize: isD ? 30 : 24, fontWeight: FontWeight.w800,
          color: AppColors.textPrimary, height: 1.2, letterSpacing: -0.8)),
      const SizedBox(height: 16),
      ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440),
        child: Text(
          'Create your free account and get personalized AI-driven lessons '
          'in programming, algorithms, databases, and web development.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: isD ? 15 : 14, color: AppColors.textSecondary, height: 1.65),
        )),
    ],
  );

  Widget _card() => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 420),
    child: GlowCard(
      glowColor: AppColors.secondary, borderRadius: 20,
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Text('Create Account', style: GoogleFonts.inter(
          fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5))),
        const SizedBox(height: 6),
        Center(child: Text('Fill in your details to get started',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted))),
        const SizedBox(height: 28),
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
        StyledFieldLabel(label: 'Full Name'),
        const SizedBox(height: 8),
        StyledTextField(controller: _nameCtl, hint: 'Enter your full name', prefixIcon: Icons.person_outline_rounded),
        const SizedBox(height: 18),
        StyledFieldLabel(label: 'Email Address'),
        const SizedBox(height: 8),
        StyledTextField(controller: _emailCtl, hint: 'Enter your email', prefixIcon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 18),
        StyledFieldLabel(label: 'Password'),
        const SizedBox(height: 8),
        StyledTextField(controller: _passCtl, hint: 'Create a password', prefixIcon: Icons.lock_outline_rounded,
          obscureText: _hidePass, suffixIcon: IconButton(
            icon: Icon(_hidePass ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textMuted, size: 20),
            onPressed: () => setState(() => _hidePass = !_hidePass))),
        const SizedBox(height: 18),
        StyledFieldLabel(label: 'Confirm Password'),
        const SizedBox(height: 8),
        StyledTextField(controller: _confirmCtl, hint: 'Confirm your password', prefixIcon: Icons.lock_outline_rounded,
          obscureText: _hideConfirm, suffixIcon: IconButton(
            icon: Icon(_hideConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textMuted, size: 20),
            onPressed: () => setState(() => _hideConfirm = !_hideConfirm))),
        const SizedBox(height: 28),
        SizedBox(width: double.infinity, child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))
          : GradientButton(label: 'Create Account', icon: Icons.person_add_rounded, onPressed: _handleSignUp)),
        const SizedBox(height: 24),
        Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('Already have an account? ', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
          MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Text('Log In', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)))),
        ])),
      ]),
    ),
  );
}
