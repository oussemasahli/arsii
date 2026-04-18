import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// A premium floating card with optional glow border,
/// gradient background, and hover animation.
class GlowCard extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double borderRadius;
  final EdgeInsets padding;
  final double? width;
  final double? height;

  const GlowCard({
    super.key,
    required this.child,
    this.glowColor = AppColors.primary,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.all(20),
    this.width,
    this.height,
  });

  @override
  State<GlowCard> createState() => _GlowCardState();
}

class _GlowCardState extends State<GlowCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _controller;
  late final Animation<double> _elevationAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _elevationAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHover(bool hovered) {
    setState(() => _hovered = hovered);
    if (hovered) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: AnimatedBuilder(
        animation: _elevationAnim,
        builder: (context, child) {
          final t = _elevationAnim.value;
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              gradient: LinearGradient(
                colors: [
                  AppColors.backgroundCard,
                  Color.lerp(
                    AppColors.backgroundCard,
                    AppColors.backgroundElevated,
                    t,
                  )!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Color.lerp(
                  AppColors.border,
                  widget.glowColor.withOpacity(0.4),
                  t,
                )!,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.glowColor.withOpacity(0.05 + 0.08 * t),
                  blurRadius: 20 + 20 * t,
                  spreadRadius: -4 + 4 * t,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 12,
                  offset: Offset(0, 4 + 4 * t),
                ),
              ],
            ),
            padding: widget.padding,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
