import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:safelima/core/app_colors.dart';
import 'package:safelima/models/ml_batch_run_result.dart';
import 'package:safelima/models/ml_model_status.dart';
import 'package:safelima/models/prediction_grid.dart';
import 'package:safelima/models/user_alert.dart';
import 'package:safelima/services/ml_admin_service.dart';
import 'package:safelima/services/prediction_grid_service.dart';
import 'package:safelima/services/user_alert_service.dart';
import 'package:safelima/widgets/safe_buttons.dart';
import 'package:safelima/widgets/safe_card.dart';
import 'package:safelima/widgets/safe_empty_state.dart';
import 'package:safelima/widgets/safe_snack_bar.dart';
import 'package:safelima/widgets/safe_status_chip.dart';

class AdminMlScreen extends StatefulWidget {
  const AdminMlScreen({super.key});

  @override
  State<AdminMlScreen> createState() => _AdminMlScreenState();
}

class _AdminMlScreenState extends State<AdminMlScreen> {
  final MlAdminService _mlAdminService = MlAdminService();
  final UserAlertService _alertService = UserAlertService();
  final PredictionGridService _predictionService = PredictionGridService();

  MlModelStatus? _modelStatus;
  MlBatchRunResult? _lastBatchResult;
  List<UserAlert> _recentAlerts = [];
  List<PredictionGrid> _recentPredictions = [];

