// ==================================================
// Program Name   : button.dart
// Purpose        : Reusable admin button component
// Developer      : Mr. Loh Kai Xuan 
// Student ID     : TP074510 
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026 
// ==================================================
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
            fontSize: 11.6,
          ),
        ),
      ),
    );
  }
}

class RegisterProviderButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const RegisterProviderButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(8),
        ),
        child: Text(
          text,
          style: GoogleFonts.interTight(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class ViewDocumentButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ViewDocumentButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white, // Secondary Background
          elevation: 0,
          padding: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: Colors.grey.shade300, // Alternate color
              width: 1,
            ),
          ),
        ),
        icon: const Icon(
          Icons.visibility_outlined,
          size: 20,
          color: Colors.black87, // Primary Text color
        ),
        label: Text(
          'View Document',
          style: GoogleFonts.interTight(
            color: Colors.black87, // Primary Text color
            fontSize: 14, // titleSmall approximate
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class DocumentDecisionRow extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const DocumentDecisionRow({
    super.key,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        // Accept Button
        Expanded(
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF249689), // Success Color (Green)
                elevation: 0,
                padding: const EdgeInsets.all(8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(
                Icons.check_circle_outline,
                size: 20,
                color: Colors.white,
              ),
              label: Text(
                'Accept',
                style: GoogleFonts.interTight(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12), // Spacing between buttons
        // Reject Button
        Expanded(
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: onReject,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5963), // Error Color (Red)
                elevation: 0,
                padding: const EdgeInsets.all(8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(
                Icons.cancel_outlined,
                size: 20,
                color: Colors.white,
              ),
              label: Text(
                'Reject',
                style: GoogleFonts.interTight(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
