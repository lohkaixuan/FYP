import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Api/apimodel.dart'; // AppUser, Merchant, ProviderModel
import 'package:mobile/Api/apis.dart';

class AdminController extends GetxController {
  final ApiService api = Get.find<ApiService>();

  // ======= Observables =======
  final users = <AppUser>[].obs;
  final merchants = <Merchant>[].obs;
  final thirdParties = <ProviderModel>[].obs;
  final directoryList = <DirectoryAccount>[].obs;

  final selectedUser = Rxn<AppUser>();
  final selectedMerchant = Rxn<Merchant>();
  final selectedThirdParty = Rxn<ProviderModel>();

  // loading flags
  final isLoadingUsers = false.obs;
  final isLoadingMerchants = false.obs;
  final isLoadingThirdParties = false.obs;
  final isProcessing = false.obs; // generic for edit/reset/deactivate
  final isLoadingDirectory = false.obs;

  // messages
  final lastError = ''.obs;
  final lastOk = ''.obs;

  // ========================
  // USERS
  // ========================
  Future<void> listAllUsers({bool force = false}) async {
    try {
      isLoadingUsers.value = true;
      // Ensure this calls the function we just updated in ApiService
      var list = await ApiService().listUsers();
      users.assignAll(list);
    } catch (e) {
      lastError.value = e.toString();
    } finally {
      isLoadingUsers.value = false;
    }
  }

  Future<AppUser?> getUserDetail(String id) async {
    try {
      isProcessing.value = true;
      lastError.value = '';
      final u = await api.getUser(id);
      selectedUser.value = u;
      lastOk.value = 'User loaded';
      return u;
    } catch (ex) {
      lastError.value = _formatError(ex);
      return null;
    } finally {
      isProcessing.value = false;
    }
  }

  Future<bool> updateUserAccountInfo({
    required String targetUserId,
    required String role,
    required String name,
    required String email,
    required String phone,
    required int age,
    String? icNumber,
    // --- NEW ARGUMENTS ---
    String? merchantName, // For Merchant
    String? merchantPhone, // For Merchant
    String? providerBaseUrl, // For Provider
    bool? providerEnabled, // For Provider
  }) async {
    try {
      isProcessing.value = true;
      lastError.value = '';

      // Prepare Payload (All in one)
      Map<String, dynamic> payload = {
        'user_name': name,
        'user_email': email,
        'user_phone_number': phone,
        'user_age': age,
        'user_ic_number': icNumber,
        // Add new fields to payload
        'merchant_name': merchantName,
        'merchant_phone_number': merchantPhone,
        'provider_base_url': providerBaseUrl,
        'provider_enabled': providerEnabled,
      };

      // Call the API (PUT /api/users/{id})
      await api.updateUser(targetUserId, payload);

      lastOk.value = 'Account Updated Successfully';
      await fetchDirectory(force: true); // Refresh list
      return true;
    } catch (ex) {
      lastError.value = ex.toString();
      return false;
    } finally {
      isProcessing.value = false;
    }
  }

