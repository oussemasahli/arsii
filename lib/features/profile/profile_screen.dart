import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../welcome/welcome_screen.dart';
import '../../shared/widgets/abstract_background.dart';
import '../../shared/widgets/gradient_button.dart';
import '../../shared/widgets/glow_card.dart';

/// Profile / Account screen – shows user info and sign-out option.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _auth = AuthService();
  bool _isSigningOut = false;

  Future<void> _handleSignOut() async {
    if (_isSigningOut) return;

    setState(() => _isSigningOut = true);
    try {
      await _auth.signOut();
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign out failed. Please try again.'),
        ),
      );
      setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final email = user?.email ?? 'Anonymous';
    final displayName = user?.displayName ?? 'Student';
    final initial = displayName[0].toUpperCase();
    final uid = user?.uid ?? '—';
    final createdAt = user?.metadata.creationTime;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: AbstractBackground()),
          SafeArea(
            child: Column(
              children: [
                // ── Top bar ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: AppColors.textPrimary, size: 22),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'My Profile',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Content ────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 8),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),

                        // Avatar
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF00D4FF),
                                Color(0xFF8B5CF6),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.primary.withOpacity(0.3),
                                blurRadius: 28,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: GoogleFonts.inter(
                                fontSize: 38,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          displayName,
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Info card
                        GlowCard(
                          glowColor: AppColors.primary,
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              _InfoRow(
                                icon: Icons.fingerprint_rounded,
                                label: 'User ID',
                                value: uid.length > 12
                                    ? '${uid.substring(0, 12)}…'
                                    : uid,
                              ),
                              const _Divider(),
                              _InfoRow(
                                icon: Icons.email_rounded,
                                label: 'Email',
                                value: email,
                              ),
                              const _Divider(),
                              _InfoRow(
                                icon: Icons.calendar_today_rounded,
                                label: 'Joined',
                                value: createdAt != null
                                    ? '${createdAt.day}/${createdAt.month}/${createdAt.year}'
                                    : '—',
                              ),
                              const _Divider(),
                              _InfoRow(
                                icon: Icons.shield_rounded,
                                label: 'Auth Type',
                                value: user?.isAnonymous == true
                                    ? 'Anonymous'
                                    : 'Email',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Sign-out button
                        GradientButton(
                          label: _isSigningOut ? 'Signing Out...' : 'Sign Out',
                          icon: _isSigningOut
                              ? Icons.hourglass_top_rounded
                              : Icons.logout_rounded,
                          onPressed: _isSigningOut ? null : _handleSignOut,
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 14),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: AppColors.border.withOpacity(0.5),
    );
  }
}