  bool _loadingStatus = true;
  bool _loadingRecent = true;
  bool _runningBatch = false;
  String? _statusError;
  String? _recentError;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
    _loadRecentData();
  }

  Future<void> _refreshStatus({bool showSuccess = false}) async {
    if (!mounted) return;
    setState(() {
      _loadingStatus = true;
      _statusError = null;
    });

    try {
      final status = await _mlAdminService.getModelStatus();
      if (!mounted) return;

      setState(() => _modelStatus = status);
      if (showSuccess) {
        SafeSnackBar.showSuccess(context, "Estado ML actualizado");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusError = _messageFromError(e));
      if (showSuccess) {
        SafeSnackBar.showError(context, _messageFromError(e));
      }
    } finally {
      if (mounted) {
        setState(() => _loadingStatus = false);
      }
    }
  }

  Future<void> _loadRecentData() async {
    if (!mounted) return;
    setState(() {
      _loadingRecent = true;
      _recentError = null;
    });

    try {
      final alerts = await _alertService.getAllAlerts();
      final predictions = await _predictionService.getAllPredictions();

      alerts.sort((a, b) => _compareDateDesc(a.fecha, b.fecha));
      predictions.sort(
        (a, b) => _compareDateDesc(a.fechaPrediccion, b.fechaPrediccion),
      );

      if (!mounted) return;
      setState(() {
        _recentAlerts = alerts.take(5).toList();
        _recentPredictions = predictions.take(10).toList();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _recentError = _messageFromError(e));
    } finally {
      if (mounted) {
        setState(() => _loadingRecent = false);
      }
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([_refreshStatus(), _loadRecentData()]);
  }

  Future<void> _runBatch() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Ejecutar batch ML"),
        content: const Text(
          "Se recalcularán las predicciones batch para todos los grids y tramos horarios.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Ejecutar"),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _runningBatch = true);
    try {
      final result = await _mlAdminService.runBatchPredictions();
      if (!mounted) return;

      setState(() => _lastBatchResult = result);
      SafeSnackBar.showSuccess(context, "Batch ML ejecutado correctamente");
      await _refreshStatus();
      await _loadRecentData();
    } catch (e) {
      if (!mounted) return;
      SafeSnackBar.showError(context, _messageFromError(e));
    } finally {
      if (mounted) {
        setState(() => _runningBatch = false);
      }
    }
  }

  int _compareDateDesc(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return b.compareTo(a);
  }

  String _messageFromError(Object error) {
    if (error is MlAdminException) return error.message;
    return error.toString().replaceFirst('Exception: ', '');
  }

  String _formatDate(DateTime? value) {
    if (value == null) return "Sin fecha";
    return DateFormat('dd/MM/yyyy HH:mm').format(value.toLocal());
  }

  Color _backgroundColor(bool isDark) {
    return isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
  }

  Color _textColor(bool isDark) {
    return isDark ? AppColors.textDark : AppColors.textLight;
  }

  Color _subtitleColor(bool isDark) {
    return isDark ? AppColors.subtitleDark : AppColors.subtitleLight;
  }

  Widget _sectionTitle(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: isDark ? AppColors.secondaryDark : AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: _textColor(isDark),
          ),
        ),
      ],
    );
  }

  SafeStatusChip _boolChip(String label, bool value) {
    return value
        ? SafeStatusChip.success(
            label: "$label OK",
            icon: Icons.check_circle_outline_rounded,
          )
        : SafeStatusChip.danger(
            label: "$label error",
            icon: Icons.error_outline_rounded,
          );
  }

  SafeStatusChip _riskChip(String risk) {
    switch (risk.toLowerCase()) {
      case 'alto':
        return const SafeStatusChip.danger(
          label: "Alto",
          icon: Icons.priority_high_rounded,
        );
      case 'medio':
        return const SafeStatusChip.warning(
          label: "Medio",
          icon: Icons.warning_amber_rounded,
        );
      case 'bajo':
        return const SafeStatusChip.success(
          label: "Bajo",
          icon: Icons.check_circle_outline_rounded,
        );
      default:
        return SafeStatusChip.neutral(
          label: risk.isEmpty ? "Sin riesgo" : risk,
          icon: Icons.help_outline_rounded,
        );
    }
  }

  Widget _buildStatusCard(bool isDark) {
    final status = _modelStatus;

    return SafeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _sectionTitle(
                  "Estado de modelos",
                  Icons.psychology_alt_rounded,
                  isDark,
                ),
              ),
              IconButton(
                tooltip: "Actualizar estado",
                onPressed: _loadingStatus
                    ? null
                    : () => _refreshStatus(showSuccess: true),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_loadingStatus)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_statusError != null)
            _InlineError(message: _statusError!)
          else if (status != null) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SafeStatusChip.info(
                  label: "Fuente: ${status.source}",
                  icon: Icons.cloud_queue_rounded,
                ),
                _boolChip("General", status.loaded),
                _boolChip("Batch", status.batchLoaded),
                _boolChip("Online", status.onlineLoaded),
              ],
            ),
            const SizedBox(height: 14),
            _InfoRow(label: "Bucket", value: status.gcsBucket),
            _InfoRow(label: "Batch", value: status.batchModelBlob),
            _InfoRow(label: "Online", value: status.onlineModelBlob),
            if (status.errors.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                "Errores",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: _textColor(isDark),
                ),
              ),
              const SizedBox(height: 6),
              ...status.errors.entries.map(
                (entry) => _InfoRow(label: entry.key, value: entry.value),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildBatchCard(bool isDark) {
    final result = _lastBatchResult;

    return SafeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Batch manual", Icons.play_circle_outline, isDark),
          const SizedBox(height: 10),
          Text(
            "Ejecuta el recálculo batch de predicciones por grid y tramo horario.",
            style: GoogleFonts.poppins(
              color: _subtitleColor(isDark),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          SafeButton.primary(
            onPressed: _runningBatch ? null : _runBatch,
            icon: Icons.play_arrow_rounded,
            label: _runningBatch ? "Ejecutando batch..." : "Ejecutar batch",
            isLoading: _runningBatch,
            fullWidth: true,
          ),
          if (result != null) ...[
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SafeStatusChip.info(
                  label: "${result.gridsProcessed} grids",
                  icon: Icons.grid_view_rounded,
                ),
                SafeStatusChip.success(
                  label: "${result.predictionsUpdated} predicciones",
                  icon: Icons.check_circle_outline_rounded,
                ),
                SafeStatusChip.info(
                  label: _formatDate(result.ranAt),
                  icon: Icons.schedule_rounded,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(label: "Tramos", value: result.tramoHorarios.join(", ")),
            if (result.errors.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...result.errors.map(
                (error) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _InlineError(message: error),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildRecentAlerts(bool isDark) {
    if (_loadingRecent) return _buildLoadingCard("Cargando datos recientes...");
    if (_recentError != null) return _InlineError(message: _recentError!);
    if (_recentAlerts.isEmpty) {
      return const SafeEmptyState(
        icon: Icons.notifications_none_rounded,
        title: "No hay alertas recientes",
      );
    }

    return Column(
      children: _recentAlerts.map((alert) {
        return SafeCard(
          margin: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                alert.titulo.isEmpty ? "Reporte ciudadano" : alert.titulo,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: _textColor(isDark),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                alert.grid?.nombre ?? "Zona sin datos",
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: _subtitleColor(isDark),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _riskChip(alert.nivelRiesgo),
                  SafeStatusChip.info(
                    label: alert.estado ?? "Sin estado",
                    icon: Icons.assignment_turned_in_outlined,
                  ),
                  SafeStatusChip.neutral(
                    label: _formatDate(alert.fecha),
                    icon: Icons.calendar_today_outlined,
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentPredictions(bool isDark) {
    if (_loadingRecent) return _buildLoadingCard("Cargando predicciones...");
    if (_recentError != null) return _InlineError(message: _recentError!);
    if (_recentPredictions.isEmpty) {
      return const SafeEmptyState(
        icon: Icons.analytics_outlined,
        title: "No hay predicciones recientes",
      );
    }

    return Column(
      children: _recentPredictions.map((prediction) {
        final zoneName = prediction.grid?.nombre ?? "Grid ${prediction.gridId}";
        return SafeCard(
          margin: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                zoneName,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: _textColor(isDark),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _riskChip(prediction.nivelRiesgo),
                  SafeStatusChip.info(
                    label: "Score ${prediction.scoreRiesgo}",
                    icon: Icons.speed_rounded,
                  ),
                  SafeStatusChip.neutral(
                    label: prediction.tramoHorario ?? "Sin tramo",
                    icon: Icons.access_time_rounded,
                  ),
                  SafeStatusChip.neutral(
                    label: _formatDate(prediction.fechaPrediccion),
                    icon: Icons.calendar_today_outlined,
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLoadingCard(String message) {
    return SafeCard(
      child: Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: _backgroundColor(isDark),
      appBar: AppBar(
        title: Text(
          "ML Predictivo",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatusCard(isDark),
            const SizedBox(height: 14),
            _buildBatchCard(isDark),
            const SizedBox(height: 24),
            _sectionTitle(
              "Últimas alertas",
              Icons.notifications_active_outlined,
              isDark,
            ),
            const SizedBox(height: 12),
            _buildRecentAlerts(isDark),
            const SizedBox(height: 18),
            _sectionTitle(
              "Últimas predicciones",
              Icons.analytics_outlined,
              isDark,
            ),
            const SizedBox(height: 12),
            _buildRecentPredictions(isDark),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final subtitleColor = isDark
        ? AppColors.subtitleDark
        : AppColors.subtitleLight;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: subtitleColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? "N/A" : value,
              style: GoogleFonts.poppins(fontSize: 12.5, color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;

  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
