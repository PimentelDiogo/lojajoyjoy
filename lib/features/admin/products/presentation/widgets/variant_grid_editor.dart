import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:joyjoy/core/theme/app_spacing.dart';
import 'package:joyjoy/core/utils/color_hex.dart';
import 'package:joyjoy/features/admin/products/domain/entities/product_draft.dart';

/// Cores sugeridas (nome que a cliente vê + amostra).
const colorPresets = <(String, String)>[
  ('Preto', '#1F1F1F'),
  ('Branco', '#FFFFFF'),
  ('Off-white', '#F5F0E6'),
  ('Bege', '#D8C3A5'),
  ('Marrom', '#7B5236'),
  ('Terracota', '#B04E1C'),
  ('Cinza', '#9E9E9E'),
  ('Azul-marinho', '#1F2A44'),
  ('Azul', '#6C9BD2'),
  ('Verde', '#6FA07A'),
  ('Verde-oliva', '#6B6B3A'),
  ('Amarelo', '#F2D06B'),
  ('Laranja', '#E0662A'),
  ('Vermelho', '#C0392B'),
  ('Vinho', '#6D1F2F'),
  ('Rosa', '#F4A7B9'),
  ('Lilás', '#C3A6D8'),
  ('Estampado', ''),
];

/// Resultado do diálogo de cor.
sealed class ColorDialogResult {
  const ColorDialogResult();
}

final class ColorSaved extends ColorDialogResult {
  const ColorSaved(this.name, this.hex);
  final String name;
  final String? hex;
}

final class ColorRemoved extends ColorDialogResult {
  const ColorRemoved();
}

/// Cores, tamanhos e a grade de estoque (vazio = combinação não existe).
class VariantGridEditor extends StatelessWidget {
  const VariantGridEditor({
    required this.colors,
    required this.sizes,
    required this.sizePresets,
    required this.cellOf,
    required this.onAddColor,
    required this.onEditColor,
    required this.onAddSize,
    required this.onRemoveSize,
    required this.onStockChanged,
    super.key,
  });

  final List<DraftColor> colors;
  final List<String> sizes;
  final List<List<String>> sizePresets;
  final DraftCell Function(String colorKey, String size) cellOf;

  /// Devolvem a mensagem de erro (ou null quando deu certo).
  final String? Function(String name, String? hex) onAddColor;
  final void Function(DraftColor color) onEditColor;
  final String? Function(String size) onAddSize;
  final ValueChanged<String> onRemoveSize;
  final void Function(String colorKey, String size, String text) onStockChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Cores', style: textTheme.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final color in colors)
              InputChip(
                avatar: _Swatch(hex: color.hex),
                label: Text(color.name),
                tooltip: 'Editar cor ${color.name}',
                onPressed: () => onEditColor(color),
              ),
            ActionChip(
              avatar: const Icon(Icons.add, size: 18),
              label: const Text('Adicionar cor'),
              onPressed: () =>
                  unawaited(showColorDialog(context, validate: onAddColor)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Tamanhos', style: textTheme.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final size in sizes)
              Chip(
                label: Text(size),
                deleteButtonTooltipMessage: 'Remover tamanho $size',
                onDeleted: () => onRemoveSize(size),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        _SizeAdder(
          sizes: sizes,
          presets: sizePresets,
          onAddSize: onAddSize,
        ),
        if (colors.isNotEmpty && sizes.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('Estoque', style: textTheme.titleSmall),
          Text(
            'Quantas peças de cada combinação. Deixe vazio se não existir; '
            '0 = esgotado (aparece riscado na loja).',
            style: textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final color in colors)
            _StockRow(
              key: ValueKey('stock-${color.key}'),
              color: color,
              sizes: sizes,
              cellOf: cellOf,
              onChanged: onStockChanged,
            ),
        ],
      ],
    );
  }
}

/// Diálogo para criar/editar uma cor. [validate] devolve o erro ou null
/// (e já aplica a mudança); o diálogo só fecha quando der certo.
Future<ColorDialogResult?> showColorDialog(
  BuildContext context, {
  required String? Function(String name, String? hex) validate,
  DraftColor? initial,
}) => showDialog<ColorDialogResult>(
  context: context,
  builder: (_) => _ColorDialog(initial: initial, validate: validate),
);

