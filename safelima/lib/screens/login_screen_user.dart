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
import 'package:safelima/widgets/safe_buttons.dart';
import 'package:safelima/widgets/safe_card.dart';
import 'package:safelima/widgets/safe_input_decoration.dart';
import 'package:safelima/widgets/safe_snack_bar.dart';

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
  bool _isLoading = false;

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
      setState(() => _isLoading = true);
      final connected = await _hasInternet();
      if (!mounted) {
        setState(() => _isLoading = false);
        return;
      }

      if (!connected) {
        setState(() => _isLoading = false);
        SafeSnackBar.showError(context, "No tienes conexion a internet");
        return;
      }

      try {
        final token = await _authService.login(
          _userController.text.trim(),
          _passController.text.trim(),
        );

        if (!mounted) {
          setState(() => _isLoading = false);
          return;
        }

        if (token == null || token.isEmpty) {
          setState(() => _isLoading = false);
          SafeSnackBar.showError(
            context,
            "Usuario o contrasena incorrecta. Intentalo de nuevo.",
          );
          return;
        }

        final storage = const FlutterSecureStorage();
        final role = await storage.read(key: "role");

        setState(() => _isLoading = false);

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
        if (!mounted) {
          setState(() => _isLoading = false);
          return;
        }
        setState(() => _isLoading = false);

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

        SafeSnackBar.showError(context, errorMessage);
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
        : AppColors.white.withValues(alpha: 0.84);

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
                color: AppColors.black.withValues(alpha: 0.12),
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
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final subtitleColor = isDark
        ? AppColors.subtitleDark
        : AppColors.subtitleLight;

    return SafeCard(
      borderRadius: 28,
      padding: const EdgeInsets.all(22),
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
              decoration: safeInputDecoration(
                context,
                labelText: "Usuario",
                prefixIcon: Icons.person_outline_rounded,
              ),
              validator: (v) => v!.isEmpty ? "Ingrese su usuario" : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passController,
              obscureText: !_isPasswordVisible,
              style: GoogleFonts.poppins(color: textColor),
              decoration: safeInputDecoration(
                context,
                labelText: "Contrasena",
                prefixIcon: Icons.lock_outline_rounded,
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
            SafeButton(
              label: "Iniciar sesion",
              icon: Icons.login_rounded,
              isLoading: _isLoading,
              fullWidth: true,
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
}
