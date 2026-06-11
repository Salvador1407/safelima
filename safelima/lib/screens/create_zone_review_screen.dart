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

  Color _cardColor(bool isDark) =>
      isDark ? AppColors.cardDark : AppColors.cardLight;

  Color _textColor(bool isDark) =>
      isDark ? AppColors.textDark : AppColors.textLight;

  Color _subtitleColor(bool isDark) =>
      isDark ? AppColors.subtitleDark : AppColors.subtitleLight;

  Color _borderColor(bool isDark) =>
      isDark ? AppColors.borderDark : AppColors.borderLight;

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

  Widget _buildStar(int index, bool isDark) {
    final selected = index <= _rating;
    final color = selected
        ? AppColors.accent
        : _subtitleColor(isDark).withValues(alpha: 0.45);

    return AnimatedScale(
      scale: selected ? 1.08 : 1.0,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      child: InkWell(
        onTap: _loading ? null : () => setState(() => _rating = index),
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: 48,
          height: 48,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected
                ? AppColors.accent.withValues(alpha: isDark ? 0.18 : 0.14)
                : _borderColor(isDark).withValues(alpha: isDark ? 0.22 : 0.34),
            border: Border.all(
              color: selected
                  ? AppColors.accent.withValues(alpha: 0.42)
                  : _borderColor(isDark).withValues(alpha: 0.65),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Icon(
            selected ? Icons.star_rounded : Icons.star_border_rounded,
            color: color,
            size: 30,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = _textColor(isDark);
    final subtitleColor = _subtitleColor(isDark);
    final cardColor = _cardColor(isDark);
    final borderColor = _borderColor(isDark);
    final accentColor = isDark ? AppColors.secondaryDark : AppColors.primary;

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
          "Escribir reseña",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.white,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
        child: SafeCard(
          padding: EdgeInsets.zero,
          backgroundColor: cardColor,
          borderColor: borderColor.withValues(alpha: isDark ? 0.55 : 0.85),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Positioned(
                  top: -52,
                  right: -42,
                  child: Container(
                    width: 138,
                    height: 138,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor.withValues(
                        alpha: isDark ? 0.10 : 0.07,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -48,
                  left: -44,
                  child: Container(
                    width: 118,
                    height: 118,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent.withValues(
                        alpha: isDark ? 0.09 : 0.08,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              accentColor.withValues(
                                alpha: isDark ? 0.24 : 0.18,
                              ),
                              accentColor.withValues(
                                alpha: isDark ? 0.12 : 0.08,
                              ),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(19),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Icon(
                          Icons.location_on_outlined,
                          color: accentColor,
                          size: 27,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        widget.zoneName,
                        style: GoogleFonts.poppins(
                          fontSize: 21,
                          height: 1.18,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          letterSpacing: -0.25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Comparte tu experiencia de seguridad en esta zona.",
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          height: 1.35,
                          color: subtitleColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 46,
                        height: 4,
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Calificación",
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.backgroundDark.withValues(alpha: 0.42)
                              : AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: borderColor.withValues(
                              alpha: isDark ? 0.48 : 0.80,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            5,
                            (index) => _buildStar(index + 1, isDark),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Comentario",
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _commentController,
                        maxLines: 5,
                        maxLength: 500,
                        enabled: !_loading,
                        style: GoogleFonts.poppins(
                          color: textColor,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                        cursorColor: accentColor,
                        decoration: safeInputDecoration(
                          context,
                          labelText: "Comentario",
                          hintText:
                              "Describe cómo fue tu experiencia en esta zona...",
                          prefixIcon: Icons.rate_review_outlined,
                        ).copyWith(
                          counterStyle: GoogleFonts.poppins(
                            color: subtitleColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}