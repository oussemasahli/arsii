import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

/// Assessment question card with lettered multiple-choice options.
class AssessmentQuestionCard extends StatelessWidget {
  final int questionIndex;
  final int totalQuestions;
  final String question;
  final List<String> options;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;

  const AssessmentQuestionCard({
    super.key,
    required this.questionIndex,
    required this.totalQuestions,
    required this.question,
    required this.options,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.backgroundCard,
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withOpacity(0.2))),
          child: Text('Question ${questionIndex + 1} of $totalQuestions',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
        ),
        const SizedBox(height: 20),
        Text(question, style: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.4)),
        const SizedBox(height: 24),
        ...List.generate(options.length, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _OptionTile(label: options[i], index: i,
            selected: selectedIndex == i, onTap: () => onSelect(i)),
        )),
      ]),
    );
  }
}

class _OptionTile extends StatefulWidget {
  final String label;
  final int index;
  final bool selected;
  final VoidCallback onTap;
  const _OptionTile({required this.label, required this.index, required this.selected, required this.onTap});
  @override
  State<_OptionTile> createState() => _OptionTileState();
}

class _OptionTileState extends State<_OptionTile> {
  bool _hovered = false;
  static const _letters = ['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) {
    final sel = widget.selected;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: sel ? AppColors.primary.withOpacity(0.1) : AppColors.backgroundSubtle,
            border: Border.all(
              color: sel ? AppColors.primary.withOpacity(0.5) : _hovered ? AppColors.borderLight : AppColors.border,
              width: sel ? 1.5 : 1)),
          child: Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: sel ? AppColors.primary : AppColors.backgroundElevated,
                border: Border.all(color: sel ? AppColors.primary : AppColors.border)),
              alignment: Alignment.center,
              child: Text(_letters[widget.index], style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: sel ? AppColors.textOnPrimary : AppColors.textMuted))),
            const SizedBox(width: 14),
            Expanded(child: Text(widget.label, style: GoogleFonts.inter(
              fontSize: 14, fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
              color: sel ? AppColors.textPrimary : AppColors.textSecondary))),
          ]),
        ),
      ),
    );
  }
}
