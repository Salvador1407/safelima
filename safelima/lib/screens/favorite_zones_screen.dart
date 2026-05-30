import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safelima/core/app_colors.dart';
import 'package:safelima/core/app_data.dart';
import 'package:safelima/models/favorite_area.dart';
import 'package:safelima/services/favorite_area_service.dart';
import 'package:safelima/widgets/safe_card.dart';
import 'package:safelima/widgets/safe_empty_state.dart';
import 'package:safelima/widgets/safe_snack_bar.dart';
import 'package:safelima/widgets/safe_shimmer.dart';

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
      SafeSnackBar.showWarning(context, "No se pudieron cargar favoritos");
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

      SafeSnackBar.showError(context, "No se pudieron cargar favoritos");
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
      SafeSnackBar.showError(context, _favoriteUpdateErrorMessage);
      return;
    }

    try {
      await _favoriteService.removeFavorite(fav.citizenId, fav.gridId);

      if (!mounted) return;
      setState(() {
        _favorites.removeWhere((f) => f.id == fav.id);
      });

      SafeSnackBar.showWarning(context, "Zona eliminada de favoritos.");
    } catch (_) {
      if (!mounted) return;
      SafeSnackBar.showError(context, _favoriteUpdateErrorMessage);
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
    required Color textColor,
    required Color subtitleColor,
  }) {
    return SafeCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.zero,
      borderRadius: 20,
      onTap: () {
        Navigator.pop(context, fav);
      },
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
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 4,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SafeShimmer(
                  width: double.infinity,
                  height: 100,
                  borderRadius: 20,
                ),
              ),
            )
          : _favorites.isEmpty
          ? const SafeEmptyState(
              icon: Icons.favorite_border,
              iconColor: Colors.pinkAccent,
              title: "Aún no tienes zonas favoritas",
              message:
                  "Guarda zonas desde el mapa para volver a ellas rápidamente.",
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeader(cardColor, textColor, subtitleColor, isDark),
                const SizedBox(height: 18),
                ..._favorites.map(
                  (fav) => _buildFavoriteCard(
                    fav: fav,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                  ),
                ),
              ],
            ),
    );
  }
}
