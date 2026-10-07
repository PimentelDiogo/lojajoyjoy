import 'package:flutter/material.dart';
import 'package:joyjoy/core/theme/app_spacing.dart';
import 'package:joyjoy/core/widgets/product_image.dart';
import 'package:joyjoy/features/admin/products/domain/entities/product_draft.dart';

/// Fotos da peça: a primeira é a capa. Botões (e não arrastar) para
/// reordenar — funciona igual no celular e com leitor de tela.
class ProductImagesEditor extends StatelessWidget {
  const ProductImagesEditor({
    required this.images,
    required this.onAdd,
    required this.onMove,
    required this.onMakeCover,
    required this.onRemove,
    this.isPicking = false,
    this.canAdd = true,
    super.key,
  });

  final List<DraftImage> images;
  final VoidCallback onAdd;
  final void Function(int from, int to) onMove;
  final ValueChanged<int> onMakeCover;
  final ValueChanged<int> onRemove;
  final bool isPicking;
  final bool canAdd;

  static const double tileWidth = 150;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
    children: [
      for (final (index, image) in images.indexed)
        _ImageTile(
          key: ValueKey(image.key),
          image: image,
          index: index,
          count: images.length,
          onMove: onMove,
          onMakeCover: onMakeCover,
          onRemove: onRemove,
        ),
      if (canAdd) _AddTile(onTap: isPicking ? null : onAdd, busy: isPicking),
    ],
  );
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({
    required this.image,
    required this.index,
    required this.count,
    required this.onMove,
    required this.onMakeCover,
    required this.onRemove,
    super.key,
  });

  final DraftImage image;
  final int index;
  final int count;
  final void Function(int from, int to) onMove;
  final ValueChanged<int> onMakeCover;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isCover = index == 0;
    final picked = image.picked;

    return Semantics(
      container: true,
      label: isCover ? 'Foto ${index + 1}, capa' : 'Foto ${index + 1}',
      child: SizedBox(
        width: ProductImagesEditor.tileWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (picked != null)
                      Image.memory(picked.bytes, fit: BoxFit.cover)
                    else
                      ProductImage(url: image.url),
                    if (isCover)
                      Positioned(
                        left: AppSpacing.xs,
                        top: AppSpacing.xs,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            'Capa',
                            style: textTheme.labelSmall?.copyWith(
                              color: scheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      right: 2,
                      top: 2,
                      child: IconButton.filled(
                        tooltip: 'Remover foto',
                        onPressed: () => onRemove(index),
                        icon: const Icon(Icons.close, size: 18),
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          backgroundColor: scheme.surfaceContainerLowest,
                          foregroundColor: scheme.onSurface,
                        ),
                      ),
                    ),
                    if (image.isNew)
                      Positioned(
                        left: AppSpacing.xs,
                        bottom: AppSpacing.xs,
                        child: Tooltip(
                          message: 'Ainda não salva',
                          child: Icon(
                            Icons.cloud_upload_outlined,
                            size: 18,
                            color: scheme.onPrimary,
                            shadows: const [Shadow(blurRadius: 4)],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _TinyButton(
                  tooltip: 'Mover para a esquerda',
                  icon: Icons.chevron_left,
                  onPressed: index > 0 ? () => onMove(index, index - 1) : null,
                ),
                _TinyButton(
                  tooltip: 'Usar como capa',
                  icon: isCover ? Icons.star : Icons.star_border,
                  onPressed: isCover ? null : () => onMakeCover(index),
                ),
                _TinyButton(
                  tooltip: 'Mover para a direita',
                  icon: Icons.chevron_right,
                  onPressed: index < count - 1
                      ? () => onMove(index, index + 1)
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TinyButton extends StatelessWidget {
  const _TinyButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Icon(icon, size: 20),
    visualDensity: VisualDensity.compact,
  );
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap, required this.busy});

  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Adicionar fotos',
      excludeSemantics: true,
      child: SizedBox(
        width: ProductImagesEditor.tileWidth,
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: Material(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Center(
                child: busy
                    ? const CircularProgressIndicator()
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            size: 32,
                            color: scheme.primary,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          const Text(
                            'Adicionar\nfotos',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
