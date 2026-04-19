import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

/// Selectable card for enrollment subject selection with animated glow.
class EnrollmentOptionCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final bool selected;
  final VoidCallback onTap;

  const EnrollmentOptionCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.selected,
    required this.onTap,
  });

  @override
  State<EnrollmentOptionCard> createState() => _EnrollmentOptionCardState();
}

class _EnrollmentOptionCardState extends State<EnrollmentOptionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final sel = widget.selected;
    final c = widget.accentColor;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: sel ? c.withOpacity(0.08) : AppColors.backgroundCard,
            border: Border.all(
              color: sel ? c.withOpacity(0.5) : (_hovered ? AppColors.borderLight : AppColors.border),
              width: sel ? 1.8 : 1),
            boxShadow: [
              if (sel) BoxShadow(color: c.withOpacity(0.12), blurRadius: 24, spreadRadius: -4),
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: sel ? c.withOpacity(0.15) : c.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.withOpacity(sel ? 0.3 : 0.12))),
              child: Icon(widget.icon, color: c, size: 24)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.title, style: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(widget.description, style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.textMuted, height: 1.4)),
            ])),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 24, height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: sel ? c : Colors.transparent,
                border: Border.all(color: sel ? c : AppColors.border, width: 2)),
              child: sel ? const Icon(Icons.check_rounded, size: 14, color: AppColors.textOnPrimary) : null),
          ]),
        ),
      ),
    );
  }
}
