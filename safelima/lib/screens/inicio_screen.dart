import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safelima/core/app_colors.dart';
import 'package:safelima/core/app_data.dart';
import 'package:safelima/screens/home_screen.dart';
import 'package:safelima/screens/splash_screen.dart';
import 'package:safelima/services/user_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:safelima/widgets/safe_card.dart';

class InicioAppScreen extends StatefulWidget {
  const InicioAppScreen({super.key});

  @override
  State<InicioAppScreen> createState() => _InicioAppScreenState();
}

class _InicioAppScreenState extends State<InicioAppScreen>
    with TickerProviderStateMixin {
  late final AnimationController _circleController;
  late final Animation<double> _circleAnim;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;
  final AuthService _authService = AuthService();
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();

    _circleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _circleAnim = Tween<double>(begin: 0.94, end: 1.08).animate(
      CurvedAnimation(parent: _circleController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _fadeAnim = Tween<double>(begin: 0.68, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _checkSession();
  }

  Future<void> _checkSession() async {
    final token = await _authService.getToken();
    final citizenId = await storage.read(key: "citizen_id");
    final userId = await storage.read(key: "user_id");

    if (token != null && token.isNotEmpty && citizenId != null) {
      if (userId != null) AppData.userID = int.parse(userId);
      AppData.citizen_id = int.parse(citizenId);
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SplashScreen()),
      );
    }
  }

  @override
  void dispose() {
    _circleController.dispose();
    _fadeController.dispose();
    super.dispose();
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
            const _DecorativeHalo(top: -110, right: -80, size: 260),
            const _DecorativeHalo(bottom: -130, left: -90, size: 300),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: _buildLoadingCard(isDark),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard(bool isDark) {
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final subtitleColor = isDark
        ? AppColors.subtitleDark
        : AppColors.subtitleLight;
    final accentColor = isDark ? AppColors.secondaryDark : AppColors.primary;
    final progressBg = isDark ? AppColors.borderDark : AppColors.borderLight;

    return SafeCard(
      borderRadius: 30,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _circleAnim,
            child: Container(
              width: 122,
              height: 122,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.backgroundDark
                    : AppColors.backgroundLight,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Image.asset("assets/images/SafeLima.png"),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            "SafeLima",
            style: GoogleFonts.poppins(
              color: textColor,
              fontSize: 31,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Preparando información de seguridad para tu recorrido.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: subtitleColor,
              fontSize: 14.5,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 26),
          FadeTransition(
            opacity: _fadeAnim,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  color: accentColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "Verificando sesión segura",
                  style: GoogleFonts.poppins(
                    color: accentColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 7,
              color: accentColor,
              backgroundColor: progressBg,
            ),
          ),
        ],
      ),
    );
  }
}

class _DecorativeHalo extends StatelessWidget {
  const _DecorativeHalo({
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
        : AppColors.white.withValues(alpha: 0.14);

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
