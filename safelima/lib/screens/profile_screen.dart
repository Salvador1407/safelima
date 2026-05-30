import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safelima/core/app_colors.dart';
import 'package:safelima/theme/theme_notifier.dart';
import 'package:safelima/models/citizen.dart';
import 'package:safelima/services/citizen_service.dart';
import 'package:safelima/core/app_data.dart';
import 'package:safelima/widgets/safe_buttons.dart';
import 'package:safelima/widgets/safe_card.dart';
import 'package:safelima/widgets/safe_empty_state.dart';
import 'package:safelima/widgets/safe_input_decoration.dart';
import 'package:safelima/widgets/safe_snack_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final CitizenService _citizenService = CitizenService();
  final _formKey = GlobalKey<FormState>();

  late Future<Citizen?> _futureCitizen;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();

  static const String _noProfileDataMessage = "No se encontraron datos";
  static const String _noInternetMessage = "No tienes conexión a internet";

  bool notificationsEnabled = false;
  String _avatar = "😀";
  String _profileLoadMessage = "No se encontraron datos.";
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadLocalPreferences();
    _futureCitizen = _loadResult();
  }

  Future<void> _loadLocalPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
      _avatar = prefs.getString('selected_avatar') ?? "😀";
    });
  }

  Future<bool> _hasInternet() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) return false;

    try {
      final result = await InternetAddress.lookup(
        'example.com',
      ).timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    }
  }

  Future<Citizen?> _loadResult() async {
    try {
      final id = AppData.citizen_id;
      final connected = await _hasInternet();

      if (!connected) {
        _nameController.clear();
        _correoController.clear();
        _profileLoadMessage = _noProfileDataMessage;
        return null;
      }

      _profileLoadMessage = _noProfileDataMessage;
      return await _citizenService.getCitizenById(id);
    } catch (e) {
      debugPrint("Error al obtener ciudadano: $e");
      _nameController.clear();
      _correoController.clear();
      _profileLoadMessage = _noProfileDataMessage;
      return null;
    }
  }

  Future<void> _saveCitizenChanges() async {
    try {
      if (!_formKey.currentState!.validate()) return;

      setState(() => _isSaving = true);
      final connected = await _hasInternet();
      if (!mounted) {
        setState(() => _isSaving = false);
        return;
      }

      if (!connected) {
        setState(() => _isSaving = false);
        SafeSnackBar.showError(context, _noInternetMessage);
        return;
      }

      final id = AppData.citizen_id;
      final updatedData = {
        "full_name": _nameController.text.trim(),
        "correo": _correoController.text.trim(),
      };

      await _citizenService.updateCitizen(id, updatedData);

      if (!mounted) {
        setState(() => _isSaving = false);
        return;
      }
      setState(() => _isSaving = false);
      SafeSnackBar.showSuccess(context, "Perfil actualizado correctamente");
    } catch (e) {
      if (!mounted) {
        setState(() => _isSaving = false);
        return;
      }
      setState(() => _isSaving = false);
      SafeSnackBar.showError(context, "No se pudo actualizar el perfil");
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() => notificationsEnabled = value);
  }

  void _showAvatarSelector() {
    final emojis = ["😀", "😎", "🤗", "🦊", "🐼", "🥰", "😴", "🥳"];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: borderColor, width: 0.9),
        ),
        title: Text(
          "Selecciona tu avatar",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: textColor,
          ),
        ),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: emojis.map((e) {
            return GestureDetector(
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('selected_avatar', e);
                if (!mounted) return;
                setState(() => _avatar = e);
                Navigator.pop(context);
              },
              child: Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.backgroundDark
                      : AppColors.backgroundLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 0.9),
                ),
                child: Text(e, style: const TextStyle(fontSize: 28)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final primaryColor = isDark ? AppColors.secondaryDark : AppColors.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Perfil"),
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
      body: FutureBuilder<Citizen?>(
        future: _futureCitizen,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          if (!snapshot.hasData) {
            return SafeEmptyState(
              icon: Icons.person_off_outlined,
              title: _profileLoadMessage,
            );
          }

          final citizen = snapshot.data!;
          _nameController.text = citizen.fullName ?? "";
          _correoController.text = citizen.correo ?? "";

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              children: [
                // 👤 Avatar Card
                SafeCard(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 104,
                            height: 104,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.backgroundDark
                                  : AppColors.backgroundLight,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? AppColors.borderDark
                                    : AppColors.borderLight,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              _avatar,
                              style: const TextStyle(fontSize: 54),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _showAvatarSelector,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.white,
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.edit_rounded,
                                  color: AppColors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        citizen.user?.nameuser ?? "@ciudadano",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ✏️ Nombre completo
                TextFormField(
                  controller: _nameController,
                  style: GoogleFonts.poppins(color: textColor),
                  decoration: safeInputDecoration(
                    context,
                    labelText: "Nombre completo",
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Ingrese su nombre completo";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // ✉️ Correo
                TextFormField(
                  controller: _correoController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.poppins(color: textColor),
                  decoration: safeInputDecoration(
                    context,
                    labelText: "Correo electrónico",
                    prefixIcon: Icons.email_outlined,
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? "";
                    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                    if (!emailRegex.hasMatch(email)) {
                      return "Ingrese un correo válido";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // 🔔 Notificaciones
                SafeCard(
                  padding: EdgeInsets.zero,
                  child: SwitchListTile(
                    title: Text(
                      "Recibir notificaciones",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    secondary: const Icon(Icons.notifications_active_outlined),
                    value: notificationsEnabled,
                    activeThumbColor: isDark
                        ? AppColors.secondaryDark
                        : AppColors.primary,
                    activeTrackColor:
                        (isDark ? AppColors.secondaryDark : AppColors.primary)
                            .withValues(alpha: 0.3),
                    onChanged: _toggleNotifications,
                  ),
                ),

                const SizedBox(height: 12),

                // 🌙 Tema oscuro
                SafeCard(
                  padding: EdgeInsets.zero,
                  child: SwitchListTile(
                    title: Text(
                      "Tema oscuro",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    secondary: const Icon(Icons.dark_mode_outlined),
                    value: context.watch<ThemeNotifier>().isDarkMode,
                    activeThumbColor: isDark
                        ? AppColors.secondaryDark
                        : AppColors.primary,
                    activeTrackColor:
                        (isDark ? AppColors.secondaryDark : AppColors.primary)
                            .withValues(alpha: 0.3),
                    onChanged: (val) {
                      context.read<ThemeNotifier>().toggleTheme(val);
                      SafeSnackBar.showInfo(
                        context,
                        val ? "Tema oscuro activado" : "Tema claro activado",
                      );
                    },
                  ),
                ),

                const SizedBox(height: 25),

                // 💾 Guardar
                SafeButton.secondary(
                  onPressed: _isSaving ? null : _saveCitizenChanges,
                  isLoading: _isSaving,
                  icon: Icons.save_rounded,
                  label: "Guardar cambios",
                  fullWidth: true,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
