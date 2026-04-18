import 'package:flutter/material.dart';

/// Centralized color palette for the Informatics AI Tutor app.
/// Dark premium futuristic theme with electric blue / cyan accents
/// and subtle violet / pink secondary glow.
class AppColors {
  AppColors._();

  // ── Background surfaces ──────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF0A0A0F);
  static const Color backgroundCard = Color(0xFF12121A);
  static const Color backgroundElevated = Color(0xFF1A1A26);
  static const Color backgroundSubtle = Color(0xFF16161F);

  // ── Primary accent – electric blue / cyan ────────────────────────
  static const Color primary = Color(0xFF00D4FF);
  static const Color primaryMuted = Color(0xFF0098CC);
  static const Color primaryDark = Color(0xFF006B99);
  static const Color primarySurface = Color(0x1A00D4FF); // 10% opacity

  // ── Secondary accent – violet / pink glow ────────────────────────
  static const Color secondary = Color(0xFF8B5CF6);
  static const Color secondaryMuted = Color(0xFF6D3FD4);
  static const Color secondaryGlow = Color(0xFFBF5AF2);
  static const Color secondarySurface = Color(0x1A8B5CF6);

  // ── Tertiary – warm pink ─────────────────────────────────────────
  static const Color tertiary = Color(0xFFFF6AC1);
  static const Color tertiarySurface = Color(0x1AFF6AC1);

  // ── Text ─────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF0F0F5);
  static const Color textSecondary = Color(0xFFB0B0C0);
  static const Color textMuted = Color(0xFF6E6E82);
  static const Color textOnPrimary = Color(0xFF0A0A0F);

  // ── Borders / Dividers ───────────────────────────────────────────
  static const Color border = Color(0xFF2A2A3A);
  static const Color borderLight = Color(0xFF3A3A4E);
  static const Color borderGlow = Color(0x4D00D4FF); // cyan at 30%

  // ── Status ───────────────────────────────────────────────────────
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFEF4444);

  // ── Gradients ────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00D4FF), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF16161F), Color(0xFF1A1A2E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0A0A0F), Color(0xFF10101A), Color(0xFF0A0A0F)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const RadialGradient glowCyan = RadialGradient(
    colors: [Color(0x3300D4FF), Color(0x0000D4FF)],
    radius: 0.8,
  );

  static const RadialGradient glowViolet = RadialGradient(
    colors: [Color(0x338B5CF6), Color(0x008B5CF6)],
    radius: 0.8,
  );
}
