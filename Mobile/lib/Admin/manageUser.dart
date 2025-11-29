import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Admin/controller/adminController.dart';
import 'package:mobile/Api/apimodel.dart';
import 'component/button.dart';
import 'package:mobile/Component/GlobalScaffold.dart';
import 'package:mobile/Admin/editUser.dart';

class ManageUserWidget extends StatefulWidget {
  const ManageUserWidget({super.key});

  @override
  State<ManageUserWidget> createState() => _ManageUserWidgetState();
}

class _ManageUserWidgetState extends State<ManageUserWidget> {
  final AdminController adminC = Get.put(AdminController());
  final TextEditingController _searchController = TextEditingController();

  // Toggle State: False = Users, True = Merchants
  bool isShowingMerchants = false;

  @override
  void initState() {
    super.initState();
    // ✅ Fetch the directory data when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      adminC.fetchDirectory(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GlobalScaffold(
      title: isShowingMerchants ? 'Manage Merchants' : 'Manage Users',
      actions: [
        IconButton(
          onPressed: () {
            setState(() {
              // ✅ Toggle the view without changing pages
              isShowingMerchants = !isShowingMerchants;
              _searchController.clear();
            });
          },
          icon: Icon(
            isShowingMerchants ? Icons.person : Icons.store,
            color: Colors.white,
            size: 28,
          ),
          tooltip: 'Switch View',
        ),
      ],
      body: Container(
        color: cs.primary,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextFormField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w400),
                decoration: InputDecoration(
                  hintText: isShowingMerchants
                      ? 'Search merchants...'
                      : 'Search users...',
                  hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w400),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: Colors.grey, size: 24),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Obx(() {
                if (adminC.isLoadingDirectory.value) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.white));
                }

                // 1. Filter by Role (User vs Merchant)
                final targetRole = isShowingMerchants ? 'merchant' : 'user';
                final search = _searchController.text.toLowerCase();

                final filtered = adminC.directoryList.where((item) {
                  // Check if role matches
                  if (item.role != targetRole) return false;
                  // Check search text
                  return item.name.toLowerCase().contains(search) ||
                      (item.email ?? '').toLowerCase().contains(search);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No ${isShowingMerchants ? "merchants" : "users"} found',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => adminC.fetchDirectory(force: true),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final item = filtered[i];
                      // Show correct card based on view
                      if (isShowingMerchants) {
                        return _buildMerchantCard(item);
                      } else {
                        return _buildUserCard(item);
                      }
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 👤 USER CARD (With Reset Password)
  // ==========================================
  Widget _buildUserCard(DirectoryAccount item) {
    String dateStr = "N/A";
    if (item.lastLogin != null) {
      final d = item.lastLogin!;
      dateStr =
          "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
    }

    final bool isDeleted = item.isDeleted;
    final Color statusColor = isDeleted ? Colors.red : Colors.green;
    final String statusText = isDeleted ? 'Deactivated' : 'Active';

    // Button styling logic
    final String btnText = isDeleted ? 'Reactivate User' : 'Delete User';
    final Color btnBgColor =
        isDeleted ? const Color(0xFFE6FFFA) : const Color(0xFFFFE6E6);
    final Color btnTextColor = isDeleted ? Colors.green : Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white38, width: 1),
        ),
        padding: const EdgeInsetsDirectional.fromSTEB(10, 20, 10, 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Colors.grey),
              child: Image.network(
                'https://ui-avatars.com/api/?name=${item.name}&background=random',
                fit: BoxFit.cover,
                errorBuilder: (c, o, s) =>
                    const Icon(Icons.person, color: Colors.white),
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    Text(item.email ?? '',
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text('Last Login: $dateStr',
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 12)),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Text(statusText,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),

            // Actions Column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                UserActionButton(
                  text: 'Edit Info',
                  width: 120,
                  height: 32,
                  color: const Color(0xFF4F46E5),
                  textColor: Colors.white,
                  onPressed: () async {
                    // ✅ CORRECT: Arrow syntax () => Widget
                    await Get.to(() => EditUserWidget(account: item));
                    adminC.fetchDirectory(force: true);
                  },
                ),
                const SizedBox(height: 6),

                // ✅ ADDED BACK: Reset Password Button
                UserActionButton(
                  text: 'Reset Pwd',
                  width: 120,
                  height: 32,
                  color: const Color(0xFF60A5FA),
                  textColor: Colors.white,
                  borderColor: const Color(0xFF4F46E5),
                  borderRadius: 6,
                  onPressed: () => adminC.resetPassword(item.id, item.name),
                ),
                const SizedBox(height: 6),

                // Delete / Reactivate Button
                UserActionButton(
                  text: btnText,
                  width: 120,
                  height: 32,
                  color: btnBgColor,
                  textColor: btnTextColor,
                  borderColor: Colors.red,
                  borderRadius: 6,
                  onPressed: () => adminC.deactivateUser(item.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 🏪 MERCHANT CARD
  // ==========================================
  Widget _buildMerchantCard(DirectoryAccount item) {
    final bool isActive = !item.isDeleted;
    final Color statusColor = isActive ? Colors.green : Colors.red;
    final String statusText = isActive ? 'Active' : 'Inactive';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey, width: 1),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: NetworkImage(
                  'https://ui-avatars.com/api/?name=${item.name}&background=0D8ABC&color=fff'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                  Text(item.phone ?? 'No Phone',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      )),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Text(statusText,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                UserActionButton(
                  text: 'Edit Info',
                  width: 130,
                  height: 34.87,
                  color: const Color(0xFF4F46E5),
                  textColor: Colors.white,
                  borderRadius: 8,
                  onPressed: () async {
                    // ✅ CORRECT: Arrow syntax () => Widget
                    await Get.to(() => EditUserWidget(account: item));
                    adminC.fetchDirectory(force: true);
                  },
                ),
                const SizedBox(height: 8),
                UserActionButton(
                  text: 'Reset Pwd',
                  width: 130,
                  height: 32,
                  color: const Color(0xFF60A5FA),
                  textColor: Colors.white,
                  borderColor: const Color(0xFF4F46E5),
                  borderRadius: 6,
                  onPressed: () {
                    if (item.ownerUserId != null) {
                      adminC.resetPassword(item.ownerUserId!, item.name);
                    } else {
                      Get.snackbar(
                          "Error", "This merchant has no linked User ID");
                    }
                  },
                ),
                const SizedBox(height: 6),
                UserActionButton(
                  text: 'View Doc',
                  width: 130,
                  height: 32,
                  color: const Color(0xFF60A5FA),
                  textColor: Colors.white,
                  borderRadius: 6,
                  borderColor: const Color(0xFF4F46E5),
                  onPressed: () {
                    print('View Document pressed');
                  },
                ),
                const SizedBox(height: 8),
                UserActionButton(
                  text: 'Delete',
                  width: 130,
                  height: 32,
                  color: const Color(0xFFFFE6E6),
                  textColor: const Color(0xFFE11D48),
                  borderRadius: 6,
                  borderColor: const Color(0xFFE11D48),
                  onPressed: () {
                    print('Delete Merchant pressed');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
