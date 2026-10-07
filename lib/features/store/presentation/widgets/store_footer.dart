import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:joyjoy/core/config/app_constants.dart';
import 'package:joyjoy/core/responsive/app_responsive.dart';
import 'package:joyjoy/core/responsive/responsive_page.dart';
import 'package:joyjoy/core/services/link_launcher.dart';
import 'package:joyjoy/core/theme/app_spacing.dart';
import 'package:joyjoy/core/utils/phone_format.dart';
import 'package:joyjoy/core/utils/whatsapp_link.dart';
import 'package:joyjoy/core/widgets/app_wordmark.dart';
import 'package:joyjoy/features/store/domain/entities/store_settings.dart';
import 'package:joyjoy/features/store/presentation/controllers/store_controller.dart';

/// Rodapé da loja (referências A15): atendimento, redes, pagamento e retirada.
/// Tudo vem de `store_settings` — a Ana edita no admin.
class StoreFooter extends StatelessWidget {
  const StoreFooter({super.key});

  static const whatsappMessage = 'Olá! Vim pelo site da JOYJOY.';
  static final _instagram = RegExp(r'^[A-Za-z0-9._]{1,30}$');

  /// Links montados aqui (nunca uma URL vinda do banco).
  static Uri? instagramUri(String? handle) =>
      handle != null && _instagram.hasMatch(handle)
      ? Uri.https('www.instagram.com', '/$handle/')
      : null;

  static Uri mapsUri(String address) => Uri.https(
    'www.google.com',
    '/maps/search/',
    {'api': '1', 'query': address},
  );

  @override
  Widget build(BuildContext context) {
    final store = Get.find<StoreController>();
    return Obx(() {
      final settings = store.settings.value;
      if (settings == null) return const SizedBox.shrink();
      return _FooterContent(settings: settings);
    });
  }
}

class _FooterContent extends StatelessWidget {
  const _FooterContent({required this.settings});

  final StoreSettings settings;

  void _open(Uri? uri) {
    if (uri != null) unawaited(Get.find<LinkLauncher>().open(uri));
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final instagram = StoreFooter.instagramUri(settings.instagramHandle);
    final address = settings.pickupAddress?.trim();

    final sections = <Widget>[
      _Section(
        title: 'Atendimento ao cliente',
        children: [
          _LinkRow(
            icon: FontAwesomeIcons.whatsapp,
            label: formatBrazilPhone(settings.whatsappNumber),
            semanticsLabel:
                'WhatsApp ${formatBrazilPhone(settings.whatsappNumber)}',
            onTap: () => _open(
              WhatsAppLink.tryBuild(
                settings.whatsappNumber,
                message: StoreFooter.whatsappMessage,
              ),
            ),
          ),
        ],
      ),
      if (instagram != null)
        _Section(
          title: 'Redes sociais',
          children: [
            _LinkRow(
              icon: FontAwesomeIcons.instagram,
              label: '@${settings.instagramHandle}',
              semanticsLabel: 'Instagram @${settings.instagramHandle}',
              onTap: () => _open(instagram),
            ),
          ],
        ),
      if (settings.paymentMethods.isNotEmpty)
        _Section(
          title: 'Formas de pagamento',
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final method in settings.paymentMethods)
                  if (_payment(method) case (final icon, final label))
                    _PaymentChip(icon: icon, label: label),
              ],
            ),
          ],
        ),
      if (address != null && address.isNotEmpty)
        _Section(
          title: 'Endereço para retirada',
          children: [
            _LinkRow(
              icon: FontAwesomeIcons.locationDot,
              label: address,
              semanticsLabel: 'Endereço para retirada: $address. Abrir no mapa',
              onTap: () => _open(StoreFooter.mapsUri(address)),
            ),
          ],
        ),
    ];

    return Semantics(
      container: true,
      label: 'Rodapé',
      child: Container(
        margin: const EdgeInsets.only(top: AppSpacing.xl),
        padding: EdgeInsets.symmetric(
          vertical: AppSpacing.xl,
          horizontal: r.value<double>(
            mobile: AppSpacing.md,
            desktop: AppSpacing.lg,
          ),
        ),
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveBuilder(
              mobile: (_) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final section in sections) ...[
                    section,
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ],
              ),
              tablet: (_) => Wrap(
                spacing: AppSpacing.xl,
                runSpacing: AppSpacing.lg,
                children: [
                  for (final section in sections)
                    SizedBox(
                      width: r.value<double>(
                        mobile: 0,
                        tablet: 240,
                        desktop: 260,
                      ),
                      child: section,
                    ),
                ],
              ),
            ),
            const Divider(height: AppSpacing.xl),
            Row(
              children: [
                const AppWordmark(fontSize: 18),
                const Spacer(),
                Text(
                  'Recife - PE',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '© ${DateTime.now().year} ${AppConstants.storeName}',
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static (FaIconData, String)? _payment(String method) => switch (method) {
    'pix' => (FontAwesomeIcons.pix, 'Pix'),
    'card' => (FontAwesomeIcons.creditCard, 'Cartão'),
    'cash' => (FontAwesomeIcons.moneyBill, 'Dinheiro'),
    _ => null,
  };
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Semantics(
        header: true,
        child: Text(title, style: Theme.of(context).textTheme.titleSmall),
      ),
      const SizedBox(height: AppSpacing.xs),
      ...children,
    ],
  );
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.label,
    required this.semanticsLabel,
    required this.onTap,
  });

  final FaIconData icon;
  final String label;
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            children: [
              FaIcon(icon, size: 20, color: scheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentChip extends StatelessWidget {
  const _PaymentChip({required this.icon, required this.label});

  final FaIconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}
