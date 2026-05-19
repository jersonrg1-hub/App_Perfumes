import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:perfuteca/config/env.dart';
import 'package:perfuteca/theme/app_colors.dart';
import 'package:shimmer/shimmer.dart';

// Caché de imágenes con límite: 300 imágenes máx · 7 días de vigencia.
// Evita que el celular acumule cientos de MB con el tiempo.
final _imageCacheManager = CacheManager(
  Config(
    'perfume_images',
    stalePeriod: const Duration(days: 7),
    maxNrOfCacheObjects: 300,
  ),
);

class PerfumeImage extends StatelessWidget {
  const PerfumeImage({
    super.key,
    required this.imageUrl,
    this.marca,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final String? imageUrl;
  final String? marca;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final fullUrl = imageUrl != null ? '${Env.baseUrl}$imageUrl' : null;

    final child = fullUrl != null
        ? CachedNetworkImage(
            imageUrl:     fullUrl,
            cacheManager: _imageCacheManager,
            width:  width,
            height: height,
            fit:    fit,
            placeholder: (_, __) => _Shimmer(width: width, height: height),
            errorWidget: (_, __, ___) =>
                _Placeholder(width: width, height: height, marca: marca),
          )
        : _Placeholder(width: width, height: height, marca: marca);

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }
}

class _Shimmer extends StatelessWidget {
  const _Shimmer({this.width, this.height});
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor:      AppColors.primaryLight,
    highlightColor: AppColors.primaryPale,
    child: Container(
      width:  width,
      height: height,
      color:  AppColors.primaryLight,
    ),
  );
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({this.width, this.height, this.marca});
  final double? width;
  final double? height;
  final String? marca;

  static const _gradients = [
    [Color(0xFFb8724a), Color(0xFFd4956e)],
    [Color(0xFF7C3AED), Color(0xFFA78BFA)],
    [Color(0xFF0369A1), Color(0xFF38BDF8)],
    [Color(0xFF047857), Color(0xFF34D399)],
    [Color(0xFFB45309), Color(0xFFFBBF24)],
    [Color(0xFFBE185D), Color(0xFFF472B6)],
    [Color(0xFF4338CA), Color(0xFF818CF8)],
    [Color(0xFF9F1239), Color(0xFFFB7185)],
  ];

  @override
  Widget build(BuildContext context) {
    final seed    = (marca ?? '').hashCode.abs();
    final pair    = _gradients[seed % _gradients.length];
    final initial = (marca?.isNotEmpty == true) ? marca![0].toUpperCase() : '?';

    return Container(
      width:  width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
          colors: pair,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color:      Colors.white54,
            fontSize:   56,
            fontWeight: FontWeight.w900,
            letterSpacing: -2,
          ),
        ),
      ),
    );
  }
}
