import 'package:flutter/material.dart';
import 'package:joyjoy/core/responsive/app_responsive.dart';
import 'package:joyjoy/core/theme/app_colors.dart';
import 'package:joyjoy/core/widgets/app_wordmark.dart';

/// Header da loja: nome da marca (ou [title]) + ações (busca, carrinho, tema).
///
/// Sem [title], mostra o [AppWordmark] "JOYJOY". A faixa fina embaixo usa
/// o laranja do logo; seções passam [accentColor] (rosa no Feminino, azul
/// no Masculino).
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    this.title,
    this.actions = const [],
    this.leading,
    this.accentColor,
    super.key,
  });

  static const double _accentHeight = 3;

  final String? title;
  final List<Widget> actions;
  final Widget? leading;
  final Color? accentColor;

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight + _accentHeight);

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return AppBar(
      leading: leading,
      titleSpacing: leading == null ? r.pagePadding : null,
      title: title == null
          ? AppWordmark(fontSize: r.value(mobile: 22, desktop: 26))
          : Semantics(
              header: true,
              child: Text(title!, overflow: TextOverflow.ellipsis),
            ),
      actions: [
        ...actions,
        SizedBox(width: r.pagePadding / 2),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(_accentHeight),
        child: Container(
          height: _accentHeight,
          color: accentColor ?? context.appColors.brand,
        ),
      ),
    );
  }
}