class _ColorDialog extends StatefulWidget {
  const _ColorDialog({required this.validate, this.initial});

  final DraftColor? initial;
  final String? Function(String name, String? hex) validate;

  @override
  State<_ColorDialog> createState() => _ColorDialogState();
}

class _ColorDialogState extends State<_ColorDialog> {
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late String? _hex = widget.initial?.hex;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final error = widget.validate(_name.text, _hex);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(ColorSaved(_name.text.trim(), _hex));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(widget.initial == null ? 'Nova cor' : 'Editar cor'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _name,
                autofocus: true,
                maxLength: 40,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Nome da cor',
                  helperText: 'Como a cliente vai ver (ex.: Rosa chá)',
                  errorText: _error,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('Amostra', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final (name, hex) in colorPresets)
                    Tooltip(
                      message: name,
                      child: InkResponse(
                        onTap: () => setState(() {
                          _hex = hex.isEmpty ? null : hex;
                          if (_name.text.trim().isEmpty) _name.text = name;
                        }),
                        radius: 22,
                        child: Semantics(
                          button: true,
                          selected: (hex.isEmpty ? null : hex) == _hex,
                          label: 'Amostra $name',
                          excludeSemantics: true,
                          child: Container(
                            width: 40,
                            height: 40,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: (hex.isEmpty ? null : hex) == _hex
                                    ? scheme.primary
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                            child: _Swatch(hex: hex.isEmpty ? null : hex),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (widget.initial != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop(const ColorRemoved()),
            style: TextButton.styleFrom(foregroundColor: scheme.error),
            child: const Text('Remover cor'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Salvar cor')),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({this.hex});

  final String? hex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = colorFromHex(hex);
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color ?? scheme.surfaceContainerHigh,
        border: Border.all(color: scheme.outline),
      ),
      child: color == null
          ? Icon(Icons.texture, size: 14, color: scheme.onSurfaceVariant)
          : null,
    );
  }
}

class _SizeAdder extends StatefulWidget {
  const _SizeAdder({
    required this.sizes,
    required this.presets,
    required this.onAddSize,
  });

  final List<String> sizes;
  final List<List<String>> presets;
  final String? Function(String size) onAddSize;

  @override
  State<_SizeAdder> createState() => _SizeAdderState();
}

class _SizeAdderState extends State<_SizeAdder> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add(String size) {
    final error = widget.onAddSize(size);
    setState(() => _error = error);
    if (error == null) _controller.clear();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          for (final group in widget.presets)
            for (final size in group)
              if (!widget.sizes.contains(size))
                ActionChip(
                  label: Text('+ $size'),
                  tooltip: 'Adicionar tamanho $size',
                  onPressed: () => _add(size),
                ),
        ],
      ),
      const SizedBox(height: AppSpacing.xs),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              maxLength: 10,
              textCapitalization: TextCapitalization.characters,
              onSubmitted: _add,
              decoration: InputDecoration(
                labelText: 'Outro tamanho',
                hintText: 'Ex.: 48, XG, 2 anos',
                errorText: _error,
                counterText: '',
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: OutlinedButton(
              onPressed: () => _add(_controller.text),
              child: const Text('Adicionar'),
            ),
          ),
        ],
      ),
    ],
  );
}

class _StockRow extends StatelessWidget {
  const _StockRow({
    required this.color,
    required this.sizes,
    required this.cellOf,
    required this.onChanged,
    super.key,
  });

  final DraftColor color;
  final List<String> sizes;
  final DraftCell Function(String colorKey, String size) cellOf;
  final void Function(String colorKey, String size, String text) onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Swatch(hex: color.hex),
              const SizedBox(width: AppSpacing.xs),
              Flexible(child: Text(color.name, style: textTheme.labelLarge)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final size in sizes)
                SizedBox(
                  width: 76,
                  child: Semantics(
                    label: 'Estoque ${color.name}, tamanho $size',
                    child: TextFormField(
                      key: ValueKey('${color.key}|$size'),
                      initialValue:
                          cellOf(color.key, size).stock?.toString() ?? '',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(5),
                      ],
                      textAlign: TextAlign.center,
                      onChanged: (text) => onChanged(color.key, size, text),
                      decoration: InputDecoration(
                        labelText: size,
                        hintText: '—',
                        isDense: true,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
