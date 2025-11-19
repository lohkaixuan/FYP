import 'package:flutter/material.dart';

class UserActionButton extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  final double width;
  final double height;
  final VoidCallback onPressed;
  final Color? borderColor;
  final double borderRadius;

  const UserActionButton({
    super.key,
    required this.text,
    required this.color,
    required this.textColor,
    required this.width,
    required this.height,
    required this.onPressed,
    this.borderColor,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: borderColor != null
                ? BorderSide(color: borderColor!)
                : BorderSide.none,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}