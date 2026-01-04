// ==================================================
// Program Name   : GradientWidgets.dart
// Purpose        : Gradient styling helper widgets
// Developer      : Mr. Loh Kai Xuan 
// Student ID     : TP074510 
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026 
// ==================================================
import 'package:flutter/material.dart';
import 'package:mobile/Component/AppTheme.dart';

class GradientIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Gradient gradient;

  const GradientIcon(
    this.icon, {
    super.key,
    this.size = 24,
    this.gradient = AppTheme.brandGradient,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return gradient.createShader(Rect.fromLTWH(0, 0, size, size));
      },
      blendMode: BlendMode.srcIn,
      child: Icon(icon, size: size, color: Colors.white),
    );
  }
}

class BrandGradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final double height;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool expand;

  const BrandGradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.height = 48,
    this.borderRadius,
    this.padding,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = borderRadius ?? BorderRadius.circular(AppTheme.rMd);
    final enabled = onPressed != null;
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: Opacity(
        opacity: enabled ? 1 : 0.6,
        child: Ink(
          decoration: BoxDecoration(
            gradient: enabled ? AppTheme.brandGradient : null,
            color: enabled ? null : scheme.surfaceVariant,
            borderRadius: radius,
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onPressed,
            child: Container(
              height: height,
              width: expand ? double.infinity : null,
              alignment: Alignment.center,
              padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
              child: DefaultTextStyle.merge(
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
