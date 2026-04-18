import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/abstract_background.dart';
import '../../shared/widgets/glow_card.dart';
import '../../shared/widgets/gradient_button.dart';

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
  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Animations
  late final AnimationController _leftFade;
  late final Animation<double> _leftFadeIn;
  late final Animation<Offset> _leftSlide;

  late final AnimationController _rightFade;
  late final Animation<double> _rightFadeIn;
  late final Animation<Offset> _rightSlide;

  @override
  void initState() {
    super.initState();

    _leftFade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _leftFadeIn = CurvedAnimation(parent: _leftFade, curve: Curves.easeOut);
    _leftSlide = Tween<Offset>(
      begin: const Offset(-0.06, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _leftFade, curve: Curves.easeOut));

    _rightFade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _rightFadeIn = CurvedAnimation(parent: _rightFade, curve: Curves.easeOut);
    _rightSlide = Tween<Offset>(
      begin: const Offset(0.06, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _rightFade, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _leftFade.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _rightFade.forward();
    });
  }

  @override
  void dispose() {
    _leftFade.dispose();
    _rightFade.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 960;

  @override
  Widget build(BuildContext context) {
    final isDesktop = _isDesktop(context);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: AbstractBackground()),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(isDesktop),
                Expanded(
                  child: isDesktop
                      ? _buildDesktopLayout()
                      : _buildMobileLayout(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Top Bar ──────────────────────────────────────────────────────────
  Widget _buildTopBar(bool isDesktop) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 24,
        vertical: 20,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              color: AppColors.primarySurface,
            ),
            child: const Icon(
              Icons.psychology_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Informatics AI Tutor',
            style: GoogleFonts.inter(
              fontSize: isDesktop ? 18 : 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          if (isDesktop) ...[
            _NavLink(label: 'Features', onTap: () {}),
            const SizedBox(width: 32),
            _NavLink(label: 'Curriculum', onTap: () {}),
            const SizedBox(width: 32),
            _NavLink(label: 'About', onTap: () {}),
            const SizedBox(width: 32),
          ],
        ],
      ),
    );
  }

  // ── Desktop Layout ───────────────────────────────────────────────────
  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Row(
        children: [
          // Left – Illustration + Description
          Expanded(
            flex: 5,
            child: FadeTransition(
              opacity: _leftFadeIn,
              child: SlideTransition(
                position: _leftSlide,
                child: _buildLeftSide(isDesktop: true),
              ),
            ),
          ),
          const SizedBox(width: 60),
          // Right – Login Form
          Expanded(
            flex: 4,
            child: FadeTransition(
              opacity: _rightFadeIn,
              child: SlideTransition(
                position: _rightSlide,
                child: Center(child: _buildLoginCard()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Mobile Layout ────────────────────────────────────────────────────
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          FadeTransition(
            opacity: _leftFadeIn,
            child: SlideTransition(
              position: _leftSlide,
              child: _buildLeftSide(isDesktop: false),
            ),
          ),
          const SizedBox(height: 36),
          FadeTransition(
            opacity: _rightFadeIn,
            child: SlideTransition(
              position: _rightSlide,
              child: _buildLoginCard(),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  // ── Left Side: Illustration Circle + Welcome Text ────────────────────
  Widget _buildLeftSide({required bool isDesktop}) {
    return Column(
      mainAxisAlignment:
          isDesktop ? MainAxisAlignment.center : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Circular illustration container
        _HeroIllustration(size: isDesktop ? 320 : 240),

        SizedBox(height: isDesktop ? 36 : 28),

        // Welcome title
        Text(
          'Welcome to Informatics AI Tutor',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: isDesktop ? 30 : 24,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            height: 1.2,
            letterSpacing: -0.8,
          ),
        ),

        const SizedBox(height: 16),

        // Description
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Text(
            'A personalized AI-powered learning platform that adapts '
            'lessons, exercises, and feedback to your pace — covering '
            'programming, algorithms, databases, and web fundamentals.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: isDesktop ? 15 : 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.65,
            ),
          ),
        ),
      ],
    );
  }

  // ── Login Form Card ──────────────────────────────────────────────────
  Widget _buildLoginCard() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: GlowCard(
        glowColor: AppColors.primary,
        borderRadius: 20,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Text(
                'Log In',
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'Enter your credentials to access your account',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textMuted,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Email field
            _FieldLabel(label: 'Email Address'),
            const SizedBox(height: 8),
            _StyledTextField(
              controller: _emailController,
              hint: 'Enter your email',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 22),

            // Password field
            _FieldLabel(label: 'Password'),
            const SizedBox(height: 8),
            _StyledTextField(
              controller: _passwordController,
              hint: 'Enter your password',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),

            const SizedBox(height: 12),

            // Forgot password
            Align(
              alignment: Alignment.centerRight,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {},
                  child: Text(
                    'Forgot Password?',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Login button
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                label: 'Log In to Your Account',
                icon: Icons.login_rounded,
                onPressed: () {},
              ),
            ),

            const SizedBox(height: 24),

            // Divider
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    color: AppColors.border,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    color: AppColors.border,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Sign up link
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {},
                      child: Text(
                        'Sign Up',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Helper Widgets
// ═══════════════════════════════════════════════════════════════════════════

/// Circular hero illustration with glow ring and inner icon-based visual.
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
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = _pulse.value;
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.backgroundElevated,
                AppColors.backgroundCard,
                AppColors.backgroundDark,
              ],
              stops: const [0.0, 0.7, 1.0],
            ),
            border: Border.all(
              color: Color.lerp(
                AppColors.primary.withOpacity(0.25),
                AppColors.secondary.withOpacity(0.25),
                t,
              )!,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.08 + 0.06 * t),
                blurRadius: 40 + 20 * t,
                spreadRadius: -5,
              ),
              BoxShadow(
                color: AppColors.secondary.withOpacity(0.06 + 0.04 * t),
                blurRadius: 60,
                spreadRadius: -10,
                offset: const Offset(10, 20),
              ),
            ],
          ),
          child: child,
        );
      },
      child: _buildIllustrationContent(),
    );
  }

  Widget _buildIllustrationContent() {
    final s = widget.size;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Central monitor
        Icon(
          Icons.desktop_mac_rounded,
          size: s * 0.32,
          color: AppColors.primary.withOpacity(0.7),
        ),

        // Floating subject icons around the circle
        _positionedIcon(
          icon: Icons.code_rounded,
          color: AppColors.primary,
          angle: -0.5,
          distance: s * 0.33,
          iconSize: s * 0.08,
        ),
        _positionedIcon(
          icon: Icons.account_tree_rounded,
          color: AppColors.secondary,
          angle: 0.4,
          distance: s * 0.35,
          iconSize: s * 0.07,
        ),
        _positionedIcon(
          icon: Icons.storage_rounded,
          color: AppColors.tertiary,
          angle: 1.8,
          distance: s * 0.32,
          iconSize: s * 0.07,
        ),
        _positionedIcon(
          icon: Icons.language_rounded,
          color: AppColors.primary,
          angle: 2.8,
          distance: s * 0.36,
          iconSize: s * 0.07,
        ),
        _positionedIcon(
          icon: Icons.auto_awesome_rounded,
          color: AppColors.secondary,
          angle: -1.6,
          distance: s * 0.3,
          iconSize: s * 0.065,
        ),
        _positionedIcon(
          icon: Icons.psychology_alt_rounded,
          color: AppColors.tertiary,
          angle: 3.6,
          distance: s * 0.34,
          iconSize: s * 0.065,
        ),

        // Small decorative dots
        ..._buildDots(s),
      ],
    );
  }

  Widget _positionedIcon({
    required IconData icon,
    required Color color,
    required double angle,
    required double distance,
    required double iconSize,
  }) {
    return Transform.translate(
      offset: Offset(
        cos(angle) * distance,
        sin(angle) * distance,
      ),
      child: Container(
        padding: EdgeInsets.all(iconSize * 0.5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(iconSize * 0.4),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Icon(icon, size: iconSize, color: color.withOpacity(0.8)),
      ),
    );
  }

  List<Widget> _buildDots(double s) {
    final dots = <Widget>[];
    final rng = [1.1, 2.2, 3.8, 5.0, 0.3];
    for (int i = 0; i < rng.length; i++) {
      dots.add(
        Transform.translate(
          offset: Offset(
            cos(rng[i]) * s * 0.42,
            sin(rng[i]) * s * 0.42,
          ),
          child: Container(
            width: 4 + (i % 3) * 2.0,
            height: 4 + (i % 3) * 2.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (i % 2 == 0 ? AppColors.primary : AppColors.secondary)
                  .withOpacity(0.25),
            ),
          ),
        ),
      );
    }
    return dots;
  }
}

/// Styled text field matching the dark futuristic theme.
class _StyledTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;

  const _StyledTextField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
  });

  @override
  State<_StyledTextField> createState() => _StyledTextFieldState();
}

class _StyledTextFieldState extends State<_StyledTextField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _focused
              ? AppColors.primary.withOpacity(0.5)
              : AppColors.border,
          width: _focused ? 1.5 : 1,
        ),
        color: AppColors.backgroundSubtle,
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.08),
                  blurRadius: 12,
                  spreadRadius: -2,
                ),
              ]
            : [],
      ),
      child: Focus(
        onFocusChange: (focused) => setState(() => _focused = focused),
        child: TextField(
          controller: widget.controller,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
            prefixIcon: Icon(
              widget.prefixIcon,
              color: _focused ? AppColors.primary : AppColors.textMuted,
              size: 20,
            ),
            suffixIcon: widget.suffixIcon,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
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
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 180),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _hovered ? AppColors.primary : AppColors.textSecondary,
          ),
          child: Text(widget.label),
        ),
      ),
    );
  }
}
