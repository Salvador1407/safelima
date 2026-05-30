import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safelima/core/app_colors.dart';
import 'package:safelima/models/app_feedback.dart';
import 'package:safelima/services/app_feedback_service.dart';

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

  Future<void> _submit() async {
    if (_rating < 1 || _rating > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una calificación de 1 a 5')),
      );
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gracias por ayudarnos a mejorar SafeLima'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar feedback: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildStar(int index) {
    return IconButton(
      onPressed: () {
        setState(() => _rating = index);
      },
      icon: Icon(
        index <= _rating ? Icons.star : Icons.star_border,
        color: Colors.amber,
        size: 34,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          "Califica SafeLima",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "¿Cómo fue tu experiencia general con la app?",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) => _buildStar(index + 1)),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _commentController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: "Comentario (opcional)",
                hintText: "Cuéntanos qué podríamos mejorar",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const CircularProgressIndicator()
                    : Text(widget.isEdit ? "Actualizar" : "Enviar"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}