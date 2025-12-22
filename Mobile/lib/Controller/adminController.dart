import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Api/apimodel.dart'; // AppUser, Merchant, ProviderModel
import 'package:mobile/Api/apis.dart';
import 'dart:typed_data'; // ✅ REQUIRED for Uint8List
import 'package:dio/dio.dart'; // ✅ REQUIRED for DioException
import 'package:mobile/Utils/api_dialogs.dart';

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
  // ======= DASHBOARD STATS =======
  final totalVolumeToday = 0.0.obs;
  final activeUserCount = 0.obs;
  final totalTransactionsCount = 0.obs;

  // Graph Data
  final weeklySpots = <FlSpot>[].obs;
  final categorySections = <PieChartSectionData>[].obs;
  final recentTransactions = <TransactionModel>[].obs;
  final isLoadingStats = false.obs;

  // ======= DOCUMENT VIEWING STATE =======
  final currentDocBytes = Rxn<Uint8List>();
  final isDocLoading = false.obs;
  final docErrorMessage = ''.obs;

  // messages
  final lastError = ''.obs;
  final lastOk = ''.obs;

  /// Dashboard
  Future<void> loadDashboardStats() async {
    try {
      isLoadingStats.value = true;

      // 1. Fetch Directory for User Counts
      await fetchDirectory();
      activeUserCount.value = directoryList.where((u) => !u.isDeleted).length;

      // 2. Fetch Transactions (Get last 500 to calculate local stats)
      // In production, you should create a dedicated API endpoint for this aggregation
      // to avoid downloading thousands of records.
      final txListRaw = await api.listTransactions();
      // Cast the dynamic list to TransactionModel list
      final txList = txListRaw.whereType<TransactionModel>().toList();

      totalTransactionsCount.value = txList.length;
      recentTransactions.assignAll(txList.take(5).toList()); // Top 5 recent

      _calculateMoneyFlow(txList);
      _calculateCategoryPie(txList);
    } catch (e) {
      print("Dashboard Error: $e");
    } finally {
      isLoadingStats.value = false;
    }
  }

  void _calculateMoneyFlow(List<TransactionModel> txList) {
    // Calculate Today's Volume
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    totalVolumeToday.value = txList
        .where((t) => t.timestamp != null && t.timestamp!.isAfter(todayStart))
        .fold(0.0, (sum, t) => sum + t.amount);

    // Calculate Last 7 Days Graph Spots
    List<FlSpot> spots = [];
    for (int i = 6; i >= 0; i--) {
      final dayDate = now.subtract(Duration(days: i));
      final dayStart = DateTime(dayDate.year, dayDate.month, dayDate.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      double dailySum = txList
          .where((t) =>
              t.timestamp != null &&
              t.timestamp!.isAfter(dayStart) &&
              t.timestamp!.isBefore(dayEnd))
          .fold(0.0, (sum, t) => sum + t.amount);

      // X = 0 is 7 days ago, X = 6 is Today
      spots.add(FlSpot((6 - i).toDouble(), dailySum));
    }
    weeklySpots.assignAll(spots);
  }

  void _calculateCategoryPie(List<TransactionModel> txList) {
    // Group by Category
    Map<String, double> catMap = {};
    for (var t in txList) {
      final cat = t.category ?? 'Uncategorized';
      catMap[cat] = (catMap[cat] ?? 0) + t.amount;
    }

    // Convert to Pie Sections
    List<Color> colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.red,
      Colors.teal
    ];
    int colorIndex = 0;

    List<PieChartSectionData> sections = [];
    catMap.forEach((key, value) {
      if (value > 0) {
        sections.add(PieChartSectionData(
          color: colors[colorIndex % colors.length],
          value: value,
          title: '${key.substring(0, 1).toUpperCase()}', // Short title
          radius: 50,
          titleStyle: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ));
        colorIndex++;
      }
    });
    categorySections.assignAll(sections);
  }

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

      ApiDialogs.showSuccess(
        'Success',
        'Password for $accountName has been reset to \"12345678\"',
      );
    } catch (ex) {
      ApiDialogs.showError(
        ApiDialogs.formatErrorMessage(ex),
        fallbackTitle: 'Error',
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

      ApiDialogs.showSuccess(
        "Success",
        "${role.capitalizeFirst} has been $action successfully",
      );

      return true;
    } catch (ex) {
      lastError.value = _formatError(ex);
      ApiDialogs.showError(
        "Failed: ${lastError.value}",
        fallbackTitle: "Error",
      );
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
      // This calls the API endpoint shown in your Swagger image
      await api.adminApproveMerchant(merchantId);
      lastOk.value = 'Merchant approved';
      // Refresh directory to show new status/role
      await fetchDirectory(force: true);
      return true;
    } catch (ex) {
      lastError.value = _formatError(ex);
      ApiDialogs.showError(
        "Approve failed: ${lastError.value}",
        fallbackTitle: "Error",
      );
      return false;
    } finally {
      isProcessing.value = false;
    }
  }

  /// Fetches the document bytes for a specific merchant
  Future<void> fetchMerchantDocument(String merchantId) async {
    try {
      isDocLoading.value = true;
      docErrorMessage.value = '';
      currentDocBytes.value = null; // Clear previous

      // Call the API
      final res = await api.downloadMerchantDoc(merchantId);

      // Check data
      if (res.data != null && res.data!.isNotEmpty) {
        currentDocBytes.value = Uint8List.fromList(res.data!);
      } else {
        docErrorMessage.value = "Document is empty or not found on server.";
      }
    } catch (e) {
      // Check for 404 specifically
      if (e is DioException && e.response?.statusCode == 404) {
        docErrorMessage.value = "No document uploaded for this merchant.";
      } else {
        docErrorMessage.value = "Failed to load document: ${e.toString()}";
      }
    } finally {
      isDocLoading.value = false;
    }
  }

  // Ensure your reject function calls the updated API
  Future<bool> rejectMerchant(String merchantId) async {
    try {
      isProcessing.value = true;
      lastError.value = '';

      await api.adminRejectMerchant(merchantId);

      lastOk.value = 'Merchant application rejected';
      ApiDialogs.showSuccess(
        "Success",
        "Merchant application rejected (Soft Deleted)",
      );

      // Refresh directory to update the UI list
      await fetchDirectory(force: true);
      return true;
    } catch (ex) {
      lastError.value = _formatError(ex);
      ApiDialogs.showError(
        "Reject failed: ${lastError.value}",
        fallbackTitle: "Error",
      );
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
