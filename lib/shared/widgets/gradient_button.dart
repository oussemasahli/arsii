import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// A shimmer-gradient CTA button with hover/press feedback.
class GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final double? width;
  final IconData? icon;

  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.width,
    this.icon,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  bool _pressed = false;
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onPressed?.call();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedBuilder(
          animation: _shimmer,
          builder: (context, _) {
            final shimmerT = _shimmer.value;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: widget.width,
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
              transform: Matrix4.identity()..scale(_pressed ? 0.97 : 1.0),
              transformAlignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: _hovered
                      ? [
                          const Color(0xFF00E5FF),
                          const Color(0xFF7C3AED),
                          const Color(0xFF00E5FF),
                        ]
                      : [
                          AppColors.primary,
                          AppColors.primaryMuted,
                        ],
                  begin: Alignment(-1.0 + 2.0 * shimmerT, 0),
                  end: Alignment(1.0 + 2.0 * shimmerT, 0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(
                      _hovered ? 0.35 : 0.15,
                    ),
                    blurRadius: _hovered ? 28 : 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: AppColors.textOnPrimary, size: 20),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: AppColors.textOnPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
