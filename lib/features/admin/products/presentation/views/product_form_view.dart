import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:joyjoy/app/routes/app_routes.dart';
import 'package:joyjoy/core/errors/failure.dart';
import 'package:joyjoy/core/responsive/app_responsive.dart';
import 'package:joyjoy/core/responsive/responsive_page.dart';
import 'package:joyjoy/core/state/ui_state.dart';
import 'package:joyjoy/core/theme/app_spacing.dart';
import 'package:joyjoy/core/widgets/app_button.dart';
import 'package:joyjoy/core/widgets/feedback_states.dart';
import 'package:joyjoy/features/admin/products/domain/entities/product_draft.dart';
import 'package:joyjoy/features/admin/products/presentation/controllers/product_form_controller.dart';
import 'package:joyjoy/features/admin/products/presentation/widgets/admin_section_card.dart';
import 'package:joyjoy/features/admin/products/presentation/widgets/product_images_editor.dart';
import 'package:joyjoy/features/admin/products/presentation/widgets/variant_grid_editor.dart';
import 'package:joyjoy/features/catalog/domain/entities/gender.dart';

/// Cadastro/edição de peça (/admin/produtos/nova e /admin/produtos/:id).
class ProductFormView extends StatelessWidget {
  const ProductFormView({required this.tag, super.key});

  /// Tag do controller (id da peça ou `nova`).
  final String tag;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProductFormController>(tag: tag);
    return Obx(
      () => switch (controller.loadState.value) {
        UiIdle() || UiLoading() => const Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Center(child: CircularProgressIndicator()),
        ),
        UiFailure(:final failure) => ErrorState.fromFailure(
          failure,
          onRetry: () => unawaited(controller.load()),
        ),
        _ => _Form(controller: controller),
      },
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({required this.controller});

  final ProductFormController controller;

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          persist: false,
        ),
      );
  }

  Future<void> _save(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final failure = await controller.save();
    if (!context.mounted) return;
    if (failure == null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('“${controller.name.text.trim()}” salva.'),
            duration: const Duration(seconds: 3),
            persist: false,
          ),
        );
      unawaited(Get.offAllNamed<void>(AppRoutes.adminProducts));
      return;
    }
    _snack(context, failure.message);
  }

  Future<void> _pickImages(BuildContext context) async {
    final message = await controller.pickImages();
    if (message != null && context.mounted) _snack(context, message);
  }

  Future<void> _editColor(BuildContext context, DraftColor color) async {
    final result = await showColorDialog(
      context,
      initial: color,
      validate: (name, hex) => controller.updateColor(color.key, name, hex),
    );
    if (result is ColorRemoved) controller.removeColor(color.key);
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final textTheme = Theme.of(context).textTheme;
    final c = controller;

    final photos = Obx(
      () => AdminSectionCard(
        title: 'Fotos',
        subtitle:
            'Até ${ProductDraft.maxImages}. A primeira é a capa. '
            'Fotos grandes são reduzidas antes de enviar.',
        error: c.errors.value[ProductField.images],
        child: ProductImagesEditor(
          images: c.images.toList(),
          isPicking: c.isPicking.value,
          canAdd: c.remainingImages > 0,
          onAdd: () => unawaited(_pickImages(context)),
          onMove: c.moveImage,
          onMakeCover: c.makeCover,
          onRemove: c.removeImage,
        ),
      ),
    );

    final info = AdminSectionCard(
      title: 'Informações',
      child: Obx(() {
        final errors = c.errors.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: c.name,
              maxLength: 120,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => c.clearError(ProductField.name),
              decoration: InputDecoration(
                labelText: 'Nome da peça',
                hintText: 'Ex.: Vestido Midi Linho',
                errorText: errors[ProductField.name],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: c.description,
              minLines: 3,
              maxLines: 8,
              maxLength: 4000,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Descrição (opcional)',
                hintText: 'Tecido, caimento, medidas…',
                alignLabelWithHint: true,
                errorText: errors[ProductField.description],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Seção da loja', style: textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            SegmentedButton<Gender>(
              segments: [
                for (final g in Gender.values)
                  ButtonSegment(value: g, label: Text(g.label)),
              ],
              selected: {c.gender.value},
              showSelectedIcon: false,
              onSelectionChanged: (s) => c.setGender(s.first),
            ),
            const SizedBox(height: AppSpacing.md),
            _CategoryField(controller: c),
            const SizedBox(height: AppSpacing.md),
            ResponsiveBuilder(
              mobile: (_) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PriceField(controller: c, errors: errors),
                  const SizedBox(height: AppSpacing.sm),
                  _CompareAtField(controller: c, errors: errors),
                ],
              ),
              tablet: (_) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _PriceField(controller: c, errors: errors),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _CompareAtField(controller: c, errors: errors),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mostrar na loja'),
              subtitle: const Text(
                'Desligado, a peça fica oculta para clientes.',
              ),
              value: c.isActive.value,
              onChanged: c.isActive.call,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Destaque na página inicial'),
              value: c.isFeatured.value,
              onChanged: c.isFeatured.call,
            ),
          ],
        );
      }),
    );

    final variants = Obx(
      () => AdminSectionCard(
        title: 'Cores, tamanhos e estoque',
        subtitle: c.colors.isEmpty || c.sizes.isEmpty
            ? 'Adicione as cores e os tamanhos; depois informe o estoque.'
            : 'Total em estoque: ${c.totalStock} '
                  '${c.totalStock == 1 ? 'peça' : 'peças'}',
        error: c.errors.value[ProductField.variants],
        child: VariantGridEditor(
          colors: c.colors.toList(),
          sizes: c.sizes.toList(),
          sizePresets: ProductFormController.sizePresets,
          // Lê o mapa aqui para o Obx reconstruir quando o estoque mudar.
          cellOf: (color, size) =>
              c.cells[ProductDraft.cellKey(color, size)] ?? const DraftCell(),
          onAddColor: c.addColor,
          onEditColor: (color) => unawaited(_editColor(context, color)),
          onAddSize: c.addSize,
          onRemoveSize: c.removeSize,
          onStockChanged: c.setStock,
        ),
      ),
    );

    final actions = Obx(
      () => Wrap(
        alignment: WrapAlignment.end,
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          AppButton(
            label: 'Cancelar',
            variant: AppButtonVariant.text,
            onPressed: () =>
                unawaited(Get.offAllNamed<void>(AppRoutes.adminProducts)),
          ),
          AppButton(
            label: 'Salvar peça',
            icon: Icons.check,
            isLoading: c.isSaving.value,
            onPressed: () => unawaited(_save(context)),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(controller: c),
        const SizedBox(height: AppSpacing.md),
        if (r.isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    photos,
                    const SizedBox(height: AppSpacing.md),
                    info,
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: variants),
            ],
          )
        else ...[
          photos,
          const SizedBox(height: AppSpacing.md),
          info,
          const SizedBox(height: AppSpacing.md),
          variants,
        ],
        const SizedBox(height: AppSpacing.lg),
        actions,
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller});

  final ProductFormController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final slug = controller.slug;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        IconButton(
          tooltip: 'Voltar para a lista',
          onPressed: () =>
              unawaited(Get.offAllNamed<void>(AppRoutes.adminProducts)),
          icon: const Icon(Icons.arrow_back),
        ),
        Semantics(
          header: true,
          child: Text(
            controller.isNew ? 'Nova peça' : 'Editar peça',
            style: textTheme.headlineSmall,
          ),
        ),
        if (slug != null)
          TextButton.icon(
            onPressed: () =>
                unawaited(Get.toNamed<void>(AppRoutes.productPath(slug))),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Ver na loja'),
          ),
      ],
    );
  }
}

