// authcontroller.dart
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:mobile/Api/apis.dart';        // ApiService
import 'package:mobile/Api/tokenController.dart';       // TokenController
import 'package:mobile/Api/apimodel.dart';    // LoginRequest, LoginResponse, AppUser (defined in your project)

/// A lightweight GetX controller that handles login/logout and keeps auth state reactive.
/// Usage:
///   final auth = Get.put(AuthController());
///   await auth.login(email: 'a@b.com', password: 'secret');
///   Obx(() => auth.isLoggedIn ? Home() : const LoginScreen());
class AuthController extends GetxController {
  final ApiService _api = ApiService();

  // ===== Reactive state =====
  final isLoading = false.obs;
  final isLoggedIn = false.obs;
  final token = ''.obs;
  final role = ''.obs;
  final user = Rxn<AppUser>();
  final lastError = ''.obs;

  // Optional: persist token via TokenController (GetStorage)
  late final TokenController _tokenCtrl;

  @override
  void onInit() {
    super.onInit();
    // Ensure TokenController exists
    if (Get.isRegistered<TokenController>()) {
      _tokenCtrl = Get.find<TokenController>();
    } else {
      _tokenCtrl = Get.put(TokenController());
    }

    // Seed from storage
    token.value = _tokenCtrl.token.value;
    isLoggedIn.value = token.value.isNotEmpty;

    // Keep local token in sync when TokenController changes
    ever<String>(_tokenCtrl.token, (t) {
      token.value = t;
      isLoggedIn.value = t.isNotEmpty;
    });
  }

  /// Perform login with email/password.
  /// Throws on failure but also updates [lastError] and [isLoading].
  Future<void> login({required String email, required String password}) async {
    if (isLoading.value) return;
    isLoading.value = true;
    lastError.value = '';

    try {
      final dto = LoginRequest(email: email, password: password);
      final LoginResponse res = await _api.login(dto);

      // Save token
      final String tk = res.token ?? '';
      if (tk.isEmpty) {
        throw Exception('Empty token from server');
      }
      await _tokenCtrl.saveToken(tk);

      // Update other fields
      role.value = (res.role ?? '').toLowerCase();
      user.value = res.user;

      // Optional UX: show a tiny toast/snackbar
      _okSnack('Welcome', res.user?.name ?? email);
    } catch (e) {
      lastError.value = _humanizeError(e);
      _errSnack('Login failed', lastError.value);
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Clear local token and ping server logout (best-effort).
  Future<void> logout() async {
    if (isLoading.value) return;
    isLoading.value = true;
    lastError.value = '';

    try {
      // Best-effort server logout (ignore errors)
      await _api.logout().catchError((_) {});
    } finally {
      await _tokenCtrl.clearToken();
      role.value = '';
      user.value = null;
      isLoggedIn.value = false;
      isLoading.value = false;
      _okSnack('Logged out', 'See you soon!');
    }
  }

  // ===== Helpers =====
  String _humanizeError(Object e) {
    // Basic normalization for Dio/HTTP errors vs generic exceptions
    final s = e.toString();
    if (s.contains('SocketException')) return 'Network error. Please check your connection.';
    if (s.contains('401') || s.contains('Unauthorized')) return 'Invalid email or password.';
    if (s.contains('timeout')) return 'Request timed out. Try again.';
    return s.replaceFirst('Exception: ', '');
  }

  void _okSnack(String title, String message) {
    if (!Get.isSnackbarOpen) {
      Get.snackbar(
        title, message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green.shade800,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 2),
      );
    }
  }

  void _errSnack(String title, String message) {
    if (!Get.isSnackbarOpen) {
      Get.snackbar(
        title, message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red.shade800,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
      );
    }
  }
}
