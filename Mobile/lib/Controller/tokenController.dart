// ==================================================
// Program Name   : tokenController.dart
// Purpose        : Controller for persisting and retrieving auth tokens
// Developer      : Mr. Loh Kai Xuan 
// Student ID     : TP074510 
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026 
// ==================================================
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class TokenController extends GetxController {
  final _box = GetStorage();
  final token = ''.obs;

  @override
  void onInit() {
    super.onInit();
    token.value = _box.read<String>('token') ?? '';
  }

  Future<void> saveToken(String tk) async {
    token.value = tk;
    await _box.write('token', tk);
  }

  Future<void> clearToken() async {
    token.value = '';
    await _box.remove('token');
  }
}
