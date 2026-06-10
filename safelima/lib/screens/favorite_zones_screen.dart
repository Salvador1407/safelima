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

  List<BoxShadow> _softShadow(bool isDark) {
    return [
      BoxShadow(
        color: AppColors.black.withValues(alpha: isDark ? 0.24 : 0.08),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = _backgroundColor(isDark);
    final cardColor = _cardColor(isDark);
    final textColor = _textColor(isDark);
    final subtitleColor = _subtitleColor(isDark);
    final borderColor = _borderColor(isDark);

    return Scaffold(
      backgroundColor: bgColor,
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
          "Mis zonas favoritas",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.white,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: _loading
          ? _buildLoadingList()
          : _favorites.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: SafeEmptyState(
                      icon: Icons.favorite_border,
                      iconColor: AppColors.danger,
                      title: "Aún no tienes zonas favoritas",
                      message:
                          "Guarda zonas desde el mapa para volver a ellas rápidamente.",
                    ),
                  ),
                )
              : ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                  children: [
                    _buildHeader(
                      cardColor: cardColor,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      borderColor: borderColor,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 18),
                    ..._favorites.map(
                      (fav) => _buildFavoriteCard(
                        fav: fav,
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                        borderColor: borderColor,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      itemCount: 4,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: SafeShimmer(
          width: double.infinity,
          height: 106,
          borderRadius: 22,
        ),
      ),
    );
  }

  Widget _buildHeader({
    required Color cardColor,
    required Color textColor,
    required Color subtitleColor,
    required Color borderColor,
    required bool isDark,
  }) {
    final accentColor = isDark ? AppColors.secondaryDark : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: isDark
            ? null
            : const LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.secundary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: isDark ? cardColor : null,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? borderColor.withValues(alpha: 0.75)
              : AppColors.white.withValues(alpha: 0.34),
        ),
        boxShadow: _softShadow(isDark),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -42,
            right: -34,
            child: Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withValues(alpha: isDark ? 0.04 : 0.10),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isDark
                      ? accentColor.withValues(alpha: 0.18)
                      : AppColors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? accentColor.withValues(alpha: 0.25)
                        : AppColors.white.withValues(alpha: 0.24),
                  ),
                ),
                child: Icon(
                  Icons.bookmark_added_rounded,
                  color: isDark ? accentColor : AppColors.white,
                  size: 27,
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
                        letterSpacing: -0.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Toca una zona para verla en el mapa.",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        height: 1.3,
                        color: isDark
                            ? subtitleColor
                            : AppColors.white.withValues(alpha: 0.86),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCard({
    required FavoriteArea fav,
    required Color textColor,
    required Color subtitleColor,
    required Color borderColor,
    required bool isDark,
  }) {
    final accentColor = AppColors.danger;
    final cardColor = _cardColor(isDark);

    return SafeCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.zero,
      borderRadius: 22,
      backgroundColor: cardColor,
      borderColor: borderColor.withValues(alpha: isDark ? 0.55 : 0.85),
      onTap: () {
        Navigator.pop(context, fav);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned(
              top: -34,
              right: -32,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(alpha: isDark ? 0.10 : 0.07),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accentColor.withValues(alpha: isDark ? 0.22 : 0.15),
                          accentColor.withValues(alpha: isDark ? 0.10 : 0.07),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.20),
                      ),
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: AppColors.danger,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fav.grid?.nombre ?? "Zona sin nombre",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                            letterSpacing: -0.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Toca para ver esta zona en el mapa",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            color: subtitleColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: "Eliminar favorito",
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.danger,
                    ),
                    onPressed: () => _removeFavorite(fav),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}