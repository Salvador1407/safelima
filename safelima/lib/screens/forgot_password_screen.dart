import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safelima/core/app_colors.dart';
import 'package:safelima/screens/reset_password_screen.dart';
import 'package:safelima/services/user_service.dart';
import 'package:safelima/widgets/safe_buttons.dart';
import 'package:safelima/widgets/safe_card.dart';
import 'package:safelima/widgets/safe_input_decoration.dart';
import 'package:safelima/widgets/safe_snack_bar.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _correoController = TextEditingController();
  final UserService _userService = UserService();
  bool _loading = false;

  Future<bool> _hasInternet() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) return false;
    try {
      final result = await InternetAddress.lookup(
        'platform.openai.com',
      ).timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    }
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final connected = await _hasInternet();
      if (!mounted) return;

      if (!connected) {
        SafeSnackBar.showError(context, "📵 No tienes conexión a internet");
        return;
      }

      final correo = _correoController.text.trim();
      final message = await _userService.forgotPassword(correo);

      if (!mounted) return;

      SafeSnackBar.showSuccess(context, message);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ResetPasswordScreen(correo: correo)),
      );
    } catch (e) {
      if (!mounted) return;

      String errorMessage = e.toString();

      if (errorMessage.contains("Correo no registrado")) {
        errorMessage = "El correo no está registrado.";
      } else {
        errorMessage = "No se pudo enviar el código.";
      }

      SafeSnackBar.showError(context, "⚠️ $errorMessage");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _correoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textDark : AppColors.white;
    final subtitleColor = isDark ? AppColors.subtitleDark : Colors.white70;
    final inputTextColor = isDark ? AppColors.textDark : AppColors.textLight;

    return Scaffold(
      body: Container(
        decoration: isDark
            ? BoxDecoration(color: bgColor)
            : const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secundary],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  Image.asset(
                    "assets/images/SafeLima.png",
                    height: 110,
                    width: 110,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Recuperar contraseña",
                    style: GoogleFonts.poppins(
                      color: textColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Ingresa tu correo registrado y te enviaremos un código.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: subtitleColor,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 35),
                  SafeCard(
                    borderRadius: 28,
                    padding: const EdgeInsets.all(22),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _correoController,
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.poppins(color: inputTextColor),
                            decoration: safeInputDecoration(
                              context,
                              labelText: "Correo electrónico",
                              prefixIcon: Icons.email_outlined,
                            ),
                            validator: (value) {
                              final correo = value?.trim() ?? "";
                              if (correo.isEmpty) return "Ingrese su correo";
                              if (!correo.contains("@") ||
                                  !correo.contains(".")) {
                                return "Ingrese un correo válido";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          SafeButton(
                            label: "Enviar código",
                            isLoading: _loading,
                            fullWidth: true,
                            onPressed: _sendCode,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      "← Volver al login",
                      style: GoogleFonts.poppins(
                        color: subtitleColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
