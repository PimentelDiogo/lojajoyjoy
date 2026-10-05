import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Foto de produto com placeholder (sem foto, carregando ou erro).
class ProductImage extends StatelessWidget {
  const ProductImage({this.url, this.fit = BoxFit.cover, super.key});

  final String? url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: scheme.surfaceContainerHigh,
      child: Center(
        child: Icon(
          Icons.checkroom_outlined,
          size: 40,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
    if (url == null) return placeholder;
    return CachedNetworkImage(
      imageUrl: url!,
      fit: fit,
      placeholder: (_, _) => placeholder,
      errorWidget: (_, _, _) => placeholder,
    );
  }
}
