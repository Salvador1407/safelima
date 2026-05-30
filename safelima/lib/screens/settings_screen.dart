import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:safelima/core/app_colors.dart';
import 'package:safelima/core/app_data.dart';
import 'package:safelima/screens/splash_screen.dart';
import 'package:safelima/services/app_notification_service.dart';
import 'package:safelima/services/user_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:safelima/models/app_feedback.dart';
import 'package:safelima/services/app_feedback_service.dart';
import 'package:safelima/services/notification_settings_service.dart';

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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(_notificationUpdateErrorMessage),
          backgroundColor: AppColors.danger,
        ),
      );
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

          setState(() {
            _notificationsEnabled = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Permiso de notificaciones denegado"),
              backgroundColor: AppColors.danger,
            ),
          );
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(_notificationUpdateErrorMessage),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _mostrarDialogoFeedback() {
    final theme = Theme.of(context);
    final comentarioController = TextEditingController();
    int estrellasSeleccionadas = 0;
    bool enviando = false;

    showDialog(
      context: context,
      barrierDismissible: !enviando,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                "Califica SafeLima",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "¿Cómo fue tu experiencia general en la app?",
                      style: theme.textTheme.bodyMedium,
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
                      decoration: InputDecoration(
                        labelText: "Comentario (opcional)",
                        hintText: "Cuéntanos qué podríamos mejorar",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: enviando ? null : () => Navigator.pop(context),
                  child: const Text(
                    "Cancelar",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: enviando
                      ? null
                      : () async {
                          if (estrellasSeleccionadas == 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Selecciona una calificación de 1 a 5 estrellas.",
                                ),
                              ),
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

                            if (!mounted) return;
                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Gracias por calificar SafeLima.",
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            setStateDialog(() {
                              enviando = false;
                            });

                            final errorText = e.toString().toLowerCase();

                            if (errorText.contains("409") ||
                                errorText.contains(
                                  "ya registró una calificación",
                                ) ||
                                errorText.contains("ya calificó")) {
                              Navigator.pop(context);

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Ya registraste tu calificación anteriormente.",
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "No se pudo enviar tu opinión. Inténtalo nuevamente.",
                                ),
                              ),
                            );
                          }
                        },
                  child: enviando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Enviar",
                          style: TextStyle(color: Colors.white),
                        ),
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

  Future<void> _showTermsAndConditions() async {
    final connected = await _hasConnection();

    if (!mounted) return;

    if (!connected) {
      setState(() {
        isConnected = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(_termsConnectionErrorMessage),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurface.withOpacity(0.9),
      height: 1.45,
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          "Términos y Condiciones de SafeLima",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
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
            child: const Text(
              "Cerrar",
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "No tienes conexión a internet. No se pudo cerrar sesión.",
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

    final authService = AuthService();
    await authService.logout();
    AppData.citizen_id = 0;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Sesión cerrada correctamente.",
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.secundary,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (route) => false,
    );
  }

  void _eliminarCuenta() {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          "Eliminar cuenta",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.redAccent,
          ),
        ),
        content: const Text(
          "¿Estás seguro de que deseas eliminar tu cuenta? Tu información será desactivada y no podrás acceder hasta reactivarla nuevamente.",
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              try {
                final connected = await _hasConnection();
                if (!mounted) return;

                if (!connected) {
                  setState(() {
                    isConnected = false;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("No se pudo eliminar la cuenta"),
                      backgroundColor: AppColors.danger,
                    ),
                  );
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

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Cuenta eliminada correctamente."),
                    backgroundColor: Colors.redAccent,
                  ),
                );

                await storage.deleteAll();
                if (!mounted) return;

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const SplashScreen()),
                  (route) => false,
                );
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("No se pudo eliminar la cuenta: $e")),
                );
              }
            },
            child: const Text(
              "Eliminar",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseTextStyle = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Configuración",
          style: baseTextStyle.titleLarge?.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secundary],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            ListTile(
              leading: Icon(
                isConnected ? Icons.wifi : Icons.wifi_off,
                color: isConnected ? Colors.green : Colors.redAccent,
              ),
              title: Text(
                "Estado de conexión",
                style: baseTextStyle.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                isConnected ? "Conectado" : "Sin conexión",
                style: baseTextStyle.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),

            SwitchListTile(
              secondary: const Icon(
                Icons.notifications_active_rounded,
                color: AppColors.primary,
              ),
              title: const Text("Activar notificaciones"),
              subtitle: const Text(
                "Activa o desactiva todas las alertas de SafeLima",
              ),
              value: _notificationsEnabled,
              activeThumbColor: AppColors.primary,
              onChanged: _toggleNotifications,
            ),

            ListTile(
              leading: const Icon(
                Icons.description_rounded,
                color: AppColors.primary,
              ),
              title: const Text("Términos y condiciones de uso"),
              onTap: _showTermsAndConditions,
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),

            ListTile(
              leading: const Icon(Icons.star_rate_rounded, color: Colors.amber),
              title: const Text("Calificar la aplicación"),
              subtitle: const Text("Ayúdanos a mejorar SafeLima"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _mostrarDialogoFeedback,
            ),

            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.orange),
              title: const Text("Cerrar sesión"),
              onTap: _cerrarSesion,
            ),

            ListTile(
              leading: const Icon(
                Icons.delete_forever_rounded,
                color: Colors.redAccent,
              ),
              title: const Text("Eliminar cuenta"),
              onTap: _eliminarCuenta,
            ),
          ],
        ),
      ),
    );
  }
}
