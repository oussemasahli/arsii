import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/data/mock_data.dart';
import '../../shared/widgets/abstract_background.dart';
import '../../shared/widgets/enrollment_option_card.dart';
import '../../shared/widgets/gradient_button.dart';
import 'evaluation_screen.dart';

/// Onboarding Step 1 — Subject enrollment selection.
class EnrollmentScreen extends StatefulWidget {
  const EnrollmentScreen({super.key});
  @override
  State<EnrollmentScreen> createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends State<EnrollmentScreen>
    with SingleTickerProviderStateMixin {
  final Set<String> _selected = {};

  late final AnimationController _fade;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeIn = CurvedAnimation(parent: _fade, curve: Curves.easeOut);
    Future.delayed(const Duration(milliseconds: 150), () { if (mounted) _fade.forward(); });
  }

  @override
  void dispose() { _fade.dispose(); super.dispose(); }

  bool _isDesktop(BuildContext c) => MediaQuery.of(c).size.width >= 960;

  void _continue() {
    if (_selected.isEmpty) return;
    final chosen = MockData.subjects.where((s) => _selected.contains(s.id)).toList();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => EvaluationScreen(selectedSubjects: chosen),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isD = _isDesktop(context);
    return Scaffold(
      body: Stack(children: [
        const Positioned.fill(child: AbstractBackground()),
        SafeArea(child: FadeTransition(opacity: _fadeIn,
          child: isD ? _desktop() : _mobile())),
      ]),
    );
  }

  Widget _desktop() => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 860),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(children: [
          _stepIndicator(),
          const SizedBox(height: 32),
          Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 4, child: _header(true)),
            const SizedBox(width: 48),
            Expanded(flex: 5, child: _subjectList()),
          ])),
          const SizedBox(height: 24),
          _bottomBar(),
        ]),
      ),
    ),
  );

  Widget _mobile() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Column(children: [
      const SizedBox(height: 16),
      _stepIndicator(),
      Expanded(child: SingleChildScrollView(child: Column(children: [
        const SizedBox(height: 24),
        _header(false),
        const SizedBox(height: 28),
        _subjectList(),
        const SizedBox(height: 32),
      ]))),
      _bottomBar(),
      const SizedBox(height: 16),
    ]),
  );

  // ── Step indicator ────────────────────────────────────────────
  Widget _stepIndicator() => Row(children: [
    _StepDot(label: '1', title: 'Choose', active: true),
    Expanded(child: Container(height: 1, color: AppColors.border)),
    _StepDot(label: '2', title: 'Evaluate', active: false),
    Expanded(child: Container(height: 1, color: AppColors.border)),
    _StepDot(label: '3', title: 'Dashboard', active: false),
  ]);

  // ── Header ────────────────────────────────────────────────────
  Widget _header(bool isD) => Column(
    crossAxisAlignment: isD ? CrossAxisAlignment.start : CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: const Icon(Icons.school_rounded, color: AppColors.primary, size: 32),
      ),
      const SizedBox(height: 24),
      Text('What do you want\nto learn?',
        textAlign: isD ? TextAlign.left : TextAlign.center,
        style: GoogleFonts.inter(fontSize: isD ? 32 : 26, fontWeight: FontWeight.w800,
          color: AppColors.textPrimary, height: 1.15, letterSpacing: -1)),
      const SizedBox(height: 14),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Text(
          'Select the Informatics areas you want to focus on. '
          'We\'ll personalize your learning path based on your choices.',
          textAlign: isD ? TextAlign.left : TextAlign.center,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary, height: 1.6)),
      ),
      const SizedBox(height: 20),
      Text('${_selected.length} of ${MockData.subjects.length} selected',
        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600,
          color: _selected.isNotEmpty ? AppColors.primary : AppColors.textMuted)),
    ],
  );

  // ── Subject list ──────────────────────────────────────────────
  Widget _subjectList() => Column(
    children: MockData.subjects.map((s) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: EnrollmentOptionCard(
        title: s.name,
        description: s.description,
        icon: s.icon,
        accentColor: s.color,
        selected: _selected.contains(s.id),
        onTap: () => setState(() {
          _selected.contains(s.id) ? _selected.remove(s.id) : _selected.add(s.id);
        }),
      ),
    )).toList(),
  );

  // ── Bottom bar ────────────────────────────────────────────────
  Widget _bottomBar() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      if (_selected.isNotEmpty)
        Text('${_selected.length} area${_selected.length > 1 ? "s" : ""} selected',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
      const Spacer(),
      AnimatedOpacity(
        opacity: _selected.isNotEmpty ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 200),
        child: GradientButton(
          label: 'Continue',
          icon: Icons.arrow_forward_rounded,
          onPressed: _selected.isNotEmpty ? _continue : null,
        ),
      ),
    ]),
  );
}

// ── Step dot widget ───────────────────────────────────────────────
class _StepDot extends StatelessWidget {
  final String label, title;
  final bool active;
  const _StepDot({required this.label, required this.title, required this.active});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? AppColors.primary : AppColors.backgroundElevated,
          border: Border.all(color: active ? AppColors.primary : AppColors.border, width: 2),
        ),
        alignment: Alignment.center,
        child: Text(label, style: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w700,
          color: active ? AppColors.textOnPrimary : AppColors.textMuted)),
      ),
      const SizedBox(height: 4),
      Text(title, style: GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w500,
        color: active ? AppColors.primary : AppColors.textMuted)),
    ]);
  }
}
