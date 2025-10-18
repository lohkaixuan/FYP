import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:mobile/Role/RoleController.dart';

class RoleGate extends GetView<RoleController> {
  final Widget child;
  final Widget? fallback;
  const RoleGate({super.key, required this.child, this.fallback});

  @override
  Widget build(BuildContext context) =>
      Obx(() => controller.isMerchant ? child : (fallback ?? const SizedBox.shrink()));
}
