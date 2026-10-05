import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:joyjoy/app/routes/app_routes.dart';
import 'package:joyjoy/core/widgets/cart_badge_button.dart';
import 'package:joyjoy/features/cart/presentation/controllers/cart_controller.dart';

/// [CartBadgeButton] ligado ao `CartController` global. Use nas ações do header.
class AppCartButton extends StatelessWidget {
  const AppCartButton({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Get.find<CartController>();
    return Obx(
      () => CartBadgeButton(
        count: cart.totalQuantity,
        onPressed: () => unawaited(Get.toNamed<void>(AppRoutes.cart)),
      ),
    );
  }
}
