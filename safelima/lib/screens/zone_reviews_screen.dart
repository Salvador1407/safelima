import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:safelima/core/app_colors.dart';
import 'package:safelima/models/summary.dart';
import 'package:safelima/models/zone_review.dart';
import 'package:safelima/screens/create_zone_review_screen.dart';
import 'package:safelima/services/zone_review_service.dart';
import 'package:safelima/services/review_like_service.dart';
import 'package:safelima/widgets/safe_card.dart';
import 'package:safelima/widgets/safe_empty_state.dart';
import 'package:safelima/widgets/safe_snack_bar.dart';
import 'package:safelima/widgets/safe_status_chip.dart';
import 'package:safelima/widgets/safe_shimmer.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ZoneReviewsScreen extends StatefulWidget {
  final int gridId;
  final String zoneName;

  const ZoneReviewsScreen({
    super.key,
    required this.gridId,
    required this.zoneName,
  });

  @override
  State<ZoneReviewsScreen> createState() => _ZoneReviewsScreenState();
}

class _ZoneReviewsScreenState extends State<ZoneReviewsScreen> {
  final ZoneReviewService _service = ZoneReviewService();
  final ReviewLikeService _likeService = ReviewLikeService();

  // Cambiamos a nullable para manejar el estado inicial
  Future<ZoneReviewSummary>? _future;

  final Map<int, bool> _likedReviews = {};
  final Map<int, int> _likeCount = {};
  final storage = const FlutterSecureStorage();
  int? _currentCitizenId;
  static const String _likeErrorMessage = "Error";

  @override
  void initState() {
    super.initState();
    // Ejecutamos la carga inicial
    _loadUserAndReviews();
  }

  Future<void> _loadUserAndReviews() async {
    final citizenIdStr = await storage.read(key: "citizen_id");
    if (citizenIdStr != null) {
      _currentCitizenId = int.tryParse(citizenIdStr);
    }
    // Una vez que tenemos el ID, cargamos las reseñas
    _reloadReviews();
  }

