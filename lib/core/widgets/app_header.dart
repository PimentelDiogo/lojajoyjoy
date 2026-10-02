import 'package:flutter/material.dart';
import 'package:ondas_que_faltam/core/config/app_constants.dart';
import 'package:ondas_que_faltam/core/responsive/app_responsive.dart';
import 'package:ondas_que_faltam/core/theme/app_spacing.dart';
import 'package:ondas_que_faltam/core/widgets/app_logo.dart';

/// Header da loja: logo + nome + ações (busca, carrinho, tema).
///
/// [accentColor] pinta uma faixa fina embaixo — rosa no Feminino,
/// azul no Masculino.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    this.title = AppConstants.storeName,
    this.actions = const [],
    this.leading,
    this.accentColor,
    this.showLogo = true,
    super.key,
  });

  static const double _accentHeight = 3;

  final String title;
  final List<Widget> actions;
  final Widget? leading;
  final Color? accentColor;
  final bool showLogo;

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight + _accentHeight);

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return AppBar(
      leading: leading,
      titleSpacing: leading == null ? r.pagePadding : null,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLogo) ...[
            const AppLogo(),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Semantics(
              header: true,
              child: Text(title, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
      actions: [
        ...actions,
        SizedBox(width: r.pagePadding / 2),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(_accentHeight),
        child: Container(
          height: _accentHeight,
          color: accentColor ?? Colors.transparent,
        ),
      ),
    );
  }
}
