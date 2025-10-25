import 'package:get/get.dart';
import 'package:flutter/material.dart';

/// Centralized helpers used across the app.
class AppHelpers {
  /// Convert raw exceptions / Dio / socket errors into friendly messages.
  static String humanizeError(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('socketexception')) return 'Network error. Please check your connection.';
    if (s.contains('401') || s.contains('unauthorized')) return 'Invalid email or password.';
    if (s.contains('timeout')) return 'Request timed out. Try again.';
    return e.toString().replaceFirst('Exception: ', '');
  }

  /// Show success snackbar (non-intrusive).
  static void okSnack(String title, String message) {
    if (!Get.isSnackbarOpen) {
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.08),
        colorText: Colors.green.shade800,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 2),
      );
    }
  }

  /// Show error snackbar.
  static void errSnack(String title, String message) {
    if (!Get.isSnackbarOpen) {
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.08),
        colorText: Colors.red.shade800,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Parse role CSV like "merchant,user" -> ['merchant','user'] (lowercased & trimmed).
  static List<String> parseRoles(String? roleCsv) {
    if (roleCsv == null || roleCsv.isEmpty) return const [];
    return roleCsv
        .split(',')
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
  }

  /// Check if a CSV role string contains a target role.
  static bool hasRole(String roleCsv, String role) {
    return parseRoles(roleCsv).contains(role.toLowerCase());
  }
}