  Future<void> _reloadReviews() async {
    try {
      final summary = await _service.getReviewsByGrid(
        widget.gridId,
        citizenId: _currentCitizenId,
      );

      if (!mounted) return;

      setState(() {
        _future = Future.value(summary);

        for (final r in summary.reviews) {
          if (r.id != null) {
            _likedReviews[r.id!] = r.isLiked ?? false;
            _likeCount[r.id!] = r.likesCount ?? 0;
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _future = Future.error(e);
      });
    }
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

  void _showLikeError() {
    if (!mounted) return;

    SafeSnackBar.showError(context, _likeErrorMessage);
  }

  Future<void> _toggleLike(int reviewId) async {
    if (_currentCitizenId == null) return;

    final connected = await _hasInternet();

    if (!mounted) return;

    if (!connected) {
      _showLikeError();
      return;
    }

    final previousLiked = _likedReviews[reviewId] ?? false;
    final previousCount = _likeCount[reviewId] ?? 0;

    setState(() {
      _likedReviews[reviewId] = !previousLiked;
      _likeCount[reviewId] = previousCount + (previousLiked ? -1 : 1);
    });

    try {
      final result = await _likeService.toggleLike(
        citizenId: _currentCitizenId!,
        reviewId: reviewId,
      );

      if (!mounted) return;

      setState(() {
        _likedReviews[reviewId] = result.liked;
        _likeCount[reviewId] = result.likesCount;
      });
    } on SocketException {
      if (!mounted) return;

      setState(() {
        _likedReviews[reviewId] = previousLiked;
        _likeCount[reviewId] = previousCount;
      });

      _showLikeError();
    } on TimeoutException {
      if (!mounted) return;

      setState(() {
        _likedReviews[reviewId] = previousLiked;
        _likeCount[reviewId] = previousCount;
      });

      _showLikeError();
    } catch (e) {
      debugPrint("Error técnico al reaccionar a reseña: $e");

      if (!mounted) return;

      setState(() {
        _likedReviews[reviewId] = previousLiked;
        _likeCount[reviewId] = previousCount;
      });

      _showLikeError();
    }
  }

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

  List<BoxShadow> _softShadow(bool isDark) {
    return [
      BoxShadow(
        color: AppColors.black.withValues(alpha: isDark ? 0.24 : 0.08),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ];
  }

  Widget _stateCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return SafeEmptyState(
      icon: icon,
      iconColor: iconColor,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  Widget _ratingStars(int rating, {double size = 17}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (index) => Icon(
          index < rating ? Icons.star_rounded : Icons.star_border_rounded,
          size: size,
          color: Colors.amber,
        ),
      ),
    );
  }

  Widget _metaChip({
    required IconData icon,
    required String label,
    required Color foreground,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: foreground),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(ZoneReviewSummary summary, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: isDark
            ? null
            : LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.96),
                  AppColors.secundary.withValues(alpha: 0.92),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: isDark ? _cardColor(isDark) : null,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? _borderColor(isDark)
              : AppColors.white.withValues(alpha: 0.34),
        ),
        boxShadow: _softShadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.zoneName,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? _textColor(isDark) : AppColors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Experiencias ciudadanas de seguridad",
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark
                  ? _subtitleColor(isDark)
                  : AppColors.white.withValues(alpha: 0.86),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _metaChip(
                icon: Icons.star_rounded,
                label: "${summary.promedioCalificacion.toStringAsFixed(1)} / 5",
                foreground: Colors.amber.shade800,
                background: Colors.amber.withValues(alpha: 0.18),
              ),
              _metaChip(
                icon: Icons.reviews_outlined,
                label: "${summary.totalReviews} reseñas",
                foreground: isDark ? AppColors.secondaryDark : AppColors.white,
                background: AppColors.white.withValues(
                  alpha: isDark ? 0.08 : 0.18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reviewCard({
    required ZoneReview review,
    required int reviewId,
    required bool isLikedLocal,
    required int likesCountLocal,
    required bool isDark,
  }) {
    final dateText = review.fechaPublicacion == null
        ? "Sin fecha"
        : DateFormat(
            'dd/MM/yyyy HH:mm',
          ).format(review.fechaPublicacion!.toLocal());

    return SafeCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.citizenName ?? "Usuario Anónimo",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _textColor(isDark),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _ratingStars(review.calificacion),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            review.comentario,
            style: GoogleFonts.poppins(
              color: _textColor(isDark),
              height: 1.45,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              InkWell(
                onTap: () => _toggleLike(reviewId),
                borderRadius: BorderRadius.circular(999),
                child: SafeStatusChip(
                  icon: isLikedLocal ? Icons.favorite : Icons.favorite_border,
                  label: "$likesCountLocal",
                  tone: isLikedLocal
                      ? SafeStatusTone.danger
                      : SafeStatusTone.neutral,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  dateText,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: _subtitleColor(isDark),
                  ),
                ),
              ),
            ],
          ),
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
        elevation: 0,
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.mainGradient),
        ),
        title: Text(
          "Reseñas de ${widget.zoneName}",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.rate_review),
        label: Text(
          "Reseñar",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => CreateZoneReviewScreen(
                gridId: widget.gridId,
                zoneName: widget.zoneName,
                citizenId: _currentCitizenId!,
              ),
            ),
          );

          if (created == true) {
            await _reloadReviews();
          }
        },
      ),
      body: FutureBuilder<ZoneReviewSummary>(
        future: _future,
        builder: (context, snapshot) {
          // Estado de carga inicial
          if (snapshot.connectionState == ConnectionState.waiting &&
              !_likedReviews.isNotEmpty) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 4,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SafeShimmer(
                  width: double.infinity,
                  height: 120,
                  borderRadius: 18,
                ),
              ),
            );
          }

          // Manejo de errores
          if (snapshot.hasError) {
            return _stateCard(
              icon: Icons.error_outline,
              iconColor: AppColors.danger,
              title: "Error al cargar reseñas",
              message: "No se pudo obtener la información de esta zona.",
              actionLabel: "Reintentar",
              onAction: _reloadReviews,
            );
          }

          // Si no hay datos
          if (!snapshot.hasData || snapshot.data!.reviews.isEmpty) {
            return RefreshIndicator(
              onRefresh: _reloadReviews,
              child: ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  _stateCard(
                    icon: Icons.forum_outlined,
                    iconColor: AppColors.primary,
                    title: "Aún no hay reseñas",
                    message:
                        "Sé el primero en compartir una experiencia de seguridad sobre esta zona.",
                  ),
                ],
              ),
            );
          }

          final summary = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _reloadReviews,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Panel de Resumen de la Zona
                _summaryCard(summary, isDark),
                const SizedBox(height: 20),

                // Listado de Reseñas Individuales
                ...summary.reviews.map((review) {
                  final rId = review.id!;
                  final isLikedLocal = _likedReviews[rId] ?? false;
                  final likesCountLocal = _likeCount[rId] ?? 0;

                  return _reviewCard(
                    review: review,
                    reviewId: rId,
                    isLikedLocal: isLikedLocal,
                    likesCountLocal: likesCountLocal,
                    isDark: isDark,
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
