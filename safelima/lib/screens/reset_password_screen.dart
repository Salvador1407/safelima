import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safelima/core/app_colors.dart';
import 'package:safelima/screens/login_screen_user.dart';
import 'package:safelima/services/user_service.dart';
import 'package:safelima/widgets/safe_buttons.dart';
import 'package:safelima/widgets/safe_card.dart';
import 'package:safelima/widgets/safe_input_decoration.dart';
import 'package:safelima/widgets/safe_snack_bar.dart';

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
        SafeSnackBar.showError(context, "📵 No tienes conexión a internet");
        return;
      }

      final message = await _userService.resetPassword(
        _codigoController.text.trim(),
        _newPasswordController.text.trim(),
      );

      if (!mounted) return;

      SafeSnackBar.showSuccess(context, message);

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

      SafeSnackBar.showError(context, "⚠️ $errorMessage");
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
                  SafeCard(
                    borderRadius: 28,
                    padding: const EdgeInsets.all(22),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _codigoController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.poppins(color: inputTextColor),
                            decoration: safeInputDecoration(
                              context,
                              labelText: "Código de verificación",
                              prefixIcon: Icons.verified_user_outlined,
                            ),
                            validator: (value) {
                              final codigo = value?.trim() ?? "";
                              if (codigo.isEmpty) return "Ingrese el código";
                              if (codigo.length < 6) return "Código inválido";
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _newPasswordController,
                            obscureText: !_showPassword,
                            style: GoogleFonts.poppins(color: inputTextColor),
                            decoration: safeInputDecoration(
                              context,
                              labelText: "Nueva contraseña",
                              prefixIcon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: isDark
                                      ? AppColors.subtitleDark
                                      : AppColors.subtitleLight,
                                ),
                                onPressed: () {
                                  setState(
                                    () => _showPassword = !_showPassword,
                                  );
                                },
                              ),
                            ),
                            validator: (value) {
                              final pass = value?.trim() ?? "";
                              if (pass.isEmpty) {
                                return "Ingrese una nueva contraseña";
                              }
                              if (pass.length < 4) {
                                return "Debe tener al menos 4 caracteres";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: !_showConfirmPassword,
                            style: GoogleFonts.poppins(color: inputTextColor),
                            decoration: safeInputDecoration(
                              context,
                              labelText: "Confirmar contraseña",
                              prefixIcon: Icons.lock_reset_outlined,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showConfirmPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: isDark
                                      ? AppColors.subtitleDark
                                      : AppColors.subtitleLight,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _showConfirmPassword =
                                        !_showConfirmPassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              final confirm = value?.trim() ?? "";
                              if (confirm.isEmpty) {
                                return "Confirme la contraseña";
                              }
                              if (confirm !=
                                  _newPasswordController.text.trim()) {
                                return "Las contraseñas no coinciden";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          SafeButton(
                            label: "Actualizar contraseña",
                            isLoading: _loading,
                            fullWidth: true,
                            onPressed: _resetPassword,
                          ),
                        ],
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
    );
  }
}
