import 'package:get/get.dart';
import 'package:mobile/Api/apis.dart';
import 'package:mobile/Controller/RoleController.dart';

class PasscodeController extends GetxController {
  final api = Get.find<ApiService>();
  final roleController = Get.find<RoleController>();

  final passcode = RxnString();
  final isLoading = false.obs;
  final lastError = ''.obs;

  Future<void> fetchPasscode() async {
    try {
      isLoading.value = true;
      lastError.value = '';
      final userId = roleController.userId.value;
      final response = await api.getPasscode(
        userId: userId.isEmpty ? null : userId,
      );
      passcode.value = response.passcode;
    } catch (ex) {
      lastError.value = ex.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> verifyPasscode(String value) async {
    if (passcode.value == null) {
      await fetchPasscode();
    }

    if (passcode.value == null || passcode.value!.isEmpty) {
      lastError.value = 'No passcode registered for this account.';
      return false;
    }

    final isMatch = passcode.value == value;
    if (!isMatch) {
      lastError.value = 'Incorrect passcode. Please try again.';
    } else {
      lastError.value = '';
    }
    return isMatch;
  }
}
