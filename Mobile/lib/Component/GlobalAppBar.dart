// lib/Component/GlobalAppBar.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Role/RoleController.dart';

class GlobalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  /// 👥 商家视图图标（默认：people）
  final IconData activeIcon;

  /// 🛒 个人视图图标（默认：shopping_cart）
  final IconData inactiveIcon;

  /// 仅切换文字/图标颜色；字号/字重沿用主题（默认 false）
  /// false -> 使用 appBarTheme.foregroundColor / onPrimary
  /// true  -> 使用 colorScheme.onSurface（更强对比，适合透明或自定义背景）
  final bool altTextColor;

  const GlobalAppBar({
    super.key,
    required this.title,
    this.activeIcon = Icons.people,
    this.inactiveIcon = Icons.shopping_cart,
    this.altTextColor = false,
  });

  @override
  Widget build(BuildContext context) {
    final roleC = Get.find<RoleController>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // 基于主题的文本样式（字号/字重与主题一致，只在此处切颜色）
    final titleStyle = (theme.appBarTheme.titleTextStyle ??
            const TextStyle(fontSize: 20, fontWeight: FontWeight.w600))
        .copyWith(
          color: altTextColor
              ? cs.onSurface
              : (theme.appBarTheme.foregroundColor ?? cs.onPrimary),
        );

    final subBase = (theme.appBarTheme.toolbarTextStyle ??
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w400))
        .copyWith(
          color: altTextColor
              ? cs.onSurface.withOpacity(.75)
              : (theme.appBarTheme.foregroundColor ?? cs.onPrimary)
                  .withOpacity(.75),
        );

    final iconColor = altTextColor
        ? cs.onSurface
        : (theme.appBarTheme.foregroundColor ?? cs.onPrimary);

    return Obx(() {
      final bool canSwitch = roleC.hasMerchant.value;     // 账号是否具备商家能力
      final bool viewingMerchant = roleC.isMerchantView;  // 当前查看的钱包

      return AppBar(
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? cs.primary, // 跟随主题
        elevation: theme.appBarTheme.elevation ?? 2,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题（居中排版）
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [Text(title, style: titleStyle)],
            ),
            // 只有商家账号显示副标题：当前查看的钱包视图
            if (canSwitch)
              Text(
                viewingMerchant
                    ? 'Wallet View: Merchant (Business)'
                    : 'Wallet View: User (Personal)',
                style: subBase,
              ),
          ],
        ),
        actions: [
          // 只有商家账号可切换视图
          if (canSwitch)
            IconButton(
              icon: Icon(
                viewingMerchant ? activeIcon : inactiveIcon,
                color: iconColor,
              ),
              tooltip: viewingMerchant
                  ? 'Switch to Personal Wallet'
                  : 'Switch to Merchant Wallet',
              onPressed: roleC.toggleRole, // 一键切换
            ),
        ],
      );
    });
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
