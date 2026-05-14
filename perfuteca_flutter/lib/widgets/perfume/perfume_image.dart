import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:perfuteca/config/env.dart';
import 'package:perfuteca/theme/app_colors.dart';
import 'package:shimmer/shimmer.dart';

class PerfumeImage extends StatelessWidget {
  const PerfumeImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final fullUrl = imageUrl != null ? '${Env.baseUrl}$imageUrl' : null;

    final child = fullUrl != null
        ? CachedNetworkImage(
            imageUrl: fullUrl,
            width:  width,
            height: height,
            fit:    fit,
            placeholder: (_, __) => _Shimmer(width: width, height: height),
            errorWidget: (_, __, ___) => _Placeholder(width: width, height: height),
          )
        : _Placeholder(width: width, height: height);

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
  const _Placeholder({this.width, this.height});
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) => Container(
    width:  width,
    height: height,
    color:  AppColors.primaryPale,
    child: const Icon(
      Icons.water_drop_outlined,
      color: AppColors.primary,
      size: 32,
    ),
  );
}
