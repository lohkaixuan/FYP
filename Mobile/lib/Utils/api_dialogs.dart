import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ApiDialogs {
  static void showSuccess(String title, String message) {
    if (Get.isDialogOpen != true) {
      Get.defaultDialog(
        title: title,
        middleText: message,
        textConfirm: 'OK',
        confirmTextColor: Colors.white,
        onConfirm: () => Get.back(),
        barrierDismissible: true,
      );
    }
  }

  static void showError(dynamic error, {String? fallbackTitle}) {
    String title = fallbackTitle ?? 'Request Failed';
    String message = 'Something went wrong. Please try again.';
    int? code;

    if (error is dio.DioException) {
      code = error.response?.statusCode;
      final data = error.response?.data;

      // Prefer detailed message from server
      if (data is Map<String, dynamic>) {
        message = _extractMessage(data) ?? message;
      } else if (data is String && data.trim().isNotEmpty) {
        message = data;
      } else if (error.message != null && error.message!.isNotEmpty) {
        message = error.message!;
      }

      title = _titleForCode(code) ?? title;
      if (code != null) {
        title = '$title ($code)';
      }
    } else if (error is dio.Response) {
      // Generic Dio Response without exception
      code = error.statusCode;
      final data = error.data;
      if (data is Map<String, dynamic>) {
        message = _extractMessage(data) ?? message;
      } else if (data is String && data.trim().isNotEmpty) {
        message = data;
      }
      title = _titleForCode(code) ?? title;
      if (code != null) title = '$title ($code)';
    } else if (error is String) {
      message = error;
    } else if (error != null) {
      message = error.toString();
    }

    if (Get.isDialogOpen != true) {
      Get.defaultDialog(
        title: title,
        middleText: message,
        textConfirm: 'OK',
        confirmTextColor: Colors.white,
        onConfirm: () => Get.back(),
        barrierDismissible: true,
      );
    }
  }

  static String? _extractMessage(Map<String, dynamic> data) {
    final keys = ['message', 'error', 'detail', 'msg'];
    for (final k in keys) {
      final v = data[k];
      if (v is String && v.trim().isNotEmpty) return v;
    }
    // Validation errors structure: { errors: { field: [..] } }
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

  static String? _titleForCode(int? code) {
    if (code == null) return null;
    if (code >= 200 && code < 300) return 'Success';
    switch (code) {
      case 400:
        return 'Bad Request';
      case 401:
        return 'Unauthorized';
      case 403:
        return 'Forbidden';
      case 404:
        return 'Not Found';
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
