import 'package:flutter/material.dart';
import 'package:joyjoy/core/theme/app_spacing.dart';
import 'package:joyjoy/core/widgets/product_card.dart';
import 'package:joyjoy/core/widgets/product_image.dart';

/// Galeria do produto: carrossel com bolinhas (celular) ou miniaturas ao lado
/// da foto principal (tablet/desktop), como nas referências.
class ProductGallery extends StatefulWidget {
  const ProductGallery({
    required this.imageUrls,
    this.showThumbnails = false,
    super.key,
  });

  final List<String> imageUrls;
  final bool showThumbnails;

  @override
  State<ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<ProductGallery> {
  final _pageController = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    setState(() => _index = index);
    if (_pageController.hasClients) {
      _pageController.jumpToPage(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.imageUrls;
    final main = ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AspectRatio(
        aspectRatio: ProductCard.imageAspectRatio,
        child: urls.isEmpty
            ? const ProductImage()
            : PageView.builder(
                controller: _pageController,
                itemCount: urls.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => Semantics(
                  image: true,
                  label: 'Foto ${i + 1} de ${urls.length}',
                  child: ProductImage(url: urls[i]),
                ),
              ),
      ),
    );

    if (urls.length <= 1) return main;

    if (widget.showThumbnails) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Column(
              children: [
                for (var i = 0; i < urls.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: _Thumbnail(
                      url: urls[i],
                      selected: i == _index,
                      label: 'Ver foto ${i + 1}',
                      onTap: () => _goTo(i),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: main),
        ],
      );
    }

    return Column(
      children: [
        main,
        const SizedBox(height: AppSpacing.sm),
        _Dots(count: urls.length, index: _index),
      ],
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.url,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final String url;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: AspectRatio(
            aspectRatio: ProductCard.imageAspectRatio,
            child: ProductImage(url: url),
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Foto ${index + 1} de $count',
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == index ? 18 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == index ? scheme.primary : scheme.outlineVariant,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
        ],
      ),
    );
  }
}
