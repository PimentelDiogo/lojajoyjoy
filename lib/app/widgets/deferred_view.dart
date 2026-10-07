import 'package:flutter/material.dart';
import 'package:joyjoy/core/widgets/feedback_states.dart';

/// Carrega uma biblioteca `deferred` (ex.: a área admin) antes de mostrar a
/// tela — o cliente da loja não baixa esse código (ADR-0001).
class DeferredView extends StatefulWidget {
  const DeferredView({required this.load, required this.builder, super.key});

  final Future<void> Function() load;
  final WidgetBuilder builder;

  @override
  State<DeferredView> createState() => _DeferredViewState();
}

class _DeferredViewState extends State<DeferredView> {
  late Future<void> _future = widget.load();

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Scaffold(
          body: ErrorState(
            message: 'Não foi possível abrir esta área. Verifique a conexão.',
            onRetry: () => setState(() => _future = widget.load()),
          ),
        );
      }
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return widget.builder(context);
    },
  );
}