class _PriceField extends StatelessWidget {
  const _PriceField({required this.controller, required this.errors});

  final ProductFormController controller;
  final Map<ProductField, String> errors;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller.price,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9.,]'))],
    onChanged: (_) => controller.clearError(ProductField.price),
    decoration: InputDecoration(
      labelText: 'Preço',
      prefixText: r'R$ ',
      hintText: '129,90',
      errorText: errors[ProductField.price],
    ),
  );
}

class _CompareAtField extends StatelessWidget {
  const _CompareAtField({required this.controller, required this.errors});

  final ProductFormController controller;
  final Map<ProductField, String> errors;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller.compareAtPrice,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9.,]'))],
    onChanged: (_) => controller.clearError(ProductField.compareAtPrice),
    decoration: InputDecoration(
      labelText: 'Preço "de" (opcional)',
      prefixText: r'R$ ',
      helperText: 'Aparece riscado (promoção)',
      errorText: errors[ProductField.compareAtPrice],
    ),
  );
}

class _CategoryField extends StatelessWidget {
  const _CategoryField({required this.controller});

  final ProductFormController controller;

  Future<void> _create(BuildContext context) async {
    final failure = await showDialog<Failure?>(
      context: context,
      builder: (_) => _NewCategoryDialog(controller: controller),
    );
    if (failure != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failure.message),
          persist: false,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Obx(() {
    final options = controller.categoriesForGender;
    final selected = controller.categoryId.value;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DropdownButtonFormField<String?>(
            key: ValueKey('category-${controller.gender.value}-$selected'),
            initialValue: options.any((o) => o.id == selected)
                ? selected
                : null,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Categoria'),
            items: [
              const DropdownMenuItem<String?>(child: Text('Sem categoria')),
              for (final category in options)
                DropdownMenuItem<String?>(
                  value: category.id,
                  child: Text(
                    category.gender == Gender.unissex &&
                            controller.gender.value != Gender.unissex
                        ? '${category.name} (unissex)'
                        : category.name,
                  ),
                ),
            ],
            onChanged: (value) => controller.categoryId.value = value,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: IconButton.filledTonal(
            // Tonal no damasco da marca (o padrão seria o azul do Masculino).
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            tooltip: 'Nova categoria',
            onPressed: () => unawaited(_create(context)),
            icon: const Icon(Icons.add),
          ),
        ),
      ],
    );
  });
}

class _NewCategoryDialog extends StatefulWidget {
  const _NewCategoryDialog({required this.controller});

  final ProductFormController controller;

  @override
  State<_NewCategoryDialog> createState() => _NewCategoryDialogState();
}

class _NewCategoryDialogState extends State<_NewCategoryDialog> {
  final _name = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() => _saving = true);
    final failure = await widget.controller.createCategory(_name.text);
    if (!mounted) return;
    Navigator.of(context).pop(failure);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Nova categoria'),
    content: TextField(
      controller: _name,
      autofocus: true,
      maxLength: 60,
      textCapitalization: TextCapitalization.sentences,
      onSubmitted: (_) => unawaited(_submit()),
      decoration: InputDecoration(
        labelText: 'Nome',
        hintText: 'Ex.: Saias',
        helperText: 'Seção: ${widget.controller.gender.value.label}',
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: _saving ? null : () => unawaited(_submit()),
        child: const Text('Criar'),
      ),
    ],
  );
}
