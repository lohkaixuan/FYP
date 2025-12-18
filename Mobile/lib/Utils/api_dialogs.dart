import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ApiDialogs {
  // ✅ Way 1 (manual switch):
  // false = DEV (show real server/Dio details)
  // true  = PROD (user-friendly only)
  static const bool isProd = true; // 👈 change this only

  static void showSuccess(
    String title,
    String message, {
    VoidCallback? onConfirm,
  }) {
    if (Get.isDialogOpen == true) return;
    Get.defaultDialog(
      title: title,
      middleText: message,
      textConfirm: 'OK',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        onConfirm?.call();
      },
      barrierDismissible: true,
    );
  }

  /// ✅ If caller provides fallbackTitle -> use it
  /// ✅ If caller provides a String error -> treat as user message
  /// ✅ PROD: never show DioException long text / raw stack messages
  static void showError(
    dynamic error, {
    String? fallbackTitle,
    String? fallbackMessage,
  }) {
    // Default dialog title/message
    String title = (fallbackTitle?.trim().isNotEmpty == true)
        ? fallbackTitle!.trim()
        : 'Request Failed';

    String message = (fallbackMessage?.trim().isNotEmpty == true)
        ? fallbackMessage!.trim()
        : 'Something went wrong. Please try again.';

    int? code;

    // String error (you manually pass message)
    if (error is String) {
      message = error.trim().isNotEmpty ? error.trim() : message;
      _openDialog(title, message);
      return;
    }

    // Dio exception
    if (error is dio.DioException) {
      code = error.response?.statusCode;
      final data = error.response?.data;

      if (!isProd) {
        // DEV: show real message from server if possible
        if (data is Map<String, dynamic>) {
          message = _extractMessage(data) ?? message;
        } else if (data is String && data.trim().isNotEmpty) {
          message = data;
        } else if ((error.message ?? '').trim().isNotEmpty) {
          message = error.message!.trim();
        } else {
          message = error.toString();
        }
      } else {
        // PROD: user-friendly only
        message = _userFriendlyMessage(code);
      }

      // Title: if you passed fallbackTitle, keep it.
      // Otherwise use status-title.
      if (fallbackTitle == null || fallbackTitle.trim().isEmpty) {
        title = _titleForCode(code) ?? title;
      }

      _openDialog(title, message);
      return;
    }

    // Dio Response without exception
    if (error is dio.Response) {
      code = error.statusCode;
      final data = error.data;

      if (!isProd) {
        if (data is Map<String, dynamic>) {
          message = _extractMessage(data) ?? message;
        } else if (data is String && data.trim().isNotEmpty) {
          message = data;
        }
      } else {
        message = _userFriendlyMessage(code);
      }

      if (fallbackTitle == null || fallbackTitle.trim().isEmpty) {
        title = _titleForCode(code) ?? title;
      }

      _openDialog(title, message);
      return;
    }

    // Other unknown errors
    if (!isProd && error != null) {
      message = error.toString();
    }

    _openDialog(title, message);
  }

  /// Returns a user-friendly error string without opening a dialog.
  static String formatErrorMessage(
    dynamic error, {
    String? fallbackMessage,
  }) {
    String message = (fallbackMessage?.trim().isNotEmpty == true)
        ? fallbackMessage!.trim()
        : 'Something went wrong. Please try again.';
    int? code;

    if (error is String && error.trim().isNotEmpty) {
      return error.trim();
    }

    if (error is dio.DioException) {
      code = error.response?.statusCode;
      final data = error.response?.data;

      if (!isProd) {
        if (data is Map<String, dynamic>) {
          return _extractMessage(data) ?? message;
        } else if (data is String && data.trim().isNotEmpty) {
          return data.trim();
        } else if ((error.message ?? '').trim().isNotEmpty) {
          return error.message!.trim();
        } else {
          return error.toString();
        }
      } else {
        return _userFriendlyMessage(code);
      }
    }

    if (error is dio.Response) {
      code = error.statusCode;
      final data = error.data;

      if (!isProd) {
        if (data is Map<String, dynamic>) {
          return _extractMessage(data) ?? message;
        } else if (data is String && data.trim().isNotEmpty) {
          return data.trim();
        }
      } else {
        return _userFriendlyMessage(code);
      }
    }

    if (!isProd && error != null) {
      return error.toString();
    }

    return message;
  }

  // =============================
  // Internal helpers
  // =============================

  static void _openDialog(String title, String message) {
    if (Get.isDialogOpen == true) return; // ✅ prevents double dialogs
    Get.defaultDialog(
      title: title,
      middleText: message,
      textConfirm: 'OK',
      confirmTextColor: Colors.white,
      onConfirm: () => Get.back(),
      barrierDismissible: true,
    );
  }

  static String? _extractMessage(Map<String, dynamic> data) {
    final keys = ['message', 'error', 'detail', 'msg'];
    for (final k in keys) {
      final v = data[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }

    final errors = data['errors'];
    if (errors is Map) {
      final parts = <String>[];
      errors.forEach((key, value) {
        if (value is List) {
          parts.add('$key: ${value.join(', ')}');
        } else if (value is String) {
          parts.add('$key: $value');
        }
      });
      if (parts.isNotEmpty) return parts.join('\n');
    }
    return null;
  }

  static String _userFriendlyMessage(int? code) {
    switch (code) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Session expired. Please login again.';
      case 403:
        return 'Permission denied.';
      case 404:
        return 'User not found.'; // ✅ your desired message
      case 409:
        return 'Conflict detected. Please try again.';
      case 422:
        return 'Invalid data provided.';
      default:
        if (code != null && code >= 500) {
          return 'Server is busy. Please try again later.';
        }
        return 'Something went wrong. Please try again.';
    }
  }

  static String? _titleForCode(int? code) {
    if (code == null) return null;
    switch (code) {
      case 400:
        return 'Bad Request';
      case 401:
        return 'Unauthorized';
      case 403:
        return 'Forbidden';
      case 404:
        return 'Login Failed';
      case 409:
        return 'Conflict';
      case 422:
        return 'Validation Error';
      default:
        if (code >= 500) return 'Server Error';
        return 'Error';
    }
  }
}
