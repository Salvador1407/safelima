import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safelima/core/app_colors.dart';
import 'package:safelima/screens/login_screen_user.dart';
import 'package:safelima/screens/register_screen.dart';
import 'package:safelima/widgets/safe_card.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _fadeAnim = Tween<double>(
      begin: 0.72,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreenUser()),
    );
  }

  void _goToRegister() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: isDark
            ? const BoxDecoration(color: AppColors.backgroundDark)
            : const BoxDecoration(gradient: AppColors.mainGradient),
        child: Stack(
          children: [
            const _DecorativeCircle(top: -90, right: -70, size: 210),
            const _DecorativeCircle(bottom: -100, left: -70, size: 240),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 44,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(height: 8),
                          _buildBrandHero(isDark),
                          _buildWelcomeCard(isDark),
                          Text(
                            "Proyecto académico UPC",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                              color: isDark
                                  ? AppColors.subtitleDark
                                  : AppColors.white.withValues(alpha: 0.72),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandHero(bool isDark) {
    return Column(
      children: [
        FadeTransition(
          opacity: _fadeAnim,
          child: Container(
            width: 138,
            height: 138,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(
                    alpha: isDark ? 0.24 : 0.14,
                  ),
                  blurRadius: 28,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Image.asset("assets/images/SafeLima.png"),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          "SafeLima",
          style: GoogleFonts.manrope(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.textDark : AppColors.white,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Prevención, zonas seguras y alertas ciudadanas para moverte con más confianza.",
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 16,
            height: 1.45,
            color: isDark
                ? AppColors.subtitleDark
                : AppColors.white.withValues(alpha: 0.86),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard(bool isDark) {
    final accentColor = isDark ? AppColors.secondaryDark : AppColors.primary;
    final outlineBorderColor = isDark
        ? AppColors.borderDark
        : AppColors.white.withValues(alpha: 0.65);

    return SafeCard(
      borderColor: outlineBorderColor,
      borderRadius: 28,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SafetyPoint(
            icon: Icons.shield_outlined,
            title: "Seguridad preventiva",
            subtitle: "Consulta información de riesgo antes de salir.",
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _SafetyPoint(
            icon: Icons.route_outlined,
            title: "Rutas y zonas seguras",
            subtitle: "Apóyate en datos para planificar tus recorridos.",
            isDark: isDark,
          ),
          const SizedBox(height: 24),
          _GradientActionButton(
            label: "Iniciar sesión",
            icon: Icons.login_rounded,
            onPressed: _goToLogin,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _goToRegister,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: Text(
                "Crear cuenta",
                style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: accentColor,
                side: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle({
    this.top,
    this.right,
    this.bottom,
    this.left,
    required this.size,
  });

  final double? top;
  final double? right;
  final double? bottom;
  final double? left;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final circleColor = isDark
        ? AppColors.borderDark.withValues(alpha: 0.20)
        : AppColors.white.withValues(alpha: 0.10);
    final borderColor = isDark
        ? AppColors.borderDark.withValues(alpha: 0.24)
        : AppColors.white.withValues(alpha: 0.12);

    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: circleColor,
          border: Border.all(color: borderColor),
        ),
      ),
    );
  }
}

class _SafetyPoint extends StatelessWidget {
  const _SafetyPoint({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? AppColors.textDark : AppColors.textLight;
    final subtitleColor = isDark
        ? AppColors.subtitleDark
        : AppColors.subtitleLight;
    final iconColor = isDark ? AppColors.secondaryDark : AppColors.primary;
    final iconBgColor = iconColor.withValues(alpha: 0.12);

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(
                  color: titleColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.manrope(
                  color: subtitleColor,
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        gradient: AppColors.mainGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
