import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safelima/core/app_colors.dart';
import 'package:safelima/core/app_data.dart';
import 'package:safelima/screens/home_screen.dart';
import 'package:safelima/screens/login_screen_user.dart';
import 'package:safelima/services/user_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  final UserService _userService = UserService();
  final storage = const FlutterSecureStorage();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _acceptTerms = false;
  bool _isLoading = false;

  Future<bool> _hasInternet() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) return false;

    try {
      final result = await InternetAddress.lookup(
        'example.com',
      ).timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    }
  }

  Future<void> _register() async {
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Debes aceptar los términos y condiciones."),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final connected = await _hasInternet();
      if (!connected) {
        throw const RegisterCitizenException('No tienes conexión a internet');
      }

      final registrationData = await _userService.registerCitizen(
        username: _userController.text.trim(),
        password: _passController.text,
        fullName: _nameController.text.trim(),
        correo: _emailController.text.trim(),
      );

      await _persistRegistrationData(registrationData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Registro exitoso. Bienvenido a SafeLima."),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } on RegisterCitizenException catch (e) {
      _showRegisterError(e.message);
    } catch (e) {
      _showRegisterError('Error del servidor. Inténtalo nuevamente');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onRegisterPressed() async {
    await _register();
  }

  Future<void> _persistRegistrationData(Map<String, dynamic> data) async {
    final token = data['access_token'] ?? data['token'];
    final user = data['user'];
    final citizen = data['citizen'];
    final userId = _readInt(
      data['user_id'] ?? data['id'] ?? (user is Map ? user['id'] : null),
    );
    final citizenId = _readInt(
      data['citizen_id'] ?? (citizen is Map ? citizen['id'] : null),
    );

    if (token is String && token.isNotEmpty) {
      await storage.write(key: "auth_token", value: token);
      AppData.token = token;
    }

    if (userId != null) {
      await storage.write(key: "user_id", value: userId.toString());
      AppData.userID = userId;
    }

    if (citizenId != null) {
      await storage.write(key: "citizen_id", value: citizenId.toString());
      AppData.citizen_id = citizenId;
    }
  }

  int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  void _showRegisterError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  void _showTermsAndConditions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppColors.textDark : AppColors.textLight;
    final bodyColor = isDark ? AppColors.subtitleDark : AppColors.subtitleLight;
    final accentColor = isDark ? AppColors.secondaryDark : AppColors.primary;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            "Términos y condiciones",
            style: GoogleFonts.poppins(
              color: titleColor,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.62,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _termsSection(
                    title: "1. Finalidad del servicio",
                    body:
                        "SafeLima es una aplicación diseñada para brindar información y predicciones sobre zonas seguras e inseguras dentro del Cercado de Lima, promoviendo la prevención de incidentes y la seguridad ciudadana.",
                    titleColor: titleColor,
                    bodyColor: bodyColor,
                  ),
                  _termsSection(
                    title: "2. Uso de la ubicación",
                    body:
                        "La aplicación solicita acceso a la ubicación del dispositivo únicamente para mostrar rutas seguras y alertas geográficas en tiempo real. No se comparte ni almacena la ubicación del usuario fuera del dispositivo, garantizando confidencialidad y anonimato.",
                    titleColor: titleColor,
                    bodyColor: bodyColor,
                  ),
                  _termsSection(
                    title: "3. Confidencialidad y protección de datos",
                    body:
                        "Toda la información proporcionada se maneja conforme a la Ley N° 29733 (Perú) – Ley de Protección de Datos Personales. SafeLima no recopila información personal sensible ni realiza seguimiento permanente del usuario.",
                    titleColor: titleColor,
                    bodyColor: bodyColor,
                  ),
                  _termsSection(
                    title: "4. Reportes ciudadanos",
                    body:
                        "Los reportes enviados por los usuarios (título, descripción, foto, nivel de riesgo) serán revisados por administradores y utilizados con fines estadísticos y de mejora del sistema. No se publicarán datos personales.",
                    titleColor: titleColor,
                    bodyColor: bodyColor,
                  ),
                  _termsSection(
                    title: "5. Limitaciones del servicio",
                    body:
                        "SafeLima no reemplaza a las autoridades policiales ni de emergencia. Los niveles de riesgo mostrados son predictivos y pueden variar según condiciones reales. Ante cualquier situación de peligro, comuníquese con la PNP (105) o el Serenazgo de Lima (313-4020).",
                    titleColor: titleColor,
                    bodyColor: bodyColor,
                  ),
                  _termsSection(
                    title: "6. Uso responsable",
                    body:
                        "El usuario se compromete a utilizar la aplicación de forma ética, sin generar reportes falsos o difundir información que cause alarma pública. El mal uso puede resultar en la suspensión temporal de la cuenta.",
                    titleColor: titleColor,
                    bodyColor: bodyColor,
                  ),
                  _termsSection(
                    title: "7. Propiedad intelectual",
                    body:
                        "El contenido, logotipo y código fuente de SafeLima son propiedad del equipo académico desarrollador. Se prohíbe su copia, redistribución o modificación sin autorización.",
                    titleColor: titleColor,
                    bodyColor: bodyColor,
                  ),
                  _termsSection(
                    title: "8. Derechos del usuario",
                    body:
                        "El usuario puede eliminar su cuenta y datos en cualquier momento desde el menú de configuración. La app garantiza transparencia en el manejo de información.",
                    titleColor: titleColor,
                    bodyColor: bodyColor,
                  ),
                  _termsSection(
                    title: "9. Contacto y soporte",
                    body:
                        "Para consultas o sugerencias, comuníquese al correo institucional del proyecto: safelima.soporte@gmail.com.",
                    titleColor: titleColor,
                    bodyColor: bodyColor,
                  ),
                  Text(
                    "Al continuar, confirmas que has leído y aceptas estos términos y condiciones de uso.",
                    style: GoogleFonts.poppins(
                      color: titleColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                "Entendido",
                style: GoogleFonts.poppins(
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _termsSection({
    required String title,
    required String body,
    required Color titleColor,
    required Color bodyColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              color: titleColor,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            body,
            style: GoogleFonts.poppins(
              color: bodyColor,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Color _backgroundColor(bool isDark) {
    return isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
  }

  Color _cardColor(bool isDark) {
    return isDark ? AppColors.cardDark : AppColors.cardLight;
  }

  Color _textColor(bool isDark) {
    return isDark ? AppColors.textDark : AppColors.white;
  }

  Color _inputTextColor(bool isDark) {
    return isDark ? AppColors.textDark : AppColors.textLight;
  }

  Color _subtitleColor(bool isDark) {
    return isDark ? AppColors.subtitleDark : Colors.white70;
  }

  Color _hintColor(bool isDark) {
    return isDark ? AppColors.subtitleDark : AppColors.subtitleLight;
  }

  Color _iconColor(bool isDark) {
    return isDark ? AppColors.subtitleDark : Colors.grey;
  }

  InputDecoration _inputDecoration({
    required bool isDark,
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: _cardColor(isDark),
      hintText: label,
      hintStyle: GoogleFonts.poppins(color: _hintColor(isDark)),
      prefixIcon: Icon(icon, color: _iconColor(isDark)),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: isDark ? AppColors.secondaryDark : AppColors.primary,
          width: 1.5,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _userController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = _backgroundColor(isDark);
    final textColor = _textColor(isDark);
    final subtitleColor = _subtitleColor(isDark);
    final inputTextColor = _inputTextColor(isDark);

    return Scaffold(
      body: Container(
        decoration: isDark
            ? BoxDecoration(color: bgColor)
            : const BoxDecoration(gradient: AppColors.mainGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Image.asset("assets/images/SafeLima.png", height: 120),
                    const SizedBox(height: 10),

                    Text(
                      "Crear Cuenta",
                      style: GoogleFonts.poppins(
                        color: textColor,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 25),

                    _buildTextField(
                      isDark: isDark,
                      controller: _nameController,
                      label: "Nombre completo",
                      icon: Icons.person_outline,
                      textColor: inputTextColor,
                    ),
                    const SizedBox(height: 12),

                    _buildTextField(
                      isDark: isDark,
                      controller: _emailController,
                      label: "Correo electrónico",
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textColor: inputTextColor,
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return "Ingrese Correo electrónico";
                        final emailRegex = RegExp(
                          r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                        );
                        if (!emailRegex.hasMatch(value)) {
                          return "Ingrese un correo válido";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    _buildTextField(
                      isDark: isDark,
                      controller: _userController,
                      label: "Usuario",
                      icon: Icons.account_circle_outlined,
                      textColor: inputTextColor,
                    ),
                    const SizedBox(height: 12),

                    _buildPasswordField(
                      isDark: isDark,
                      controller: _passController,
                      label: "Contraseña",
                      isVisible: _isPasswordVisible,
                      textColor: inputTextColor,
                      toggleVisibility: () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildPasswordField(
                      isDark: isDark,
                      controller: _confirmPassController,
                      label: "Confirmar contraseña",
                      isVisible: _isConfirmPasswordVisible,
                      textColor: inputTextColor,
                      toggleVisibility: () => setState(
                        () => _isConfirmPasswordVisible =
                            !_isConfirmPasswordVisible,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return "Ingrese Confirmar contraseña";
                        }
                        if (v != _passController.text) {
                          return "Las contraseñas no coinciden";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 15),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.cardDark.withOpacity(0.8)
                            : Colors.white.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _acceptTerms,
                            onChanged: (v) =>
                                setState(() => _acceptTerms = v ?? false),
                            activeColor: isDark
                                ? AppColors.secondaryDark
                                : AppColors.white,
                            checkColor: isDark
                                ? AppColors.white
                                : AppColors.primary,
                            side: BorderSide(
                              color: isDark
                                  ? AppColors.subtitleDark
                                  : Colors.white70,
                            ),
                          ),
                          Expanded(
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  "Acepto los ",
                                  style: GoogleFonts.poppins(
                                    color: subtitleColor,
                                    fontSize: 13,
                                  ),
                                ),
                                InkWell(
                                  onTap: _showTermsAndConditions,
                                  borderRadius: BorderRadius.circular(4),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Text(
                                      "Términos y condiciones",
                                      style: GoogleFonts.poppins(
                                        color: isDark
                                            ? AppColors.secondaryDark
                                            : AppColors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        decoration: TextDecoration.underline,
                                        decorationColor: isDark
                                            ? AppColors.secondaryDark
                                            : AppColors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),

                    _isLoading
                        ? CircularProgressIndicator(
                            color: isDark
                                ? AppColors.secondaryDark
                                : AppColors.white,
                          )
                        : SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _onRegisterPressed,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark
                                    ? AppColors.primaryDark
                                    : AppColors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                "Registrarse",
                                style: GoogleFonts.poppins(
                                  color: isDark
                                      ? AppColors.white
                                      : AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),

                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "¿Ya tienes una cuenta? ",
                          style: GoogleFonts.poppins(
                            color: subtitleColor,
                            fontSize: 13,
                          ),
                        ),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LoginScreenUser(),
                                    ),
                                  );
                                },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            "Inicia sesión",
                            style: GoogleFonts.poppins(
                              color: isDark
                                  ? AppColors.secondaryDark
                                  : AppColors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildTextField({
    required bool isDark,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color textColor,
    TextInputType keyboardType = TextInputType.text,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(color: textColor),
      validator:
          validator ??
          (v) => v == null || v.trim().isEmpty ? "Ingrese $label" : null,
      decoration: _inputDecoration(isDark: isDark, label: label, icon: icon),
    );
  }

  Widget _buildPasswordField({
    required bool isDark,
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback toggleVisibility,
    required Color textColor,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      style: GoogleFonts.poppins(color: textColor),
      validator:
          validator ?? (v) => v == null || v.isEmpty ? "Ingrese $label" : null,
      decoration: _inputDecoration(
        isDark: isDark,
        label: label,
        icon: Icons.lock_outline,
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            color: _iconColor(isDark),
          ),
          onPressed: toggleVisibility,
        ),
      ),
    );
  }
}
