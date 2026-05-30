import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safelima/core/app_colors.dart';
import 'package:safelima/screens/reset_password_screen.dart';
import 'package:safelima/services/user_service.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("📵 No tienes conexión a internet"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final correo = _correoController.text.trim();
      final message = await _userService.forgotPassword(correo);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("⚠️ $errorMessage"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textDark : AppColors.white;
    final subtitleColor = isDark ? AppColors.subtitleDark : Colors.white70;

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
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Form(
                key: _formKey,
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
                    TextFormField(
                      controller: _correoController,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.poppins(
                        color: isDark
                            ? AppColors.textDark
                            : AppColors.textLight,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: cardColor,
                        hintText: "Correo electrónico",
                        hintStyle: GoogleFonts.poppins(
                          color: isDark
                              ? AppColors.subtitleDark
                              : AppColors.subtitleLight,
                        ),
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: isDark ? AppColors.subtitleDark : Colors.grey,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        final correo = value?.trim() ?? "";
                        if (correo.isEmpty) return "Ingrese su correo";
                        if (!correo.contains("@") || !correo.contains(".")) {
                          return "Ingrese un correo válido";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _sendCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? AppColors.primaryDark
                              : AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.primary,
                                ),
                              )
                            : Text(
                                "Enviar código",
                                style: GoogleFonts.poppins(
                                  color: isDark
                                      ? AppColors.white
                                      : AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
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
      ),
    );
  }
}
