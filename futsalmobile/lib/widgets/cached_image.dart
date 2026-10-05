import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// A network image backed by a persistent disk cache.
///
/// [Image.network] caches decoded frames in memory only, so every app launch
/// re-downloads every crest, avatar and banner — which is where almost all of
/// the project's Cloud Storage egress comes from. The same twenty club logos
/// appear on nearly every screen, so caching them on disk removes the bulk of
/// the repeat traffic.
///
/// The call shape mirrors the `Image.network` it replaces; [errorBuilder] takes
/// a plain builder since the error and stack trace were unused at every site.
class CachedImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final WidgetBuilder? errorBuilder;

  const CachedImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorBuilder,
  });

  Widget _error(BuildContext context) =>
      errorBuilder?.call(context) ?? SizedBox(width: width, height: height);

  @override
  Widget build(BuildContext context) {
    // CachedNetworkImage asserts on an empty url, which several callers can
    // still pass when a club or player record has no image.
    if (url.isEmpty) return Builder(builder: _error);

    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (_, _) => SizedBox(width: width, height: height),
      errorWidget: (context, _, _) => _error(context),
    );
  }
}
