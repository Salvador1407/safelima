import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safelima/core/app_colors.dart';
import 'package:safelima/core/app_data.dart';
import 'package:safelima/screens/splash_screen.dart';
import 'package:safelima/services/app_notification_service.dart';
import 'package:safelima/services/user_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:safelima/models/app_feedback.dart';
import 'package:safelima/services/app_feedback_service.dart';
import 'package:safelima/services/notification_settings_service.dart';
import 'package:safelima/widgets/safe_buttons.dart';
import 'package:safelima/widgets/safe_card.dart';
import 'package:safelima/widgets/safe_dialog.dart';
import 'package:safelima/widgets/safe_input_decoration.dart';
import 'package:safelima/widgets/safe_snack_bar.dart';
import 'package:safelima/widgets/safe_status_chip.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isConnected = true;
  bool _notificationsEnabled = true;

  static const String _notificationUpdateErrorMessage =
      "No se pudo actualizar el estado de las notificaciones";
  static const String _termsConnectionErrorMessage =
      "No tienes conexión a internet. No se pudieron cargar los términos y condiciones.";

  late StreamSubscription<List<ConnectivityResult>> _subscription;

  final UserService _userService = UserService();
  final storage = const FlutterSecureStorage();
  final AppFeedbackService _appFeedbackService = AppFeedbackService();
  final NotificationSettingsService _notificationSettingsService =
      NotificationSettingsService();

  @override
  void initState() {
    super.initState();
    _checkInitialConnection();
    _loadNotificationSettings();

    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final result = results.isNotEmpty
          ? results.first
          : ConnectivityResult.none;
      if (!mounted) return;
      setState(() {
        isConnected = result != ConnectivityResult.none;
      });
    });
  }

  Future<void> _checkInitialConnection() async {
    final results = await Connectivity().checkConnectivity();
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
    if (!mounted) return;
    setState(() {
      isConnected = result != ConnectivityResult.none;
    });
  }

  Future<bool> _hasConnection() async {
    final results = await Connectivity().checkConnectivity();
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;

    if (result == ConnectivityResult.none) {
      return false;
    }

    try {
      final lookupResult = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 3));

      return lookupResult.isNotEmpty &&
          lookupResult.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    }
  }

  Future<void> _loadNotificationSettings() async {
    final enabled = await _notificationSettingsService
        .getNotificationsEnabled();
    if (!enabled) return;

    if (!mounted) return;
    setState(() {
      _notificationsEnabled = enabled;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final previousValue = _notificationsEnabled;
    final connected = await _hasConnection();

    if (!mounted) return;

    if (!connected) {
      setState(() {
        isConnected = false;
        _notificationsEnabled = previousValue;
      });

      SafeSnackBar.showError(context, _notificationUpdateErrorMessage);
      return;
    }

    try {
      await _notificationSettingsService.setNotificationsEnabled(value);

      if (!mounted) return;

      setState(() {
        isConnected = true;
        _notificationsEnabled = value;
      });

      if (value) {
        final granted = await AppNotificationService.requestPermission();

        if (!mounted) return;

        if (!granted) {
          await _notificationSettingsService.setNotificationsEnabled(false);

          if (!mounted) return;

          setState(() {
            _notificationsEnabled = false;
          });

          SafeSnackBar.showError(context, "Permiso de notificaciones denegado");
          return;
        }

        await AppNotificationService.showNow();
      }
    } catch (e) {
      debugPrint("Error técnico al actualizar notificaciones: $e");

      if (!mounted) return;

      setState(() {
        _notificationsEnabled = previousValue;
      });

      SafeSnackBar.showError(context, _notificationUpdateErrorMessage);
    }
  }

  void _mostrarDialogoFeedback() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = _cardColor(isDark);
    final borderColor = _borderColor(isDark);
    final textColor = _textColor(isDark);
    final subtitleColor = _subtitleColor(isDark);
    final accentColor = _accentColor(isDark);

    final comentarioController = TextEditingController();
    int estrellasSeleccionadas = 0;
    bool enviando = false;

    showDialog(
      context: context,
      barrierDismissible: !enviando,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            return AlertDialog(
              backgroundColor: cardColor,
              elevation: 0,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
                side: BorderSide(
                  color: borderColor.withValues(alpha: isDark ? 0.65 : 0.85),
                  width: 0.9,
                ),
              ),
              title: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(
                        alpha: isDark ? 0.18 : 0.12,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.star_rate_rounded,
                      color: AppColors.accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Califica SafeLima",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: accentColor,
                        letterSpacing: -0.15,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "¿Cómo fue tu experiencia general en la app?",
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        height: 1.35,
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.backgroundDark.withValues(alpha: 0.42)
                            : AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: borderColor.withValues(
                            alpha: isDark ? 0.48 : 0.80,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final starIndex = index + 1;
                          final selected =
                              starIndex <= estrellasSeleccionadas;

                          return InkWell(
                            onTap: enviando
                                ? null
                                : () {
                                    setStateDialog(() {
                                      estrellasSeleccionadas = starIndex;
                                    });
                                  },
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              curve: Curves.easeOut,
                              width: 42,
                              height: 42,
                              alignment: Alignment.center,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selected
                                    ? AppColors.accent.withValues(
                                        alpha: isDark ? 0.18 : 0.12,
                                      )
                                    : Colors.transparent,
                              ),
                              child: Icon(
                                selected
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                color: selected
                                    ? AppColors.accent
                                    : subtitleColor.withValues(alpha: 0.65),
                                size: 31,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: comentarioController,
                      maxLines: 4,
                      maxLength: 300,
                      enabled: !enviando,
                      style: GoogleFonts.poppins(
                        color: textColor,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                      cursorColor: accentColor,
                      decoration: safeInputDecoration(
                        context,
                        labelText: "Comentario (opcional)",
                        hintText: "Cuéntanos qué podríamos mejorar",
                      ).copyWith(
                        counterStyle: GoogleFonts.poppins(
                          color: subtitleColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              actions: [
                TextButton(
                  onPressed: enviando
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: Text(
                    "Cancelar",
                    style: GoogleFonts.poppins(
                      color: subtitleColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SafeButton(
                  label: "Enviar",
                  isLoading: enviando,
                  onPressed: enviando
                      ? null
                      : () async {
                          if (estrellasSeleccionadas == 0) {
                            SafeSnackBar.showWarning(
                              dialogContext,
                              "Selecciona una calificación de 1 a 5 estrellas.",
                            );
                            return;
                          }

                          setStateDialog(() {
                            enviando = true;
                          });

                          try {
                            final feedback = AppFeedback(
                              citizenId: AppData.citizen_id,
                              estrellas: estrellasSeleccionadas,
                              comentario:
                                  comentarioController.text.trim().isEmpty
                                      ? null
                                      : comentarioController.text.trim(),
                            );

                            await _appFeedbackService.createFeedback(feedback);

                            if (!mounted || !dialogContext.mounted) return;
                            Navigator.pop(dialogContext);

                            SafeSnackBar.showSuccess(
                              context,
                              "Gracias por calificar SafeLima.",
                            );
                          } catch (e) {
                            if (!mounted || !dialogContext.mounted) return;
                            setStateDialog(() {
                              enviando = false;
                            });

                            final errorText = e.toString().toLowerCase();

                            if (errorText.contains("409") ||
                                errorText.contains(
                                  "ya registró una calificación",
                                ) ||
                                errorText.contains("ya calificó")) {
                              Navigator.pop(dialogContext);

                              SafeSnackBar.showWarning(
                                context,
                                "Ya registraste tu calificación anteriormente.",
                              );
                              return;
                            }

                            SafeSnackBar.showError(
                              context,
                              "No se pudo enviar tu opinión. Inténtalo nuevamente.",
                            );
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Color _backgroundColor(bool isDark) {
    return isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
  }

  Color _cardColor(bool isDark) {
    return isDark ? AppColors.cardDark : AppColors.cardLight;
  }

  Color _textColor(bool isDark) {
    return isDark ? AppColors.textDark : AppColors.textLight;
  }

  Color _subtitleColor(bool isDark) {
    return isDark ? AppColors.subtitleDark : AppColors.subtitleLight;
  }

  Color _borderColor(bool isDark) {
    return isDark ? AppColors.borderDark : AppColors.borderLight;
  }

  Color _accentColor(bool isDark) {
    return isDark ? AppColors.secondaryDark : AppColors.primary;
  }

  LinearGradient _appBarGradient(bool isDark) {
    return isDark
        ? const LinearGradient(
            colors: [
              AppColors.primaryDark,
              Color(0xFF102A43),
              AppColors.backgroundDark,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.secundary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
  }

  List<BoxShadow> _softShadow(bool isDark) {
    return [
      BoxShadow(
        color: AppColors.black.withValues(alpha: isDark ? 0.24 : 0.08),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ];
  }

  Widget _settingsCard({
    required Widget child,
    required bool isDark,
    EdgeInsetsGeometry margin = const EdgeInsets.fromLTRB(16, 0, 16, 12),
  }) {
    return SafeCard(
      margin: margin,
      padding: EdgeInsets.zero,
      backgroundColor: _cardColor(isDark),
      borderColor: _borderColor(isDark).withValues(alpha: isDark ? 0.55 : 0.85),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: child,
      ),
    );
  }

  Future<void> _showTermsAndConditions() async {
    final connected = await _hasConnection();

    if (!mounted) return;

    if (!connected) {
      setState(() {
        isConnected = false;
      });

      SafeSnackBar.showError(context, _termsConnectionErrorMessage);
      return;
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = _cardColor(isDark);
    final borderColor = _borderColor(isDark);
    final accentColor = _accentColor(isDark);

    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.90),
      height: 1.45,
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardColor,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: BorderSide(
            color: borderColor.withValues(alpha: isDark ? 0.65 : 0.85),
            width: 0.9,
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: isDark ? 0.18 : 0.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                Icons.description_rounded,
                color: accentColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Términos y Condiciones de SafeLima",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: accentColor,
                  letterSpacing: -0.15,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text("""
1. Finalidad del servicio  
SafeLima es una aplicación diseñada para brindar información y predicciones sobre zonas seguras e inseguras dentro del Cercado de Lima, promoviendo la prevención de incidentes y la seguridad ciudadana.

2. Uso de la ubicación  
La aplicación solicita acceso a la ubicación del dispositivo únicamente para mostrar rutas seguras y alertas geográficas en tiempo real. No se comparte ni almacena la ubicación del usuario fuera del dispositivo, garantizando confidencialidad y anonimato.

3. Confidencialidad y protección de datos  
Toda la información proporcionada se maneja conforme a la Ley N° 29733 (Perú) – Ley de Protección de Datos Personales. SafeLima no recopila información personal sensible ni realiza seguimiento permanente del usuario.

4. Reportes ciudadanos  
Los reportes enviados por los usuarios (título, descripción, foto, nivel de riesgo) serán revisados por administradores y utilizados con fines estadísticos y de mejora del sistema. No se publicarán datos personales.

5. Limitaciones del servicio  
SafeLima no reemplaza a las autoridades policiales ni de emergencia. Los niveles de riesgo mostrados son predictivos y pueden variar según condiciones reales. Ante cualquier situación de peligro, comuníquese con la PNP (105) o el Serenazgo de Lima (313-4020).

6. Uso responsable  
El usuario se compromete a utilizar la aplicación de forma ética, sin generar reportes falsos o difundir información que cause alarma pública. El mal uso puede resultar en la suspensión temporal de la cuenta.

7. Propiedad intelectual  
El contenido, logotipo y código fuente de SafeLima son propiedad del equipo académico desarrollador. Se prohíbe su copia, redistribución o modificación sin autorización.

8. Derechos del usuario  
El usuario puede eliminar su cuenta y datos en cualquier momento desde el menú de configuración. La app garantiza transparencia en el manejo de información.

9. Contacto y soporte  
Para consultas o sugerencias, comuníquese al correo institucional del proyecto: safelima.soporte@gmail.com.

Al continuar, confirmas que has leído y aceptas estos términos y condiciones de uso.
""", style: textStyle),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cerrar",
              style: GoogleFonts.poppins(
                color: accentColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _cerrarSesion() async {
    final connected = await _hasConnection();
    if (!mounted) return;

    if (!connected) {
      setState(() {
        isConnected = false;
      });
      SafeSnackBar.showError(
        context,
        "No tienes conexión a internet. No se pudo cerrar sesión.",
      );
      return;
    }

    final authService = AuthService();
    await authService.logout();
    AppData.citizen_id = 0;

    if (!mounted) return;
    SafeSnackBar.showSuccess(context, "Sesión cerrada correctamente.");

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (route) => false,
    );
  }

  void _eliminarCuenta() async {
    final confirm = await SafeDialog.showConfirmation(
      context,
      title: "Eliminar cuenta",
      content:
          "¿Estás seguro de que deseas eliminar tu cuenta? Tu información será desactivada y no podrás acceder hasta reactivarla nuevamente.",
      confirmLabel: "Eliminar",
      cancelLabel: "Cancelar",
      icon: Icons.delete_forever_rounded,
      iconColor: AppColors.danger,
    );

    if (confirm != true) return;

    try {
      final connected = await _hasConnection();
      if (!mounted) return;

      if (!connected) {
        setState(() {
          isConnected = false;
        });
        SafeSnackBar.showError(context, "No se pudo eliminar la cuenta");
        return;
      }

      final userIdString = await storage.read(key: "user_id");

      if (userIdString == null) {
        throw Exception("No se encontró el ID de usuario");
      }

      final userId = int.parse(userIdString);

      Map<String, dynamic> updateResponse = {"enable": false};
      await _userService.updateUser(userId, updateResponse);

      if (!mounted) return;

      SafeSnackBar.showSuccess(context, "Cuenta eliminada correctamente.");

      await storage.deleteAll();
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      SafeSnackBar.showError(context, "No se pudo eliminar la cuenta");
    }
  }

  Widget _buildHeaderCard({
    required bool isDark,
    required Color textColor,
    required Color subtitleColor,
  }) {
    final accentColor = _accentColor(isDark);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: isDark
            ? null
            : const LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.secundary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: isDark ? _cardColor(isDark) : null,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? _borderColor(isDark).withValues(alpha: 0.75)
              : AppColors.white.withValues(alpha: 0.34),
        ),
        boxShadow: _softShadow(isDark),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -42,
            right: -34,
            child: Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withValues(alpha: isDark ? 0.04 : 0.10),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isDark
                      ? accentColor.withValues(alpha: 0.18)
                      : AppColors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? accentColor.withValues(alpha: 0.25)
                        : AppColors.white.withValues(alpha: 0.24),
                  ),
                ),
                child: Icon(
                  Icons.settings_rounded,
                  color: isDark ? accentColor : AppColors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  "Configuración",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? textColor : AppColors.white,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required bool isDark,
    required IconData icon,
    required String title,
    String? subtitle,
    required Color iconColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final textColor = _textColor(isDark);
    final subtitleColor = _subtitleColor(isDark);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: isDark ? 0.16 : 0.10),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: iconColor, size: 23),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w800,
          color: textColor,
          fontSize: 15,
          letterSpacing: -0.1,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: subtitleColor,
                  height: 1.32,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
      trailing: trailing ??
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: subtitleColor,
          ),
    );
  }

  Widget _buildNotificationSwitchTile({
    required bool isDark,
    required Color primaryColor,
    required Color textColor,
    required Color subtitleColor,
  }) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      secondary: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: isDark ? 0.16 : 0.10),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.notifications_active_rounded,
          color: primaryColor,
          size: 23,
        ),
      ),
      title: Text(
        "Activar notificaciones",
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w800,
          color: textColor,
          fontSize: 15,
          letterSpacing: -0.1,
        ),
      ),
      subtitle: Text(
        "Activa o desactiva todas las alertas de SafeLima",
        style: GoogleFonts.poppins(
          fontSize: 12.5,
          color: subtitleColor,
          height: 1.32,
          fontWeight: FontWeight.w500,
        ),
      ),
      value: _notificationsEnabled,
      activeThumbColor: primaryColor,
      activeTrackColor: primaryColor.withValues(alpha: 0.3),
      onChanged: _toggleNotifications,
    );
  }

  Widget _buildDangerCard({
    required bool isDark,
    required Color textColor,
    required Color subtitleColor,
  }) {
    return SafeCard(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: EdgeInsets.zero,
      backgroundColor: _cardColor(isDark),
      borderColor: AppColors.danger.withValues(alpha: isDark ? 0.36 : 0.22),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          children: [
            _buildSettingsTile(
              isDark: isDark,
              icon: Icons.delete_forever_rounded,
              title: "Eliminar cuenta",
              iconColor: AppColors.danger,
              onTap: _eliminarCuenta,
              trailing: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: subtitleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = _backgroundColor(isDark);
    final textColor = _textColor(isDark);
    final subtitleColor = _subtitleColor(isDark);
    final primaryColor = _accentColor(isDark);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.white,
        titleSpacing: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: _appBarGradient(isDark),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: isDark ? 0.30 : 0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
        ),
        title: Text(
          "Configuración",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.white,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 18),
          children: [
            _buildHeaderCard(
              isDark: isDark,
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            _settingsCard(
              isDark: isDark,
              child: _buildSettingsTile(
                isDark: isDark,
                icon: isConnected
                    ? Icons.wifi_rounded
                    : Icons.wifi_off_rounded,
                title: "Estado de conexión",
                subtitle: isConnected ? "Conectado" : "Sin conexión",
                iconColor: isConnected ? AppColors.success : AppColors.danger,
                trailing: SafeStatusChip(
                  label: isConnected ? "CONECTADO" : "SIN RED",
                  tone: isConnected
                      ? SafeStatusTone.success
                      : SafeStatusTone.danger,
                ),
              ),
            ),
            _settingsCard(
              isDark: isDark,
              child: _buildNotificationSwitchTile(
                isDark: isDark,
                primaryColor: primaryColor,
                textColor: textColor,
                subtitleColor: subtitleColor,
              ),
            ),
            _settingsCard(
              isDark: isDark,
              child: _buildSettingsTile(
                isDark: isDark,
                icon: Icons.description_rounded,
                title: "Términos y condiciones de uso",
                iconColor: primaryColor,
                onTap: _showTermsAndConditions,
              ),
            ),
            _settingsCard(
              isDark: isDark,
              child: _buildSettingsTile(
                isDark: isDark,
                icon: Icons.star_rate_rounded,
                title: "Calificar la aplicación",
                subtitle: "Ayúdanos a mejorar SafeLima",
                iconColor: AppColors.accent,
                onTap: _mostrarDialogoFeedback,
              ),
            ),
            _settingsCard(
              isDark: isDark,
              child: _buildSettingsTile(
                isDark: isDark,
                icon: Icons.logout_rounded,
                title: "Cerrar sesión",
                iconColor: AppColors.warning,
                onTap: _cerrarSesion,
                trailing: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: subtitleColor,
                ),
              ),
            ),
            _buildDangerCard(
              isDark: isDark,
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
          ],
        ),
      ),
    );
  }
}