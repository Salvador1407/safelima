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

      final connected = await _hasInternet();
      if (!mounted) return;

      if (!connected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(_noInternetMessage),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final id = AppData.citizen_id;
      final updatedData = {
        "full_name": _nameController.text.trim(),
        "correo": _correoController.text.trim(),
      };

      await _citizenService.updateCitizen(id, updatedData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Perfil actualizado correctamente"),
          backgroundColor: AppColors.secundary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se pudo actualizar el perfil"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() => notificationsEnabled = value);
  }

  void _showAvatarSelector() {
    final emojis = ["😀", "😎", "🤗", "🦊", "🐼", "🥰", "😴", "🥳"];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Selecciona tu avatar"),
        content: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: emojis.map((e) {
            return GestureDetector(
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('selected_avatar', e);
                setState(() => _avatar = e);
                Navigator.pop(context);
              },
              child: CircleAvatar(
                radius: 25,
                child: Text(e, style: const TextStyle(fontSize: 26)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = GoogleFonts.poppinsTextTheme(theme.textTheme);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Perfil"),
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
      body: FutureBuilder<Citizen?>(
        future: _futureCitizen,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person_off_outlined,
                      size: 64,
                      color: AppColors.primaryDark,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _profileLoadMessage,
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final citizen = snapshot.data!;
          _nameController.text = citizen.fullName ?? "";
          _correoController.text = citizen.correo ?? "";

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 🧍 Avatar
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _showAvatarSelector,
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: AppColors.secundary.withOpacity(0.2),
                          child: Text(
                            _avatar,
                            style: const TextStyle(fontSize: 40),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        citizen.fullName ?? "Usuario SafeLima",
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // 👤 Nombre completo
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: "Nombre completo",
                    prefixIcon: const Icon(Icons.person_outline),
                    filled: true,
                    fillColor: theme.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                  validator: (value) {
                    final name = value?.trim() ?? "";
                    if (name.length < 2 || name.length > 50) {
                      return "El nombre debe tener entre 2 y 50 caracteres";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // ✉️ Correo
                TextFormField(
                  controller: _correoController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Correo electrónico",
                    prefixIcon: const Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: theme.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
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
                SwitchListTile(
                  title: const Text("Recibir notificaciones"),
                  secondary: const Icon(Icons.notifications_active_outlined),
                  value: notificationsEnabled,
                  activeThumbColor: AppColors.secundary,
                  onChanged: _toggleNotifications,
                ),

                // 🌙 Tema oscuro
                SwitchListTile(
                  title: const Text("Tema oscuro"),
                  secondary: const Icon(Icons.dark_mode_outlined),
                  value: context.watch<ThemeNotifier>().isDarkMode,
                  activeThumbColor: AppColors.secundary,
                  onChanged: (val) {
                    context.read<ThemeNotifier>().toggleTheme(val);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          val
                              ? "🌙 Tema oscuro activado"
                              : "☀️ Tema claro activado",
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: val
                            ? Colors.blueGrey
                            : AppColors.primary,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 25),

                // 💾 Guardar
                ElevatedButton.icon(
                  onPressed: _saveCitizenChanges,
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    "Guardar cambios",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secundary,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
