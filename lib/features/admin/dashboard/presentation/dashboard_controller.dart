import 'dart:async';

import 'package:get/get.dart';
import 'package:joyjoy/core/state/ui_state.dart';
import 'package:joyjoy/core/usecase/usecase.dart';
import 'package:joyjoy/features/admin/dashboard/domain/dashboard.dart';

class DashboardController extends GetxController {
  DashboardController({required this.getAdminStats});

  final GetAdminStats getAdminStats;

  final Rx<UiState<AdminStats>> state = Rx<UiState<AdminStats>>(const UiIdle());

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  Future<void> load() async {
    state.value = const UiLoading();
    state.value = UiState.fromResult(await getAdminStats(const NoParams()));
  }
}
