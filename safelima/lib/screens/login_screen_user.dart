import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safelima/core/app_colors.dart';
import 'package:safelima/screens/AdminDashboardScreen.dart';
import 'package:safelima/screens/forgot_password_screen.dart';
import 'package:safelima/screens/home_screen.dart';
import 'package:safelima/screens/register_screen.dart';
import 'package:safelima/screens/splash_screen.dart';
import 'package:safelima/services/user_service.dart';

class LoginScreenUser extends StatefulWidget {
  const LoginScreenUser({super.key});

  @override
  State<LoginScreenUser> createState() => _LoginScreenUserState();
}

class _LoginScreenUserState extends State<LoginScreenUser> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isPasswordVisible = false;
  final AuthService _authService = AuthService();

  Future<bool> _hasInternet() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) return false;
    try {
      final result = await InternetAddress.lookup('platform.openai.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  void _forgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
    );
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      final connected = await _hasInternet();
      if (!mounted) return;

      if (!connected) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "No tienes conexion a internet",
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      try {
        final token = await _authService.login(
          _userController.text.trim(),
          _passController.text.trim(),
        );

        if (!mounted) return;

        if (token == null || token.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Usuario o contrasena incorrecta. Intentalo de nuevo.",
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white),
              ),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        final storage = const FlutterSecureStorage();
        final role = await storage.read(key: "role");

        if (role == "admin") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } catch (e) {
        if (!mounted) return;
        String errorMessage = e is LoginException
            ? e.message
            : "Error inesperado. Intentalo mas tarde.";

        if (e is! LoginException && e.toString().contains("SocketException")) {
          errorMessage = "Error de conexion con el servidor.";
        } else if (e is! LoginException &&
            (e.toString().contains("401") ||
                e.toString().toLowerCase().contains("unauthorized"))) {
          errorMessage = "Usuario o contrasena incorrecta.";
        } else if (e is! LoginException &&
            (e.toString().contains("Null") ||
                e.toString().contains("subtype"))) {
          errorMessage = "Credenciales invalidas. Revisa tus datos.";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _register() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  void _goBackToSplash() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SplashScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;

    return Scaffold(
      body: Container(
        decoration: isDark
            ? BoxDecoration(color: bgColor)
            : const BoxDecoration(gradient: AppColors.mainGradient),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 42,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildHeader(isDark),
                      const SizedBox(height: 24),
                      _buildLoginCard(isDark),
                      const SizedBox(height: 14),
                      TextButton.icon(
                        onPressed: _goBackToSplash,
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: const Text("Volver al inicio"),
                        style: TextButton.styleFrom(
                          foregroundColor: isDark
                              ? AppColors.secondaryDark
                              : AppColors.white,
                          minimumSize: const Size(0, 44),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final headerColor = isDark ? AppColors.textDark : AppColors.white;
    final subtitleColor = isDark
        ? AppColors.subtitleDark
        : AppColors.white.withOpacity(0.84);

    return Column(
      children: [
        Container(
          width: 112,
          height: 112,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Image.asset("assets/images/SafeLima.png"),
        ),
        const SizedBox(height: 16),
        Text(
          "SafeLima",
          style: GoogleFonts.poppins(
            color: headerColor,
            fontSize: 31,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Accede a tus alertas, rutas y zonas seguras.",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: subtitleColor,
            fontSize: 14.5,
            height: 1.4,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard(bool isDark) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final subtitleColor = isDark
        ? AppColors.subtitleDark
        : AppColors.subtitleLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 430),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(isDark ? 0.20 : 0.10),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Bienvenido de nuevo",
              style: GoogleFonts.poppins(
                color: textColor,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Ingresa tus credenciales para continuar.",
              style: GoogleFonts.poppins(
                color: subtitleColor,
                fontSize: 13.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 22),
            TextFormField(
              controller: _userController,
              style: GoogleFonts.poppins(color: textColor),
              decoration: _inputDecoration(
                isDark: isDark,
                hintText: "Usuario",
                icon: Icons.person_outline_rounded,
              ),
              validator: (v) => v!.isEmpty ? "Ingrese su usuario" : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passController,
              obscureText: !_isPasswordVisible,
              style: GoogleFonts.poppins(color: textColor),
              decoration: _inputDecoration(
                isDark: isDark,
                hintText: "Contrasena",
                icon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color: isDark
                        ? AppColors.subtitleDark
                        : AppColors.subtitleLight,
                  ),
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
              ),
              validator: (v) => v!.isEmpty ? "Ingrese su contrasena" : null,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _forgotPassword,
                style: TextButton.styleFrom(
                  foregroundColor: isDark
                      ? AppColors.secondaryDark
                      : AppColors.primary,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                child: Text(
                  "Olvidaste tu contrasena?",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _GradientSubmitButton(
              label: "Iniciar sesion",
              icon: Icons.login_rounded,
              onPressed: _login,
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    "No tienes cuenta?",
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: subtitleColor,
                      fontSize: 13,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _register,
                  style: TextButton.styleFrom(
                    foregroundColor: isDark
                        ? AppColors.secondaryDark
                        : AppColors.primary,
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                  child: Text(
                    "Registrate",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required bool isDark,
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    final fillColor = isDark
        ? AppColors.backgroundDark.withOpacity(0.55)
        : AppColors.backgroundLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final hintColor = isDark ? AppColors.subtitleDark : AppColors.subtitleLight;

    return InputDecoration(
      filled: true,
      fillColor: fillColor,
      hintText: hintText,
      hintStyle: GoogleFonts.poppins(color: hintColor, fontSize: 14),
      prefixIcon: Icon(icon, color: hintColor),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: isDark ? AppColors.secondaryDark : AppColors.primary,
          width: 1.6,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
      ),
    );
  }
}

class _GradientSubmitButton extends StatelessWidget {
  const _GradientSubmitButton({
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
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.26),
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
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}
