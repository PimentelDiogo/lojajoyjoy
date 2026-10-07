import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

/// Registra um controller enquanto a tela existe e o descarta ao sair.
///
/// Para telas montadas fora de um `Binding` (ex.: área admin `deferred`):
/// rebuilds não recriam o controller (o formulário não perde o que foi
/// digitado) e abrir a tela de novo começa do zero.
class ControllerScope<T extends GetxController> extends StatefulWidget {
  const ControllerScope({
    required this.create,
    required this.child,
    this.tag,
    super.key,
  });

  final T Function() create;
  final String? tag;
  final Widget child;

  @override
  State<ControllerScope<T>> createState() => _ControllerScopeState<T>();
}

class _ControllerScopeState<T extends GetxController>
    extends State<ControllerScope<T>> {
  late final T _controller;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<T>(tag: widget.tag)) {
      GetInstance().delete<T>(tag: widget.tag, force: true);
    }
    _controller = Get.put<T>(widget.create(), tag: widget.tag);
  }

  @override
  void dispose() {
    // Numa troca de rota a tela nova pode já ter registrado o mesmo tipo/tag.
    if (Get.isRegistered<T>(tag: widget.tag) &&
        identical(Get.find<T>(tag: widget.tag), _controller)) {
      GetInstance().delete<T>(tag: widget.tag, force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
