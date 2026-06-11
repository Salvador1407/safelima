import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safelima/core/app_colors.dart';
import 'package:safelima/models/citizen.dart';
import 'package:safelima/models/user.dart';
import 'package:safelima/services/user_service.dart';
import 'package:safelima/widgets/safe_card.dart';
import 'package:safelima/widgets/safe_snack_bar.dart';
import 'package:safelima/widgets/safe_shimmer.dart';
import 'package:safelima/widgets/safe_dialog.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final UserService serviceController = UserService();
  late Future<List<User>> resultados;
  static const String _updateUserStatusErrorMessage =
      "No se pudo actualizar el estado del usuario";
  static const String _loadUsersErrorMessage =
      "No se pudieron cargar los usuarios";

  @override
  void initState() {
    super.initState();
    resultados = _loadUsers();
  }

  Future<List<User>> _loadUsers() async {
    final connected = await _hasInternet();

    if (!connected) {
      _showLoadUsersError();
      throw Exception(_loadUsersErrorMessage);
    }

    try {
      return await serviceController.getUsersCitizen();
    } catch (e) {
      debugPrint("Error técnico al cargar usuarios: $e");
      _showLoadUsersError();
      throw Exception(_loadUsersErrorMessage);
    }
  }

  // 🔹 Ver detalles del usuario
  Future<void> _verUsuario(User usuario) async {
    Citizen ciudadano = await serviceController.usersDetail(usuario.id);
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final Color textColor = isDark
            ? AppColors.textDark
            : AppColors.textLight;
        final Color subtitleColor = isDark
            ? AppColors.subtitleDark
            : AppColors.subtitleLight;
        final Color cardColor = isDark
            ? AppColors.cardDark
            : AppColors.cardLight;
        final Color borderColor = isDark
            ? AppColors.borderDark
            : AppColors.borderLight;

        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: borderColor, width: 0.9),
          ),
          title: Row(
            children: [
              const Icon(Icons.person, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  usuario.nameuser,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    (usuario.enable ?? false)
                        ? Icons.check_circle
                        : Icons.block,
                    color: (usuario.enable ?? false)
                        ? Colors.green
                        : Colors.redAccent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    (usuario.enable ?? false) ? "Activo" : "Bloqueado",
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      color: (usuario.enable ?? false)
                          ? Colors.green
                          : Colors.redAccent,
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              _buildInfoTile(
                "Nombre",
                ciudadano.fullName ?? "-",
                textColor,
                subtitleColor,
              ),
              _buildInfoTile(
                "Correo",
                ciudadano.correo ?? "-",
                textColor,
                subtitleColor,
              ),
              _buildInfoTile(
                "Rol",
                ciudadano.user?.role ?? "Sin rol",
                textColor,
                subtitleColor,
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.grey),
              label: Text(
                "Cerrar",
                style: GoogleFonts.manrope(color: textColor),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _hasInternet() async {
    final connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult.contains(ConnectivityResult.none)) {
      return false;
    }

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

  void _showUpdateUserStatusError() {
    if (!mounted) return;
    SafeSnackBar.showError(context, _updateUserStatusErrorMessage);
  }

  void _showLoadUsersError() {
    if (!mounted) return;
    SafeSnackBar.showError(context, _loadUsersErrorMessage);
  }

  Widget _buildInfoTile(
    String title,
    String value,
    Color textColor,
    Color subtitleColor,
  ) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.arrow_right, color: Colors.grey),
      title: Text(
        title,
        style: GoogleFonts.manrope(
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
      subtitle: Text(value, style: GoogleFonts.manrope(color: subtitleColor)),
    );
  }

  // 🔹 Bloquear o desbloquear usuario
  Future<void> _bloquearUsuario(User usuario) async {
    final yaBloqueado = (usuario.enable ?? false);

    final confirm = await SafeDialog.showConfirmation(
      context,
      title: yaBloqueado ? "Bloquear usuario" : "Desbloquear usuario",
      content: yaBloqueado
          ? "¿Estás seguro de bloquear a ${usuario.nameuser}?"
          : "¿Deseas desbloquear a ${usuario.nameuser}?",
      confirmLabel: yaBloqueado ? "Bloquear" : "Desbloquear",
      cancelLabel: "Cancelar",
      icon: Icons.block,
      iconColor: yaBloqueado ? Colors.redAccent : AppColors.primary,
    );

    if (confirm != true) return;

    final connected = await _hasInternet();
    if (!mounted) return;

    if (!connected) {
      _showUpdateUserStatusError();
      return;
    }

    try {
      final Map<String, dynamic> resultResponse = {"enable": !yaBloqueado};

      await serviceController.updateUser(usuario.id, resultResponse);

      if (!mounted) return;

      SafeSnackBar.showSuccess(
        context,
        !yaBloqueado
            ? "${usuario.nameuser} fue desbloqueado ✅"
            : "${usuario.nameuser} fue bloqueado ❌",
      );

      setState(() {
        resultados = _loadUsers();
      });
    } catch (e) {
      debugPrint("Error técnico al actualizar estado de usuario: $e");
      _showUpdateUserStatusError();
    }
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 5,
      itemBuilder: (context, index) {
        return SafeCard(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              const SafeShimmer.circular(size: 40),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SafeShimmer(width: 120, height: 16),
                    SizedBox(height: 6),
                    SafeShimmer(width: 80, height: 12),
                  ],
                ),
              ),
              const Icon(Icons.more_vert, color: Colors.grey),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final Color textColor = isDark ? AppColors.textDark : AppColors.textLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Gestión de Usuarios"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? AppColors.cardDark : AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<User>>(
        future: resultados,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingShimmer();
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                _loadUsersErrorMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  color: Colors.redAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                "No hay datos disponibles.",
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  color: Colors.redAccent,
                ),
              ),
            );
          }

          final resultadosData = snapshot.data!;

          return ListView.builder(
            itemCount: resultadosData.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final usuario = resultadosData[index];
              final activo = usuario.enable ?? false;

              return SafeCard(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: activo
                        ? AppColors.secundary.withOpacity(0.12)
                        : Colors.redAccent.withOpacity(0.12),
                    child: Icon(
                      activo ? Icons.person : Icons.block,
                      color: activo ? AppColors.secundary : Colors.redAccent,
                    ),
                  ),
                  title: Text(
                    usuario.nameuser,
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    icon: Icon(Icons.more_vert, color: textColor),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: "ver",
                        child: Text(
                          "Visualizar",
                          style: GoogleFonts.manrope(color: textColor),
                        ),
                      ),
                      PopupMenuItem(
                        value: "bloquear",
                        child: Text(
                          activo ? "Bloquear" : "Desbloquear",
                          style: GoogleFonts.manrope(color: textColor),
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == "ver") {
                        _verUsuario(usuario);
                      } else if (value == "bloquear") {
                        _bloquearUsuario(usuario);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
