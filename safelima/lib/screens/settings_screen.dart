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
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;

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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: borderColor, width: 0.9),
              ),
              title: Text(
                "Califica SafeLima",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                  color: isDark ? AppColors.secondaryDark : AppColors.primary,
                ),
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
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starIndex = index + 1;
                        return IconButton(
                          onPressed: () {
                            setStateDialog(() {
                              estrellasSeleccionadas = starIndex;
                            });
                          },
                          icon: Icon(
                            starIndex <= estrellasSeleccionadas
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: Colors.amber,
                            size: 34,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: comentarioController,
                      maxLines: 4,
                      maxLength: 300,
                      style: GoogleFonts.poppins(color: textColor),
                      decoration: safeInputDecoration(
                        context,
                        labelText: "Comentario (opcional)",
                        hintText: "Cuéntanos qué podríamos mejorar",
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: enviando
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: Text(
                    "Cancelar",
                    style: GoogleFonts.poppins(
                      color: isDark
                          ? AppColors.subtitleDark
                          : AppColors.subtitleLight,
                      fontWeight: FontWeight.w600,
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

  Widget _settingsCard({required Widget child}) {
    return SafeCard(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: EdgeInsets.zero,
      child: child,
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
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.90),
      height: 1.45,
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: borderColor, width: 0.9),
        ),
        title: Text(
          "Términos y Condiciones de SafeLima",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: isDark ? AppColors.secondaryDark : AppColors.primary,
          ),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cerrar",
              style: GoogleFonts.poppins(
                color: isDark ? AppColors.secondaryDark : AppColors.primary,
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final subtitleColor = isDark
        ? AppColors.subtitleDark
        : AppColors.subtitleLight;
    final primaryColor = isDark ? AppColors.secondaryDark : AppColors.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Configuración",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: isDark
            ? null
            : Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.mainGradient,
                ),
              ),
        backgroundColor: isDark ? AppColors.backgroundDark : null,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            _settingsCard(
              child: ListTile(
                leading: Icon(
                  isConnected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                  color: isConnected ? AppColors.success : AppColors.danger,
                ),
                title: Text(
                  "Estado de conexión",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  isConnected ? "Conectado" : "Sin conexión",
                  style: GoogleFonts.poppins(
                    color: subtitleColor,
                    fontSize: 13,
                  ),
                ),
                trailing: SafeStatusChip(
                  label: isConnected ? "CONECTADO" : "SIN RED",
                  tone: isConnected
                      ? SafeStatusTone.success
                      : SafeStatusTone.danger,
                ),
              ),
            ),
            _settingsCard(
              child: SwitchListTile(
                secondary: Icon(
                  Icons.notifications_active_rounded,
                  color: primaryColor,
                ),
                title: Text(
                  "Activar notificaciones",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  "Activa o desactiva todas las alertas de SafeLima",
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: subtitleColor,
                  ),
                ),
                value: _notificationsEnabled,
                activeThumbColor: isDark
                    ? AppColors.secondaryDark
                    : AppColors.primary,
                activeTrackColor:
                    (isDark ? AppColors.secondaryDark : AppColors.primary)
                        .withValues(alpha: 0.3),
                onChanged: _toggleNotifications,
              ),
            ),
            _settingsCard(
              child: ListTile(
                leading: Icon(Icons.description_rounded, color: primaryColor),
                title: Text(
                  "Términos y condiciones de uso",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    fontSize: 15,
                  ),
                ),
                onTap: _showTermsAndConditions,
                trailing: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: subtitleColor,
                ),
              ),
            ),
            _settingsCard(
              child: ListTile(
                leading: const Icon(
                  Icons.star_rate_rounded,
                  color: Colors.amber,
                ),
                title: Text(
                  "Calificar la aplicación",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  "Ayúdanos a mejorar SafeLima",
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: subtitleColor,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: subtitleColor,
                ),
                onTap: _mostrarDialogoFeedback,
              ),
            ),
            _settingsCard(
              child: ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.orange),
                title: Text(
                  "Cerrar sesión",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    fontSize: 15,
                  ),
                ),
                onTap: _cerrarSesion,
              ),
            ),
            _settingsCard(
              child: ListTile(
                leading: const Icon(
                  Icons.delete_forever_rounded,
                  color: AppColors.danger,
                ),
                title: Text(
                  "Eliminar cuenta",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    fontSize: 15,
                  ),
                ),
                onTap: _eliminarCuenta,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
