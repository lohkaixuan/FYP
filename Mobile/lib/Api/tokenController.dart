// token.dart
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class TokenController extends GetxController {
  static const _key = 'token';
  final _box = GetStorage();

  // reactive token
  final token = ''.obs;

  @override
  void onInit() {
    super.onInit();
    token.value = _box.read<String>(_key) ?? '';
  }

  bool get isLoggedIn => token.value.isNotEmpty;

  Future<void> saveToken(String value) async {
    await _box.write(_key, value);
    token.value = value;
  }

  Future<void> clearToken() async {
    await _box.remove(_key);
    token.value = '';
  }

  /// ===== Static helpers (for interceptors / non-Get contexts) =====

  static Future<String?> getToken() async {
    // If controller is registered, use reactive value.
    if (Get.isRegistered<TokenController>()) {
      final c = Get.find<TokenController>();
      return c.token.value.isNotEmpty ? c.token.value : null;
    }
    // Fallback to direct storage (in case called very early).
    final box = GetStorage();
    final t = box.read<String>(_key);
    return (t != null && t.isNotEmpty) ? t : null;
  }

  static Future<void> setToken(String value) async {
    if (Get.isRegistered<TokenController>()) {
      await Get.find<TokenController>().saveToken(value);
      return;
    }
    final box = GetStorage();
    await box.write(_key, value);
  }

  static Future<void> removeToken() async {
    if (Get.isRegistered<TokenController>()) {
      await Get.find<TokenController>().clearToken();
      return;
    }
    final box = GetStorage();
    await box.remove(_key);
  }
}
