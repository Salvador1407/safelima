import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safelima/core/app_colors.dart';
import 'package:safelima/core/app_data.dart';
import 'package:safelima/models/favorite_area.dart';
import 'package:safelima/services/favorite_area_service.dart';

class FavoriteZonesScreen extends StatefulWidget {
  const FavoriteZonesScreen({super.key});

  @override
  State<FavoriteZonesScreen> createState() => _FavoriteZonesScreenState();
}

class _FavoriteZonesScreenState extends State<FavoriteZonesScreen> {
  final FavoriteAreaService _favoriteService = FavoriteAreaService();

  List<FavoriteArea> _favorites = [];
  bool _loading = true;

  static const String _favoriteUpdateErrorMessage =
      "No se pudo actualizar favorito";

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final connected = await _hasInternet();
    if (!mounted) return;

    if (!connected) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se pudieron cargar favoritos"),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    try {
      final favorites = await _favoriteService.getFavoritesByCitizen(
        AppData.citizen_id,
      );

      if (!mounted) return;
      setState(() {
        _favorites = favorites;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se pudieron cargar favoritos"),
          backgroundColor: AppColors.danger,
        ),
      );
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

  Future<void> _removeFavorite(FavoriteArea fav) async {
    final connected = await _hasInternet();
    if (!mounted) return;

    if (!connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(_favoriteUpdateErrorMessage),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    try {
      await _favoriteService.removeFavorite(fav.citizenId, fav.gridId);

      if (!mounted) return;
      setState(() {
        _favorites.removeWhere((f) => f.id == fav.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Zona eliminada de favoritos."),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(_favoriteUpdateErrorMessage),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  List<BoxShadow> _softShadow(bool isDark) {
    return [
      BoxShadow(
        color: AppColors.black.withValues(alpha: isDark ? 0.24 : 0.08),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ];
  }

  Widget _buildEmptyState(Color subtitleColor, Color cardColor, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            boxShadow: _softShadow(isDark),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.pinkAccent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_border,
                  color: Colors.pinkAccent,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Aún no tienes zonas favoritas",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textDark : AppColors.textLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Guarda zonas desde el mapa para volver a ellas rápidamente.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  height: 1.4,
                  color: subtitleColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    Color cardColor,
    Color textColor,
    Color subtitleColor,
    bool isDark,
  ) {
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
        color: isDark ? cardColor : null,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? AppColors.borderDark
              : AppColors.white.withValues(alpha: 0.34),
        ),
        boxShadow: _softShadow(isDark),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: isDark ? 0.08 : 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.bookmark_added,
              color: isDark ? AppColors.secondaryDark : AppColors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${_favorites.length} zonas guardadas",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? textColor : AppColors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Toca una zona para verla en el mapa.",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: isDark
                        ? subtitleColor
                        : AppColors.white.withValues(alpha: 0.86),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCard({
    required FavoriteArea fav,
    required Color cardColor,
    required Color textColor,
    required Color subtitleColor,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: _softShadow(isDark),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.pinkAccent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.favorite, color: Colors.pinkAccent),
        ),
        title: Text(
          fav.grid?.nombre ?? "Zona sin nombre",
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            "Toca para ver esta zona en el mapa",
            style: GoogleFonts.poppins(fontSize: 12.5, color: subtitleColor),
          ),
        ),
        trailing: IconButton(
          tooltip: "Eliminar favorito",
          icon: const Icon(Icons.delete_outline, color: AppColors.danger),
          onPressed: () => _removeFavorite(fav),
        ),
        onTap: () {
          Navigator.pop(context, fav);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final subtitleColor = isDark
        ? AppColors.subtitleDark
        : AppColors.subtitleLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.mainGradient),
        ),
        title: Text(
          "Mis zonas favoritas",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _favorites.isEmpty
          ? _buildEmptyState(subtitleColor, cardColor, isDark)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeader(cardColor, textColor, subtitleColor, isDark),
                const SizedBox(height: 18),
                ..._favorites.map(
                  (fav) => _buildFavoriteCard(
                    fav: fav,
                    cardColor: cardColor,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
    );
  }
}
