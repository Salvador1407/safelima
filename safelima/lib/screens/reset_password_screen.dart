import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safelima/core/app_colors.dart';
import 'package:safelima/screens/login_screen_user.dart';
import 'package:safelima/services/user_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String correo;

  const ResetPasswordScreen({super.key, required this.correo});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final UserService _userService = UserService();

  bool _loading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

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

  Future<void> _resetPassword() async {
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

      final message = await _userService.resetPassword(
        _codigoController.text.trim(),
        _newPasswordController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreenUser()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      String errorMessage = "No se pudo actualizar la contraseña.";

      final errorText = e.toString().toLowerCase();
      if (errorText.contains("400") ||
          errorText.contains("código inválido") ||
          errorText.contains("codigo invalido")) {
        errorMessage = "Código inválido o expirado.";
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
    _codigoController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
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
                      "Nueva contraseña",
                      style: GoogleFonts.poppins(
                        color: textColor,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Hemos enviado un código a:\n${widget.correo}",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: subtitleColor,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 35),

                    TextFormField(
                      controller: _codigoController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.poppins(
                        color: isDark
                            ? AppColors.textDark
                            : AppColors.textLight,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: cardColor,
                        hintText: "Código de verificación",
                        hintStyle: GoogleFonts.poppins(
                          color: isDark
                              ? AppColors.subtitleDark
                              : AppColors.subtitleLight,
                        ),
                        prefixIcon: Icon(
                          Icons.verified_user_outlined,
                          color: isDark ? AppColors.subtitleDark : Colors.grey,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        final codigo = value?.trim() ?? "";
                        if (codigo.isEmpty) return "Ingrese el código";
                        if (codigo.length < 6) return "Código inválido";
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: !_showPassword,
                      style: GoogleFonts.poppins(
                        color: isDark
                            ? AppColors.textDark
                            : AppColors.textLight,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: cardColor,
                        hintText: "Nueva contraseña",
                        hintStyle: GoogleFonts.poppins(
                          color: isDark
                              ? AppColors.subtitleDark
                              : AppColors.subtitleLight,
                        ),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: isDark ? AppColors.subtitleDark : Colors.grey,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: isDark
                                ? AppColors.subtitleDark
                                : Colors.grey,
                          ),
                          onPressed: () {
                            setState(() => _showPassword = !_showPassword);
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        final pass = value?.trim() ?? "";
                        if (pass.isEmpty) return "Ingrese una nueva contraseña";
                        if (pass.length < 4) {
                          return "Debe tener al menos 4 caracteres";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_showConfirmPassword,
                      style: GoogleFonts.poppins(
                        color: isDark
                            ? AppColors.textDark
                            : AppColors.textLight,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: cardColor,
                        hintText: "Confirmar contraseña",
                        hintStyle: GoogleFonts.poppins(
                          color: isDark
                              ? AppColors.subtitleDark
                              : AppColors.subtitleLight,
                        ),
                        prefixIcon: Icon(
                          Icons.lock_reset_outlined,
                          color: isDark ? AppColors.subtitleDark : Colors.grey,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: isDark
                                ? AppColors.subtitleDark
                                : Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _showConfirmPassword = !_showConfirmPassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        final confirm = value?.trim() ?? "";
                        if (confirm.isEmpty) {
                          return "Confirme la contraseña";
                        }
                        if (confirm != _newPasswordController.text.trim()) {
                          return "Las contraseñas no coinciden";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _resetPassword,
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
                                "Actualizar contraseña",
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
                        "← Volver",
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
