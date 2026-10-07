import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:joyjoy/app/routes/app_routes.dart';
import 'package:joyjoy/app/widgets/app_theme_toggle.dart';
import 'package:joyjoy/core/responsive/app_responsive.dart';
import 'package:joyjoy/core/responsive/responsive_page.dart';
import 'package:joyjoy/core/theme/app_spacing.dart';
import 'package:joyjoy/core/widgets/app_header.dart';
import 'package:joyjoy/core/widgets/feedback_states.dart';
import 'package:joyjoy/features/admin/auth/presentation/controllers/auth_controller.dart';

/// Item do menu do admin. `route == null` = ainda não disponível.
class AdminMenuItem {
  const AdminMenuItem(this.label, this.icon, {this.route, this.soon});

  final String label;
  final IconData icon;
  final String? route;

  /// Texto "em breve" com o PR em que chega.
  final String? soon;
}

/// Casca do admin: confirma `is_admin()` no servidor antes de mostrar o
/// conteúdo; menu lateral (tablet/desktop) ou gaveta (celular).
class AdminShell extends StatefulWidget {
  const AdminShell({required this.selected, required this.child, super.key});

  static const menu = [
    AdminMenuItem('Início', Icons.dashboard_outlined, route: AppRoutes.admin),
    AdminMenuItem('Pedidos', Icons.receipt_long_outlined, soon: 'Em breve'),
    AdminMenuItem('Produtos', Icons.checkroom_outlined, soon: 'Em breve'),
    AdminMenuItem('Configurações', Icons.tune_outlined, soon: 'Em breve'),
  ];

  final int selected;
  final Widget child;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  final AuthController _auth = Get.find<AuthController>();
  late Future<bool> _check = _auth.ensureAdmin();

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: _check,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.data != true) {
        // Sessão expirada ou sem permissão → volta ao login.
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => unawaited(
            Get.offAllNamed<void>(
              AppRoutes.adminLoginPath(next: Get.currentRoute),
            ),
          ),
        );
        return const Scaffold(body: SizedBox.shrink());
      }
      return _Layout(
        selected: widget.selected,
        auth: _auth,
        child: widget.child,
      );
    },
  );

  @override
  void didUpdateWidget(covariant AdminShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_auth.isAdmin) _check = _auth.ensureAdmin();
  }
}

class _Layout extends StatelessWidget {
  const _Layout({
    required this.selected,
    required this.auth,
    required this.child,
  });

  final int selected;
  final AuthController auth;
  final Widget child;

  Future<void> _signOut() async {
    await auth.signOut();
    unawaited(Get.offAllNamed<void>(AppRoutes.landing));
  }

  void _go(AdminMenuItem item) {
    if (item.route != null) unawaited(Get.offAllNamed<void>(item.route!));
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final actions = [
      IconButton(
        tooltip: 'Ver a loja',
        onPressed: () => unawaited(Get.toNamed<void>(AppRoutes.landing)),
        icon: const Icon(Icons.storefront_outlined),
      ),
      const AppThemeToggle(),
      IconButton(
        tooltip: 'Sair',
        onPressed: () => unawaited(_signOut()),
        icon: const Icon(Icons.logout),
      ),
    ];

    if (r.isMobile) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Painel'),
          actions: actions,
        ),
        drawer: Drawer(
          child: SafeArea(
            child: ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: AppHeaderTitle(),
                ),
                for (final (i, item) in AdminShell.menu.indexed)
                  ListTile(
                    leading: Icon(item.icon),
                    title: Text(item.label),
                    subtitle: item.soon == null ? null : Text(item.soon!),
                    selected: i == selected,
                    enabled: item.route != null,
                    onTap: () => _go(item),
                  ),
              ],
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(r.pagePadding),
            child: child,
          ),
        ),
      );
    }

    return ResponsivePage(
      appBar: AppHeader(title: 'Painel JOYJOY', actions: actions),
      scrollable: false,
      padding: EdgeInsets.zero,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NavigationRail(
            selectedIndex: selected,
            labelType: NavigationRailLabelType.all,
            onDestinationSelected: (i) => _go(AdminShell.menu[i]),
            destinations: [
              for (final item in AdminShell.menu)
                NavigationRailDestination(
                  icon: Icon(item.icon),
                  label: Text(item.label),
                  disabled: item.route == null,
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(r.pagePadding),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Título "Painel JOYJOY" na gaveta do celular.
class AppHeaderTitle extends StatelessWidget {
  const AppHeaderTitle({super.key});

  @override
  Widget build(BuildContext context) =>
      Text('Painel JOYJOY', style: Theme.of(context).textTheme.titleLarge);
}

/// Usado quando uma área do admin ainda não existe.
class AdminComingSoon extends StatelessWidget {
  const AdminComingSoon({super.key});

  @override
  Widget build(BuildContext context) => const EmptyState(
    icon: Icons.construction_outlined,
    title: 'Em breve',
    message: 'Esta área chega nas próximas versões.',
  );
}
