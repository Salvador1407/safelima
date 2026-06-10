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

  @override
  void dispose() {
    _nameController.dispose();
    _correoController.dispose();
    super.dispose();
  }

  Future<void> _loadLocalPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

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
      if (!mounted) return;

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

      if (!mounted) return;

      setState(() => _isSaving = false);
      SafeSnackBar.showSuccess(context, "Perfil actualizado correctamente");
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSaving = false);
      SafeSnackBar.showError(context, "No se pudo actualizar el perfil");
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    if (!mounted) return;

    setState(() => notificationsEnabled = value);
  }

  void _showAvatarSelector() {
    final emojis = ["😀", "😎", "🤗", "🦊", "🐼", "🥰", "😴", "🥳"];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = _cardColor(isDark);
    final borderColor = _borderColor(isDark);
    final textColor = _textColor(isDark);
    final accentColor = _accentColor(isDark);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: borderColor.withValues(alpha: isDark ? 0.65 : 0.85),
            width: 0.9,
          ),
        ),
        title: Text(
          "Selecciona tu avatar",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: textColor,
            letterSpacing: -0.15,
          ),
        ),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: emojis.map((e) {
            final selected = e == _avatar;

            return GestureDetector(
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('selected_avatar', e);
                if (!mounted) return;
                setState(() => _avatar = e);
                Navigator.pop(context);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? accentColor.withValues(alpha: isDark ? 0.18 : 0.12)
                      : isDark
                          ? AppColors.backgroundDark
                          : AppColors.backgroundLight,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? accentColor : borderColor,
                    width: selected ? 1.4 : 0.9,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.16),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : [],
                ),
                child: Text(e, style: const TextStyle(fontSize: 28)),
              ),
            );
          }).toList(),
        ),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = _accentColor(isDark);

    return Scaffold(
      backgroundColor: _backgroundColor(isDark),
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
          "Perfil",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.white,
            letterSpacing: -0.2,
          ),
        ),
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SafeEmptyState(
                  icon: Icons.person_off_outlined,
                  title: _profileLoadMessage,
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
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              children: [
                _buildAvatarCard(citizen, isDark),
                const SizedBox(height: 18),
                _buildFormCard(isDark),
                const SizedBox(height: 18),
                _buildSettingsCard(isDark),
                const SizedBox(height: 24),
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

  Widget _buildAvatarCard(Citizen citizen, bool isDark) {
    final textColor = _textColor(isDark);
    final subtitleColor = _subtitleColor(isDark);
    final borderColor = _borderColor(isDark);
    final cardColor = _cardColor(isDark);
    final accentColor = _accentColor(isDark);

    return SafeCard(
      padding: EdgeInsets.zero,
      backgroundColor: cardColor,
      borderColor: borderColor.withValues(alpha: isDark ? 0.55 : 0.85),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              top: -54,
              right: -42,
              child: Container(
                width: 142,
                height: 142,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(alpha: isDark ? 0.10 : 0.07),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -44,
              child: Container(
                width: 118,
                height: 118,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withValues(
                    alpha: isDark ? 0.08 : 0.06,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 112,
                        height: 112,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              accentColor.withValues(
                                alpha: isDark ? 0.22 : 0.14,
                              ),
                              AppColors.accent.withValues(
                                alpha: isDark ? 0.11 : 0.08,
                              ),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: borderColor.withValues(
                              alpha: isDark ? 0.65 : 0.85,
                            ),
                            width: 1.4,
                          ),
                          boxShadow: _softShadow(isDark),
                        ),
                        child: Text(
                          _avatar,
                          style: const TextStyle(fontSize: 56),
                        ),
                      ),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: _showAvatarSelector,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: cardColor,
                                width: 2.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.black.withValues(alpha: 0.16),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
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
                  const SizedBox(height: 15),
                  Text(
                    citizen.fullName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: -0.15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _correoController.text.trim().isEmpty
                        ? "Sin correo registrado"
                        : _correoController.text.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: subtitleColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard(bool isDark) {
    final cardColor = _cardColor(isDark);
    final borderColor = _borderColor(isDark);
    final textColor = _textColor(isDark);
    final accentColor = _accentColor(isDark);

    return SafeCard(
      padding: EdgeInsets.zero,
      backgroundColor: cardColor,
      borderColor: borderColor.withValues(alpha: isDark ? 0.55 : 0.85),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                enabled: !_isSaving,
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                cursorColor: accentColor,
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
              const SizedBox(height: 18),
              TextFormField(
                controller: _correoController,
                enabled: !_isSaving,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                cursorColor: accentColor,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard(bool isDark) {
    final cardColor = _cardColor(isDark);
    final borderColor = _borderColor(isDark);

    return SafeCard(
      padding: EdgeInsets.zero,
      backgroundColor: cardColor,
      borderColor: borderColor.withValues(alpha: isDark ? 0.55 : 0.85),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            _buildSwitchTile(
              isDark: isDark,
              icon: Icons.notifications_active_outlined,
              title: "Recibir notificaciones",
              value: notificationsEnabled,
              onChanged: _toggleNotifications,
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: borderColor.withValues(alpha: isDark ? 0.40 : 0.65),
            ),
            _buildSwitchTile(
              isDark: isDark,
              icon: Icons.dark_mode_outlined,
              title: "Tema oscuro",
              value: context.watch<ThemeNotifier>().isDarkMode,
              onChanged: (val) {
                context.read<ThemeNotifier>().toggleTheme(val);
                SafeSnackBar.showInfo(
                  context,
                  val ? "Tema oscuro activado" : "Tema claro activado",
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required bool isDark,
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final textColor = _textColor(isDark);
    final subtitleColor = _subtitleColor(isDark);
    final accentColor = _accentColor(isDark);

    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: textColor,
        ),
      ),
      secondary: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: isDark ? 0.16 : 0.10),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(
          icon,
          color: value ? accentColor : subtitleColor,
          size: 22,
        ),
      ),
      value: value,
      activeThumbColor: accentColor,
      activeTrackColor: accentColor.withValues(alpha: 0.3),
      onChanged: onChanged,
    );
  }
}