  /// Admin-initiated reset password for a user. If newPassword is null the server may auto-generate one.
  Future<void> resetPassword(String targetUserId, String accountName) async {
    try {
      isProcessing.value = true;

      // Call the API we just updated
      await api.resetPassword(targetUserId);

      // Show Success Snackbar
      Get.snackbar(
        'Success',
        'Password for $accountName has been reset to "12345678"',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 3),
      );
    } catch (ex) {
      // Show Error Snackbar
      Get.snackbar(
        'Error',
        ex.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(10),
      );
    } finally {
      isProcessing.value = false;
    }
  }

  /// Soft-deactivate user (server should set status -> "Deactivate")
  Future<bool> toggleAccountStatus(
      String targetUserId, String role, bool makeActive) async {
    try {
      isProcessing.value = true;
      lastError.value = '';

      // Payload logic:
      // To Reactivate (makeActive=true) -> send is_deleted = false
      // To Delete (makeActive=false)    -> send is_deleted = true
      Map<String, dynamic> payload = {
        'is_deleted': !makeActive,
      };

      await api.updateUser(targetUserId, payload);

      final action = makeActive ? 'Reactivated' : 'Deactivated';

      // Update the list immediately
      await fetchDirectory(force: true);

      Get.snackbar(
        "Success",
        "${role.capitalizeFirst} has been $action successfully",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );

      return true;
    } catch (ex) {
      lastError.value = _formatError(ex);
      Get.snackbar("Error", "Failed: ${lastError.value}",
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    } finally {
      isProcessing.value = false;
    }
  }

  // ========================
  // MERCHANTS
  // ========================
  Future<void> listMerchants({bool force = false}) async {
    if (isLoadingMerchants.value && !force) return;
    try {
      isLoadingMerchants.value = true;
      lastError.value = '';
      final list = await api.listMerchants();
      merchants.assignAll(list);
      lastOk.value = 'Loaded ${list.length} merchants';
    } catch (ex) {
      lastError.value = _formatError(ex);
    } finally {
      isLoadingMerchants.value = false;
    }
  }

  Future<Merchant?> getMerchantDetail(String id) async {
    try {
      isProcessing.value = true;
      lastError.value = '';
      final m = await api.getMerchant(id);
      selectedMerchant.value = m;
      lastOk.value = 'Merchant loaded';
      return m;
    } catch (ex) {
      lastError.value = _formatError(ex);
      return null;
    } finally {
      isProcessing.value = false;
    }
  }

  /// Edit merchant info. `payload` uses backend fields (e.g. 'merchant_name', 'merchant_phone_number')
  // Future<bool> editMerchant(
  //     String merchantId, Map<String, dynamic> payload) async {
  //   try {
  //     isProcessing.value = true;
  //     lastError.value = '';
  //     final updated = await api.updateMerchant(merchantId, payload);
  //     await listMerchants(force: true);
  //     selectedMerchant.value = updated;
  //     lastOk.value = 'Merchant updated';
  //     return true;
  //   } catch (ex) {
  //     lastError.value = _formatError(ex);
  //     return false;
  //   } finally {
  //     isProcessing.value = false;
  //   }
  // }

  Future<bool> approveMerchant(String merchantId) async {
    try {
      isProcessing.value = true;
      lastError.value = '';
      await api.adminApproveMerchant(merchantId);
      lastOk.value = 'Merchant approved';
      await listMerchants(force: true);
      if (selectedMerchant.value?.merchantId == merchantId) {
        await getMerchantDetail(merchantId);
      }
      return true;
    } catch (ex) {
      lastError.value = _formatError(ex);
      return false;
    } finally {
      isProcessing.value = false;
    }
  }

  // ========================
  // THIRD PARTIES (PROVIDERS)
  // ========================
  Future<void> listThirdParties({bool force = false}) async {
    if (isLoadingThirdParties.value && !force) return;
    try {
      isLoadingThirdParties.value = true;
      lastError.value = '';
      final list = await api.listThirdParties();
      thirdParties.assignAll(list);
      lastOk.value = 'Loaded ${list.length} third parties';
    } catch (ex) {
      lastError.value = _formatError(ex);
    } finally {
      isLoadingThirdParties.value = false;
    }
  }

  Future<ProviderModel?> getThirdPartyDetail(String id) async {
    try {
      isProcessing.value = true;
      lastError.value = '';
      final p = await api.getThirdParty(id);
      selectedThirdParty.value = p;
      lastOk.value = 'Third party loaded';
      return p;
    } catch (ex) {
      lastError.value = _formatError(ex);
      return null;
    } finally {
      isProcessing.value = false;
    }
  }

  /// Edit third-party/provider info. use backend keys (e.g. 'name', 'base_url', 'enabled')
  // Future<bool> editThirdParty(
  //     String providerId, Map<String, dynamic> payload) async {
  //   try {
  //     isProcessing.value = true;
  //     lastError.value = '';
  //     final updated = await api.updateThirdParty(providerId, payload);
  //     await listThirdParties(force: true);
  //     selectedThirdParty.value = updated;
  //     lastOk.value = 'Third party updated';
  //     return true;
  //   } catch (ex) {
  //     lastError.value = _formatError(ex);
  //     return false;
  //   } finally {
  //     isProcessing.value = false;
  //   }
  // }

  Future<bool> resetThirdPartyPassword(String providerId,
      {String? newPassword}) async {
    try {
      isProcessing.value = true;
      lastError.value = '';
      await api.adminResetThirdPartyPassword(providerId,
          newPassword: newPassword);
      lastOk.value = 'Third party password reset requested';
      return true;
    } catch (ex) {
      lastError.value = _formatError(ex);
      return false;
    } finally {
      isProcessing.value = false;
    }
  }

  Future<bool> registerThirdParty({
    required String name,
    required String password,
    String? ic,
    String? email,
    String? phone,
    int? age,
  }) async {
    try {
      isProcessing.value = true;
      lastError.value = '';

      // Call API
      await api.registerThirdParty(
        name: name,
        password: password,
        ic: ic,
        email: email,
        phone: phone,
        age: age,
      );

      lastOk.value = 'Third-party registered successfully';

      // Refresh the list immediately so the new provider shows up
      await listThirdParties(force: true);

      return true;
    } catch (ex) {
      lastError.value = _formatError(ex);
      return false;
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> fetchDirectory({bool force = false}) async {
    if (isLoadingDirectory.value && !force) return;
    try {
      isLoadingDirectory.value = true;
      lastError.value = '';

      // Call the new API function
      final list = await api.listDirectory();
      directoryList.assignAll(list);
    } catch (ex) {
      lastError.value = ex.toString();
    } finally {
      isLoadingDirectory.value = false;
    }
  }

  // ========================
  // UTIL
  // ========================
  void clearMessages() {
    lastError.value = '';
    lastOk.value = '';
  }

  String _formatError(Object ex) {
    // You can enhance error formatting here (DioException handling etc.)
    return ex.toString();
  }
}
