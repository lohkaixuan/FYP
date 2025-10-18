import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/QR/QRtab.dart';

class QrSlideSwitch extends GetView<QrTabController> {
  const QrSlideSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      return CupertinoSlidingSegmentedControl<QrTab>(
        groupValue: controller.tab.value,
        thumbColor: theme.colorScheme.primary,       // 滑块颜色
        backgroundColor: theme.colorScheme.primary.withOpacity(0.25),
        children: const {
          QrTab.show: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text('Show QR'),
          ),
          QrTab.scan: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text('Scanner'),
          ),
        },
        onValueChanged: controller.setTab,
      );
    });
  }
}
