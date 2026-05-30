import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safelima/core/app_colors.dart';
import 'package:safelima/services/zone_review_service.dart';

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
  Color _cardColor(bool isDark) =>
      isDark ? AppColors.cardDark : AppColors.cardLight;
  Color _textColor(bool isDark) =>
      isDark ? AppColors.textDark : AppColors.textLight;
  Color _subtitleColor(bool isDark) =>
      isDark ? AppColors.subtitleDark : AppColors.subtitleLight;
  Color _borderColor(bool isDark) =>
      isDark ? AppColors.borderDark : AppColors.borderLight;

  Future<void> _submitReview() async {
    final comment = _commentController.text.trim();

    if (_rating < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Selecciona una calificación"),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (comment.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Escribe un comentario válido"),
          backgroundColor: AppColors.warning,
        ),
      );
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Reseña publicada correctamente"),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al publicar reseña: $e"),
          backgroundColor: AppColors.danger,
        ),
      );
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
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _cardColor(isDark),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderColor(isDark)),
          ),
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
                decoration: InputDecoration(
                  hintText: "Describe cómo fue tu experiencia en esta zona...",
                  hintStyle: GoogleFonts.poppins(color: _subtitleColor(isDark)),
                  filled: true,
                  fillColor: _backgroundColor(isDark),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? AppColors.primaryDark
                        : AppColors.primary,
                    foregroundColor: AppColors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.white,
                          ),
                        )
                      : Text(
                          "Publicar reseña",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
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
