import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Admin/controller/adminController.dart';
import 'package:mobile/Api/apimodel.dart'; // Import your AppUser model
import 'component/button.dart'; // Assuming this exists based on your code
import 'package:mobile/Controller/BottomNavController.dart';

class ManageUserWidget extends StatefulWidget {
  const ManageUserWidget({super.key});

  @override
  State<ManageUserWidget> createState() => _ManageUserWidgetState();
}

class _ManageUserWidgetState extends State<ManageUserWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  final AdminController adminC = Get.put(AdminController());

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      adminC.listAllUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: cs.primary,
        body: SafeArea(
          top: true,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              // --- Header ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Manage User',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // Get the controller
                        final BottomNavController nav =
                            Get.find<BottomNavController>();

                        // Switch to Index 5 (ManageMerchantWidget)
                        // Cast to dynamic if your specific controller methods aren't exposed in the interface
                        (nav as dynamic).changeIndex(5);

                        // If your controller uses .selectedIndex directly:
                        // nav.selectedIndex.value = 5;
                      },
                      icon: const Icon(
                        Icons.store,
                        color: Colors.white,
                        size: 28,
                      ),
                      tooltip: 'Manage Merchant',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // --- Search Bar ---
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 0),
                child: SizedBox(
                  width: double.infinity,
                  child: TextFormField(
                    controller: _searchController,
                    // 4. Update UI when typing to filter the list
                    onChanged: (value) => setState(() {}),
                    autofocus: false,
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      hintStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: cs.primary, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                            color: Colors.transparent, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: cs.secondary,
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                    style: TextStyle(
                        color: cs.onSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // --- User List Area ---
              Expanded(
                child: Obx(() {
                  // State: Loading
                  if (adminC.isLoadingUsers.value) {
                    return const Center(
                        child: CircularProgressIndicator(color: Colors.white));
                  }

                  // State: Error
                  if (adminC.lastError.value.isNotEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(adminC.lastError.value,
                              style: const TextStyle(color: Colors.white)),
                          const SizedBox(height: 10),
                          ElevatedButton(
                              onPressed: () => adminC.listAllUsers(force: true),
                              child: const Text("Retry"))
                        ],
                      ),
                    );
                  }

                  // Filter Logic (Search)
                  final searchText = _searchController.text.toLowerCase();
                  final filteredList = adminC.users.where((u) {
                    return u.userName.toLowerCase().contains(searchText) ||
                        u.email.toLowerCase().contains(searchText);
                  }).toList();

                  // State: Empty
                  if (filteredList.isEmpty) {
                    return const Center(
                      child: Text('No users found',
                          style: TextStyle(color: Colors.white70)),
                    );
                  }

                  // State: Success List
                  return RefreshIndicator(
                    onRefresh: () async =>
                        await adminC.listAllUsers(force: true),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final user = filteredList[index];
                        return _buildUserCard(user);
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(AppUser user) {
    // 1. Format Date
    String dateStr = "N/A";
    if (user.lastLogin != null) {
      final d = user.lastLogin!;
      dateStr =
          "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
    }

    // 2. Define Status Colors & Text based on isDeleted
    final bool isDeleted = user.isDeleted;

    // Status Badge Logic
    final Color statusColor = isDeleted ? Colors.red : Colors.green;
    final String statusText = isDeleted ? 'Deactivated' : 'Active';

    // Button Logic
    final String btnText = isDeleted ? 'Reactivate User' : 'Delete User';
    final Color btnBgColor = isDeleted
        ? const Color(0xFFE6FFFA)
        : const Color(0xFFFFE6E6); // Light Green vs Light Red
    final Color btnTextColor = isDeleted ? Colors.green : Colors.red;
    final Color btnBorderColor = isDeleted ? Colors.green : Colors.red;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white38, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(10, 20, 10, 20),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Avatar ---
              Container(
                width: 50,
                height: 50,
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Colors.grey),
                child: Image.network(
                  'https://ui-avatars.com/api/?name=${user.userName}&background=random',
                  fit: BoxFit.cover,
                  errorBuilder: (c, o, s) =>
                      const Icon(Icons.person, color: Colors.white),
                ),
              ),

              // --- User Details ---
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.userName,
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      Text(user.email,
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text('Last Login: $dateStr',
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 12)),
                      const SizedBox(height: 6),

                      // --- Dynamic Status Badge ---
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: statusColor, // Dynamic Color
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: Text(
                                statusText, // Dynamic Text
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // --- Action Buttons ---
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  UserActionButton(
                    text: 'Edit Info',
                    width: 120,
                    height: 32,
                    color: const Color(0xFF4F46E5),
                    textColor: Colors.white,
                    onPressed: () => print('Edit ${user.userId}'),
                  ),
                  const SizedBox(height: 6),
                  UserActionButton(
                    text: 'Reset Pass',
                    width: 120,
                    height: 32,
                    color: const Color(0xFF60A5FA),
                    textColor: Colors.white,
                    borderColor: const Color(0xFF4F46E5),
                    borderRadius: 6,
                    onPressed: () => print('Reset ${user.userId}'),
                  ),
                  const SizedBox(height: 6),

                  // --- Dynamic Delete/Reactivate Button ---
                  UserActionButton(
                    text: btnText,
                    width: 120,
                    height: 32,
                    color: btnBgColor,
                    textColor: btnTextColor,
                    borderColor: btnBorderColor,
                    borderRadius: 6,
                    onPressed: () {
                      if (isDeleted) {
                        print('Reactivate Pressed for ${user.userId}');
                        // adminC.reactivateUser(user.userId);
                      } else {
                        print('Delete Pressed for ${user.userId}');
                        // adminC.deleteUser(user.userId);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
