import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safelima/core/app_colors.dart';
import 'package:safelima/core/app_data.dart';
import 'package:safelima/models/user_alert.dart';
import 'package:safelima/screens/edit_report_screen.dart';
import 'package:safelima/services/user_alert_service.dart';
import 'package:safelima/widgets/safe_buttons.dart';
import 'package:safelima/widgets/safe_card.dart';
import 'package:safelima/widgets/safe_dialog.dart';
import 'package:safelima/widgets/safe_empty_state.dart';
import 'package:safelima/widgets/safe_snack_bar.dart';
import 'package:safelima/widgets/safe_shimmer.dart';
import 'package:safelima/widgets/safe_status_chip.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  final UserAlertService _alertService = UserAlertService();

  List<UserAlert> _myReports = [];
  bool _loading = true;
  static const String _deleteReportErrorMessage = "Error al eliminar reporte";

  @override
  void initState() {
    super.initState();
    _loadMyReports();
  }

  Future<void> _loadMyReports() async {
    try {
      final reports = await _alertService.getAlertsByCitizen(
        AppData.citizen_id,
      );

      if (!mounted) return;

      setState(() {
        _myReports = reports;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);

      SafeSnackBar.showError(context, "Error al cargar mis reportes: $e");
    }
  }

  Future<void> _refreshMyReports() async {
    await _loadMyReports();
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
    } catch (_) {
      return false;
    }
  }

  void _showDeleteReportError() {
    if (!mounted) return;
    SafeSnackBar.showError(context, _deleteReportErrorMessage);
  }

  Future<void> _deleteReport(int id) async {
    final connected = await _hasInternet();
    if (!mounted) return;

    if (!connected) {
      _showDeleteReportError();
      return;
    }

    try {
      await _alertService.deleteAlert(id);

      if (!mounted) return;

      SafeSnackBar.showSuccess(context, "Reporte eliminado correctamente");

      await _loadMyReports();
    } catch (_) {
      if (!mounted) return;

      _showDeleteReportError();
    }
  }

  Future<void> _confirmDelete(UserAlert alert) async {
    final connected = await _hasInternet();
    if (!mounted) return;

    if (!connected) {
      _showDeleteReportError();
      return;
    }

    final confirm = await SafeDialog.showConfirmation(
      context,
      title: "Eliminar reporte",
      content: "¿Deseas eliminar el reporte \"${alert.titulo}\"?",
      confirmLabel: "Eliminar",
      cancelLabel: "Cancelar",
      icon: Icons.delete_forever_rounded,
      iconColor: AppColors.danger,
    );

    if (confirm == true) {
      await _deleteReport(alert.id!);
    }
  }

  String _formatFecha(DateTime? fecha) {
    if (fecha == null) return "Sin fecha";

    final day = fecha.day.toString().padLeft(2, '0');
    final month = fecha.month.toString().padLeft(2, '0');
    final year = fecha.year.toString();
    final hour = fecha.hour.toString().padLeft(2, '0');
    final minute = fecha.minute.toString().padLeft(2, '0');

    return "$day/$month/$year - $hour:$minute";
  }

  SafeStatusChip _buildStatusChip(String? estado) {
    switch ((estado ?? "").toLowerCase()) {
      case "recibido":
        return const SafeStatusChip.info(
          label: "RECIBIDO",
          icon: Icons.assignment_turned_in_outlined,
        );
      case "en proceso":
        return const SafeStatusChip.warning(
          label: "EN PROCESO",
          icon: Icons.run_circle_outlined,
        );
      case "cerrado":
        return const SafeStatusChip.success(
          label: "CERRADO",
          icon: Icons.check_circle_outline_rounded,
        );
      default:
        return const SafeStatusChip.neutral(
          label: "PENDIENTE",
          icon: Icons.hourglass_empty_rounded,
        );
    }
  }

  String _getSafeText(String? value, {String fallback = "Sin información"}) {
    if (value == null || value.trim().isEmpty) return fallback;
    return value;
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

  // ignore: unused_element
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
    final backgroundColor = _backgroundColor(isDark);
    final textColor = _textColor(isDark);
    final subtitleColor = _subtitleColor(isDark);
    final borderColor = _borderColor(isDark);

    return Scaffold(
      backgroundColor: backgroundColor,
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
          "Mis reportes",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.white,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: _loading
          ? _buildLoadingList()
          : RefreshIndicator(
              color: isDark ? AppColors.secondaryDark : AppColors.primary,
              backgroundColor: _cardColor(isDark),
              onRefresh: _refreshMyReports,
              child: _myReports.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                      itemCount: _myReports.length,
                      itemBuilder: (context, index) {
                        final alert = _myReports[index];
                        return _buildReportCard(
                          alert: alert,
                          isDark: isDark,
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                          borderColor: borderColor,
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      itemCount: 4,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: SafeShimmer(
          width: double.infinity,
          height: 190,
          borderRadius: 24,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.all(24),
      children: const [
        SizedBox(height: 80),
        SafeEmptyState(
          icon: Icons.assignment_late_outlined,
          title: "No tienes reportes registrados",
          message: "Cuando envíes reportes, aparecerán aquí.",
        ),
      ],
    );
  }

  Widget _buildReportCard({
    required UserAlert alert,
    required bool isDark,
    required Color textColor,
    required Color subtitleColor,
    required Color borderColor,
  }) {
    final statusChip = _buildStatusChip(alert.estado);
    final cardColor = _cardColor(isDark);
    final accentColor = isDark ? AppColors.secondaryDark : AppColors.primary;

    return SafeCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.zero,
      backgroundColor: cardColor,
      borderColor: borderColor.withValues(alpha: isDark ? 0.55 : 0.85),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              top: -44,
              right: -40,
              child: Container(
                width: 126,
                height: 126,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(alpha: isDark ? 0.10 : 0.07),
                ),
              ),
            ),
            Positioned(
              bottom: -48,
              left: -42,
              child: Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withValues(
                    alpha: isDark ? 0.07 : 0.06,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReportHeader(
                    alert: alert,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    borderColor: borderColor,
                    isDark: isDark,
                    accentColor: accentColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getSafeText(alert.descripcion),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: subtitleColor,
                      height: 1.42,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (alert.rutaFoto != null &&
                      alert.rutaFoto!.isNotEmpty &&
                      alert.rutaFoto!.startsWith('http'))
                    _buildReportImage(alert.rutaFoto!, isDark, subtitleColor),
                  const SizedBox(height: 13),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SafeStatusChip.neutral(
                        label: _getSafeText(
                          alert.tipoIncidente,
                          fallback: "Sin tipo",
                        ).toUpperCase(),
                        icon: Icons.label_outline_rounded,
                      ),
                      statusChip,
                    ],
                  ),
                  const SizedBox(height: 13),
                  _buildMetaBox(
                    alert: alert,
                    isDark: isDark,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    borderColor: borderColor,
                  ),
                  const SizedBox(height: 14),
                  _buildActions(alert),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportHeader({
    required UserAlert alert,
    required Color textColor,
    required Color subtitleColor,
    required Color borderColor,
    required bool isDark,
    required Color accentColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accentColor.withValues(alpha: isDark ? 0.24 : 0.16),
                accentColor.withValues(alpha: isDark ? 0.12 : 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.22),
            ),
          ),
          child: Icon(
            Icons.assignment_outlined,
            color: accentColor,
            size: 23,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            _getSafeText(alert.titulo),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 15.8,
              fontWeight: FontWeight.w800,
              color: textColor,
              height: 1.22,
              letterSpacing: -0.15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportImage(
    String imageUrl,
    bool isDark,
    Color subtitleColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Image.network(
              imageUrl,
              width: double.infinity,
              height: 156,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: double.infinity,
                height: 148,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.broken_image_outlined,
                  color: subtitleColor,
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.black.withValues(alpha: 0.00),
                      AppColors.black.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaBox({
    required UserAlert alert,
    required bool isDark,
    required Color textColor,
    required Color subtitleColor,
    required Color borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.backgroundDark.withValues(alpha: 0.40)
            : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor.withValues(alpha: isDark ? 0.46 : 0.78),
        ),
      ),
      child: Column(
        children: [
          _buildMetaRow(
            icon: Icons.calendar_month_outlined,
            label: "Fecha",
            value: _formatFecha(alert.fecha),
            textColor: textColor,
            subtitleColor: subtitleColor,
          ),
          if (alert.grid != null && alert.grid!.nombre.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildMetaRow(
              icon: Icons.location_on_outlined,
              label: "Zona",
              value: alert.grid!.nombre,
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaRow({
    required IconData icon,
    required String label,
    required String value,
    required Color textColor,
    required Color subtitleColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: subtitleColor),
        const SizedBox(width: 7),
        Text(
          "$label: ",
          style: GoogleFonts.poppins(
            fontSize: 12.4,
            color: subtitleColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 12.4,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(UserAlert alert) {
    return Row(
      children: [
        Expanded(
          child: SafeButton.secondary(
            onPressed: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditReportScreen(alert: alert),
                ),
              );

              if (updated == true) {
                await _loadMyReports();
              }
            },
            icon: Icons.edit_outlined,
            label: "Editar",
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SafeButton.danger(
            onPressed: () => _confirmDelete(alert),
            icon: Icons.delete_outline,
            label: "Eliminar",
          ),
        ),
      ],
    );
  }
}