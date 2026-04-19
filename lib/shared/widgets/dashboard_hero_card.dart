import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

/// Large hero card showing the user's current lesson and a "Continue" CTA.
class DashboardHeroCard extends StatefulWidget {
  final String subjectName;
  final String lessonTitle;
  final String description;
  final double progress;
  final Color accentColor;
  final VoidCallback? onContinue;

  const DashboardHeroCard({
    super.key,
    required this.subjectName,
    required this.lessonTitle,
    required this.description,
    required this.progress,
    this.accentColor = AppColors.primary,
    this.onContinue,
  });

  @override
  State<DashboardHeroCard> createState() => _DashboardHeroCardState();
}

class _DashboardHeroCardState extends State<DashboardHeroCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              widget.accentColor.withOpacity(0.08),
              AppColors.backgroundCard,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: _hovered ? widget.accentColor.withOpacity(0.35) : AppColors.border),
          boxShadow: [
            BoxShadow(
              color: widget.accentColor.withOpacity(_hovered ? 0.1 : 0.04),
              blurRadius: _hovered ? 32 : 16, spreadRadius: -4),
            BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 12,
              offset: const Offset(0, 4)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: widget.accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: widget.accentColor.withOpacity(0.2)),
              ),
              child: Text(widget.subjectName, style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w600, color: widget.accentColor)),
            ),
            const Spacer(),
            Text('${(widget.progress * 100).toInt()}%', style: GoogleFonts.inter(
              fontSize: 20, fontWeight: FontWeight.w800, color: widget.accentColor)),
          ]),
          const SizedBox(height: 16),
          Text(widget.lessonTitle, style: GoogleFonts.inter(
            fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(widget.description, style: GoogleFonts.inter(
            fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 20),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(children: [
              Container(height: 6, color: widget.accentColor.withOpacity(0.1)),
              FractionallySizedBox(widthFactor: widget.progress,
                child: Container(height: 6, decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [widget.accentColor, widget.accentColor.withOpacity(0.7)]),
                  borderRadius: BorderRadius.circular(6)))),
            ]),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 460;
              final button = MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: widget.onContinue,
                  child: Container(
                    width: isNarrow ? double.infinity : null,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [widget.accentColor, widget.accentColor.withOpacity(0.8)]),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: widget.accentColor.withOpacity(0.2), blurRadius: 12)],
                    ),
                    child: Row(
                      mainAxisSize: isNarrow ? MainAxisSize.max : MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Continue Learning', style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textOnPrimary)),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.textOnPrimary),
                      ],
                    ),
                  ),
                ),
              );

              if (isNarrow) return button;
              return Align(alignment: Alignment.centerRight, child: button);
            },
          ),
        ]),
      ),
    );
  }
}
