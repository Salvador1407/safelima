import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safelima/core/app_colors.dart';
import 'package:safelima/services/zone_review_service.dart';
import 'package:safelima/widgets/safe_buttons.dart';
import 'package:safelima/widgets/safe_card.dart';
import 'package:safelima/widgets/safe_input_decoration.dart';
import 'package:safelima/widgets/safe_snack_bar.dart';

class CreateZoneReviewScreen extends StatefulWidget {
  final int gridId;
  final String zoneName;
  final int citizenId;

  const CreateZoneReviewScreen({
    super.key,
    required this.gridId,
    required this.zoneName,
    required this.citizenId,
  });

  @override
  State<CreateZoneReviewScreen> createState() => _CreateZoneReviewScreenState();
}

class _CreateZoneReviewScreenState extends State<CreateZoneReviewScreen> {
  final ZoneReviewService _service = ZoneReviewService();
  final TextEditingController _commentController = TextEditingController();

  int _rating = 0;
  bool _loading = false;

  Color _backgroundColor(bool isDark) =>
      isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
  Color _textColor(bool isDark) =>
      isDark ? AppColors.textDark : AppColors.textLight;
  Color _subtitleColor(bool isDark) =>
      isDark ? AppColors.subtitleDark : AppColors.subtitleLight;

  Future<void> _submitReview() async {
    final comment = _commentController.text.trim();

    if (_rating < 1) {
      SafeSnackBar.showWarning(context, "Selecciona una calificación");
      return;
    }

    if (comment.length < 3) {
      SafeSnackBar.showWarning(context, "Escribe un comentario válido");
      return;
    }

    setState(() => _loading = true);

    try {
      await _service.createReview({
        "citizen_id": widget.citizenId,
        "grid_id": widget.gridId,
        "calificacion": _rating,
        "comentario": comment,
      });

      if (!mounted) return;

      SafeSnackBar.showSuccess(context, "Reseña publicada correctamente");

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      SafeSnackBar.showError(context, "Error al publicar reseña: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: _backgroundColor(isDark),
      appBar: AppBar(
        title: Text(
          "Escribir reseña",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SafeCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.zoneName,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _textColor(isDark),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Comparte tu experiencia de seguridad en esta zona.",
                style: GoogleFonts.poppins(color: _subtitleColor(isDark)),
              ),
              const SizedBox(height: 20),

              Text(
                "Calificación",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: _textColor(isDark),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (index) {
                  final star = index + 1;
                  return IconButton(
                    onPressed: () {
                      setState(() => _rating = star);
                    },
                    icon: Icon(
                      star <= _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                  );
                }),
              ),

              const SizedBox(height: 16),
              Text(
                "Comentario",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: _textColor(isDark),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                maxLines: 5,
                maxLength: 500,
                style: GoogleFonts.poppins(color: _textColor(isDark)),
                decoration: safeInputDecoration(
                  context,
                  labelText: "Comentario",
                  hintText: "Describe cómo fue tu experiencia en esta zona...",
                  prefixIcon: Icons.rate_review_outlined,
                ),
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: SafeButton.primary(
                  onPressed: _loading ? null : _submitReview,
                  label: "Publicar reseña",
                  isLoading: _loading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
