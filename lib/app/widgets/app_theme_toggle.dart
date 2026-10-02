import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ondas_que_faltam/core/theme/theme_controller.dart';
import 'package:ondas_que_faltam/core/widgets/theme_toggle.dart';

/// [ThemeToggle] ligado ao `ThemeController` global. Use nas ações do header.
class AppThemeToggle extends StatelessWidget {
  const AppThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ThemeController>();
    return Obx(
      () =>
          ThemeToggle(mode: controller.mode.value, onPressed: controller.cycle),
    );
  }
}
