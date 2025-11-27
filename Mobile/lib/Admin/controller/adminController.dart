import 'package:get/get.dart';
import 'package:mobile/Api/apimodel.dart'; // AppUser, Merchant, ProviderModel
import 'package:mobile/Api/apis.dart';

class AdminController extends GetxController {
  final ApiService api = Get.find<ApiService>();

  // ======= Observables =======
  final users = <AppUser>[].obs;
  final merchants = <Merchant>[].obs;
  final thirdParties = <ProviderModel>[].obs;

  final selectedUser = Rxn<AppUser>();
  final selectedMerchant = Rxn<Merchant>();
  final selectedThirdParty = Rxn<ProviderModel>();

  // loading flags
  final isLoadingUsers = false.obs;
  final isLoadingMerchants = false.obs;
  final isLoadingThirdParties = false.obs;
  final isProcessing = false.obs; // generic for edit/reset/deactivate

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

  /// Edit user info. `payload` must use backend field names (e.g. 'user_name', 'user_email')
  Future<bool> editUser(String userId, Map<String, dynamic> payload) async {
    try {
      isProcessing.value = true;
      lastError.value = '';
      final updated = await api.updateUser(userId, payload);
      // refresh lists/selected
      await listAllUsers(force: true);
      selectedUser.value = updated;
      lastOk.value = 'User updated';
      return true;
    } catch (ex) {
      lastError.value = _formatError(ex);
      return false;
    } finally {
      isProcessing.value = false;
    }
  }

  /// Admin-initiated reset password for a user. If newPassword is null the server may auto-generate one.
  Future<bool> resetUserPassword(String userId, {String? newPassword}) async {
    try {
      isProcessing.value = true;
      lastError.value = '';
      await api.adminResetUserPassword(userId, newPassword: newPassword);
      lastOk.value = 'User password reset requested';
      return true;
    } catch (ex) {
      lastError.value = _formatError(ex);
      return false;
    } finally {
      isProcessing.value = false;
    }
  }

  /// Soft-deactivate user (server should set status -> "Deactivate")
  Future<bool> deactivateUser(String userId) async {
    try {
      isProcessing.value = true;
      lastError.value = '';
      await api.updateUserStatus(userId, 'Deactivate');
      lastOk.value = 'User deactivated';
      await listAllUsers(force: true);
      if (selectedUser.value?.userId == userId) {
        await getUserDetail(userId);
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
  Future<bool> editMerchant(
      String merchantId, Map<String, dynamic> payload) async {
    try {
      isProcessing.value = true;
      lastError.value = '';
      final updated = await api.updateMerchant(merchantId, payload);
      await listMerchants(force: true);
      selectedMerchant.value = updated;
      lastOk.value = 'Merchant updated';
      return true;
    } catch (ex) {
      lastError.value = _formatError(ex);
      return false;
    } finally {
      isProcessing.value = false;
    }
  }

  Future<bool> deactivateMerchant(String merchantId) async {
    try {
      isProcessing.value = true;
      lastError.value = '';
      await api.updateMerchantStatus(merchantId, 'Deactivate');
      lastOk.value = 'Merchant deactivated';
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
  Future<bool> editThirdParty(
      String providerId, Map<String, dynamic> payload) async {
    try {
      isProcessing.value = true;
      lastError.value = '';
      final updated = await api.updateThirdParty(providerId, payload);
      await listThirdParties(force: true);
      selectedThirdParty.value = updated;
      lastOk.value = 'Third party updated';
      return true;
    } catch (ex) {
      lastError.value = _formatError(ex);
      return false;
    } finally {
      isProcessing.value = false;
    }
  }

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

  Future<bool> deactivateThirdParty(String providerId) async {
    try {
      isProcessing.value = true;
      lastError.value = '';
      await api.updateThirdPartyStatus(providerId, 'Deactivate');
      lastOk.value = 'Third party deactivated';
      await listThirdParties(force: true);
      if (selectedThirdParty.value?.providerId == providerId) {
        await getThirdPartyDetail(providerId);
      }
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
      await api.registerThirdParty(
        name: name,
        password: password,
        ic: ic,
        email: email,
        phone: phone,
        age: age,
      );
      // res is Map<String,dynamic>
      lastOk.value = 'Third-party registered';
      await listThirdParties(force: true);
      return true;
    } catch (ex) {
      lastError.value = _formatError(ex);
      return false;
    } finally {
      isProcessing.value = false;
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
