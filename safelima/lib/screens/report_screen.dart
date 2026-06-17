import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:safelima/core/app_colors.dart';
import 'package:safelima/core/app_data.dart';
import 'package:safelima/models/grid.dart';
import 'package:safelima/services/grid_service.dart';
import 'package:safelima/services/user_alert_service.dart';
import 'package:safelima/widgets/safe_buttons.dart';
import 'package:safelima/widgets/safe_card.dart';
import 'package:safelima/widgets/safe_input_decoration.dart';
import 'package:safelima/widgets/safe_snack_bar.dart';
import 'package:safelima/widgets/safe_shimmer.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descController = TextEditingController();
  final UserAlertService _alertService = UserAlertService();
  final GridService _gridService = GridService();

  String? _selectedIncident;
  int? _selectedGridId;
  bool _isAnonymous = false;
  File? _selectedImage;

  List<Grid> _grids = [];
  bool _isLoadingGrids = true;
  bool _zonesUnavailable = false;
  static const String _loadZonesErrorMessage = "Error al cargar zonas";

  final List<String> _incidentTypes = [
    "Acoso callejero",
    "Vandalismo",
    "Hurto de celular",
    "Robo al paso",
    "Asalto con arma blanca",
    "Asalto con arma de fuego",
    "Robo de vehículo",
    "Pelea en la vía pública",
    "Microcomercialización de droga",
    "Riña entre grupos",
  ];

  final Map<String, String> incidentMap = {
    "Acoso callejero": "acoso",
    "Vandalismo": "vandalismo",
    "Hurto de celular": "hurto",
    "Robo al paso": "robo",
    "Asalto con arma blanca": "asalto",
    "Asalto con arma de fuego": "asalto",
    "Robo de vehículo": "robo_vehiculo",
    "Pelea en la vía pública": "pelea",
    "Microcomercialización de droga": "droga",
    "Riña entre grupos": "rina",
  };

  @override
  void initState() {
    super.initState();
    _loadGrids();
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadGrids() async {
    final connected = await _hasInternet();
    if (!mounted) return;

    if (!connected) {
      setState(() {
        _grids = [];
        _selectedGridId = null;
        _zonesUnavailable = true;
        _isLoadingGrids = false;
      });
      _showLoadZonesError();
      return;
    }

    try {
      final grids = await _gridService.getAllGrids();
      if (!mounted) return;
      setState(() {
        _grids = grids;
        _zonesUnavailable = false;
        _isLoadingGrids = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _grids = [];
        _selectedGridId = null;
        _zonesUnavailable = true;
        _isLoadingGrids = false;
      });
      _showLoadZonesError();
    }
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

  Widget _zonesErrorBox({
    required bool isDark,
    required Color textColor,
    required Color subtitleColor,
    required Color borderColor,
  }) {
    return SafeCard(
      borderColor: AppColors.danger.withValues(alpha: 0.45),
      backgroundColor: isDark
          ? AppColors.cardDark
          : AppColors.danger.withValues(alpha: 0.08),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.wifi_off, color: AppColors.danger, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _loadZonesErrorMessage,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "No se pudieron cargar las zonas. El reporte no podrá enviarse hasta restablecer la conexión y actualizar la pestaña.",
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: subtitleColor,
                  ),
                ),
                const SizedBox(height: 12),
                SafeButton.danger(
                  onPressed: _reloadGrids,
                  icon: Icons.refresh,
                  label: "Actualizar zonas",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _reloadGrids() async {
    setState(() {
      _isLoadingGrids = true;
      _zonesUnavailable = false;
      _selectedGridId = null;
      _grids = [];
    });

    await _loadGrids();
  }

  void _showLoadZonesError() {
    if (!mounted) return;
    SafeSnackBar.showError(context, _loadZonesErrorMessage);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (!mounted) return;

    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<void> _sendReport() async {
    final connected = await _hasInternet();
    if (!mounted) return;

    if (!connected) {
      setState(() {
        _zonesUnavailable = true;
        _selectedGridId = null;
        _grids = [];
      });

      _showLoadZonesError();
      return;
    }

    if (_zonesUnavailable) {
      _showLoadZonesError();
      return;
    }

    if (_selectedIncident == null || _selectedGridId == null) {
      SafeSnackBar.showError(
        context,
        "Selecciona un tipo de incidente y una zona",
      );
      return;
    }

    try {
      final Map<String, String> fields = {
        "titulo": incidentMap[_selectedIncident!]!,
        "tipo_incidente": _selectedIncident!,
        "descripcion": _descController.text.isNotEmpty
            ? _descController.text
            : "Sin descripción",
        "citizen_id": AppData.citizen_id.toString(),
        "grid_id": _selectedGridId.toString(),
      };

      await _alertService.createAlertMultipart(
        fields: fields,
        imageFile: _selectedImage,
      );

      if (!mounted) return;

      SafeSnackBar.showSuccess(context, "✅ Reporte enviado correctamente");

      setState(() {
        _selectedIncident = null;
        _descController.clear();
        _selectedImage = null;
        _isAnonymous = false;
        _selectedGridId = null;
      });
    } catch (e) {
      if (!mounted) return;

      debugPrint("Error técnico al enviar reporte: $e");

      SafeSnackBar.showError(context, "No tienes conexión a Internet");
    }
  }

  Color _bgColor(bool isDark) {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = _bgColor(isDark);
    final cardColor = _cardColor(isDark);
    final textColor = _textColor(isDark);
    final subtitleColor = _subtitleColor(isDark);
    final borderColor = _borderColor(isDark);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "Reportar Incidente",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Tipo de Incidente",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedIncident,
                  dropdownColor: cardColor,
                  iconEnabledColor: textColor,
                  style: GoogleFonts.poppins(color: textColor, fontSize: 14),
                  decoration: safeInputDecoration(
                    context,
                    labelText: "Tipo de Incidente",
                    hintText: "Seleccionar...",
                    prefixIcon: Icons.warning_amber_rounded,
                  ),
                  hint: Text(
                    "Seleccionar...",
                    style: GoogleFonts.poppins(color: subtitleColor),
                  ),
                  items: _incidentTypes
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(
                            type,
                            style: GoogleFonts.poppins(
                              color: textColor,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedIncident = value);
                  },
                ),
                const SizedBox(height: 20),

                Text(
                  "Zona o Ubicación",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                _isLoadingGrids
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: SafeShimmer(
                          width: double.infinity,
                          height: 58,
                          borderRadius: 16,
                        ),
                      )
                    : _zonesUnavailable
                    ? _zonesErrorBox(
                        isDark: isDark,
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                        borderColor: borderColor,
                      )
                    : DropdownButtonFormField<int>(
                        value: _selectedGridId,
                        dropdownColor: cardColor,
                        iconEnabledColor: textColor,
                        style: GoogleFonts.poppins(
                          color: textColor,
                          fontSize: 14,
                        ),
                        decoration: safeInputDecoration(
                          context,
                          labelText: "Zona o Ubicación",
                          hintText: "Seleccionar zona...",
                          prefixIcon: Icons.location_on_outlined,
                        ),
                        hint: Text(
                          "Seleccionar zona...",
                          style: GoogleFonts.poppins(color: subtitleColor),
                        ),
                        items: _grids
                            .map(
                              (grid) => DropdownMenuItem<int>(
                                value: grid.id,
                                child: Text(
                                  grid.nombre,
                                  style: GoogleFonts.poppins(
                                    color: textColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedGridId = value);
                        },
                      ),
                const SizedBox(height: 20),

                Text(
                  "Descripción (Opcional)",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  style: GoogleFonts.poppins(color: textColor, fontSize: 14),
                  decoration: safeInputDecoration(
                    context,
                    labelText: "Descripción",
                    hintText: "Describe brevemente lo que ocurrió...",
                    prefixIcon: Icons.description_outlined,
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  "Adjuntar Foto (opcional)",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SafeButton.secondary(
                      onPressed: _pickImage,
                      icon: Icons.camera_alt,
                      label: "Seleccionar imagen",
                    ),
                    const SizedBox(width: 15),
                    if (_selectedImage != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _selectedImage!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                SafeCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _isAnonymous,
                        activeColor: AppColors.primary,
                        checkColor: AppColors.white,
                        side: BorderSide(color: borderColor),
                        onChanged: (value) {
                          setState(() => _isAnonymous = value ?? false);
                        },
                      ),
                      Expanded(
                        child: Text(
                          "Reporte Anónimo\nTu identidad permanecerá privada.",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  child: SafeButton.primary(
                    onPressed: _isLoadingGrids ? null : _sendReport,
                    label: "Enviar Reporte",
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
