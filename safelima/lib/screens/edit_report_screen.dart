import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:safelima/core/app_colors.dart';
import 'package:safelima/models/user_alert.dart';
import 'package:safelima/services/user_alert_service.dart';

class EditReportScreen extends StatefulWidget {
  final UserAlert alert;

  const EditReportScreen({super.key, required this.alert});

  @override
  State<EditReportScreen> createState() => _EditReportScreenState();
}

class _EditReportScreenState extends State<EditReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserAlertService _alertService = UserAlertService();

  late TextEditingController _tituloController;
  late TextEditingController _descripcionController;

  String? _selectedIncidentLabel;
  String? _selectedRisk;
  bool _isSaving = false;
  File? _newImage;
  static const String _updateReportErrorMessage = "Error al eliminar reporte";

  final List<String> _incidentTypes = const [
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

  final Map<String, String> _incidentMap = const {
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

  final List<String> _riskLevels = const ["bajo", "medio", "alto"];

  @override
  void initState() {
    super.initState();

    _tituloController = TextEditingController(text: widget.alert.titulo);

    _descripcionController = TextEditingController(
      text: widget.alert.descripcion,
    );

    _selectedIncidentLabel = _getIncidentLabelFromCode(
      widget.alert.tipoIncidente,
    );
    _selectedRisk = widget.alert.nivelRiesgo.toLowerCase();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  String? _getIncidentLabelFromCode(String? code) {
    if (code == null || code.trim().isEmpty) return null;

    for (final entry in _incidentMap.entries) {
      if (entry.value == code) {
        return entry.key;
      }
    }

    if (_incidentTypes.contains(code)) {
      return code;
    }

    return null;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80, // Mantenemos la calidad para ahorrar espacio en GCS
    );

    if (pickedFile != null) {
      setState(() => _newImage = File(pickedFile.path));
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
    } catch (_) {
      return false;
    }
  }

  void _showUpdateReportError() {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(
        content: Text(_updateReportErrorMessage),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required bool isDark,
    required String labelText,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: GoogleFonts.poppins(
        color: isDark ? AppColors.subtitleDark : AppColors.subtitleLight,
      ),
      filled: true,
      fillColor: isDark ? AppColors.cardDark : AppColors.cardLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
    );
  }

  Future<void> _updateReport() async {
    final connected = await _hasInternet();
    if (!mounted) return;

    if (!connected) {
      _showUpdateReportError();
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final incidentCode = _incidentMap[_selectedIncidentLabel];
    if (incidentCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Selecciona un tipo de incidente válido"),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final fields = {
        "titulo": _tituloController.text.trim(),
        "tipo_incidente": _selectedIncidentLabel!,
        "descripcion": _descripcionController.text.trim(),
        "nivel_riesgo": _selectedRisk ?? "bajo",
      };

      await _alertService.updateAlertMultipart(
        id: widget.alert.id!,
        fields: fields,
        imageFile: _newImage,
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Reporte actualizado correctamente"),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;

      _showUpdateReportError();
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final subtitleColor = isDark
        ? AppColors.subtitleDark
        : AppColors.subtitleLight;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "Editar reporte",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Corrige la información de tu reporte",
                style: GoogleFonts.poppins(fontSize: 14, color: subtitleColor),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _tituloController,
                style: GoogleFonts.poppins(color: textColor, fontSize: 14),
                decoration: _inputDecoration(
                  isDark: isDark,
                  labelText: "Título",
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Ingresa un título";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _selectedIncidentLabel,
                dropdownColor: cardColor,
                style: GoogleFonts.poppins(color: textColor, fontSize: 14),
                decoration: _inputDecoration(
                  isDark: isDark,
                  labelText: "Tipo de incidente",
                ),
                items: _incidentTypes
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(
                          item,
                          style: GoogleFonts.poppins(
                            color: textColor,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedIncidentLabel = value);
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Selecciona un tipo de incidente";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descripcionController,
                maxLines: 4,
                style: GoogleFonts.poppins(color: textColor, fontSize: 14),
                decoration: _inputDecoration(
                  isDark: isDark,
                  labelText: "Descripción",
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Ingresa una descripción";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Text(
                "Evidencia del reporte",
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image_search),
                    label: Text(
                      _newImage == null ? "Cambiar foto" : "Foto seleccionada",
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? AppColors.secondaryDark
                          : AppColors.secundary,
                      foregroundColor: AppColors.white,
                    ),
                  ),
                  const SizedBox(width: 15),
                  if (_newImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _newImage!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    )
                  else if (widget.alert.rutaFoto != null &&
                      widget.alert.rutaFoto!.startsWith('http'))
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.alert.rutaFoto!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _updateReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? AppColors.primaryDark
                        : AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.white,
                          ),
                        )
                      : Text(
                          "Guardar cambios",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
