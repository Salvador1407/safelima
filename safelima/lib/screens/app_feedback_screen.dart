import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safelima/core/app_colors.dart';
import 'package:safelima/models/app_feedback.dart';
import 'package:safelima/services/app_feedback_service.dart';
import 'package:safelima/widgets/safe_buttons.dart';
import 'package:safelima/widgets/safe_card.dart';
import 'package:safelima/widgets/safe_input_decoration.dart';
import 'package:safelima/widgets/safe_snack_bar.dart';

class AppFeedbackScreen extends StatefulWidget {
  final int citizenId;
  final bool isEdit;

  const AppFeedbackScreen({
    super.key,
    required this.citizenId,
    this.isEdit = false,
  });

  @override
  State<AppFeedbackScreen> createState() => _AppFeedbackScreenState();
}

class _AppFeedbackScreenState extends State<AppFeedbackScreen> {
  final AppFeedbackService _service = AppFeedbackService();
  final TextEditingController _commentController = TextEditingController();

  int _rating = 0;
  bool _loading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating < 1 || _rating > 5) {
      SafeSnackBar.showWarning(context, 'Selecciona una calificación de 1 a 5');
      return;
    }

    setState(() => _loading = true);

    try {
      if (widget.isEdit) {
        await _service.updateFeedback(widget.citizenId, {
          'estrellas': _rating,
          'comentario': _commentController.text.trim().isEmpty
              ? null
              : _commentController.text.trim(),
        });
      } else {
        await _service.createFeedback(
          AppFeedback(
            citizenId: widget.citizenId,
            estrellas: _rating,
            comentario: _commentController.text.trim().isEmpty
                ? null
                : _commentController.text.trim(),
          ),
        );
      }

      if (!mounted) return;

      SafeSnackBar.showSuccess(
        context,
        'Gracias por ayudarnos a mejorar SafeLima',
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      SafeSnackBar.showError(context, 'Error al enviar feedback: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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

  Widget _buildStar(int index, bool isDark) {
    final selected = index <= _rating;
    final starColor = selected
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
                : _borderColor(isDark).withValues(alpha: isDark ? 0.22 : 0.35),
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
            color: starColor,
            size: 30,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = _textColor(isDark);
    final subtitleColor = _subtitleColor(isDark);
    final cardColor = _cardColor(isDark);
    final borderColor = _borderColor(isDark);

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
          "Califica SafeLima",
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
                      color: (isDark ? AppColors.secondaryDark : AppColors.primary)
                          .withValues(alpha: isDark ? 0.10 : 0.07),
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
                              AppColors.accent.withValues(
                                alpha: isDark ? 0.24 : 0.18,
                              ),
                              AppColors.accent.withValues(
                                alpha: isDark ? 0.12 : 0.08,
                              ),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(19),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.25),
                          ),
                        ),
                        child: const Icon(
                          Icons.rate_review_outlined,
                          color: AppColors.accent,
                          size: 27,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        "¿Cómo fue tu experiencia general con la app?",
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          height: 1.32,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          letterSpacing: -0.15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 46,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.secondaryDark
                              : AppColors.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 24),
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
                      TextField(
                        controller: _commentController,
                        maxLines: 4,
                        maxLength: 500,
                        enabled: !_loading,
                        style: GoogleFonts.poppins(
                          color: textColor,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                        cursorColor: isDark
                            ? AppColors.secondaryDark
                            : AppColors.primary,
                        decoration: safeInputDecoration(
                          context,
                          labelText: "Comentario (opcional)",
                          hintText: "Cuéntanos qué podríamos mejorar",
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
                          onPressed: _loading ? null : _submit,
                          label: widget.isEdit ? "Actualizar" : "Enviar",
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