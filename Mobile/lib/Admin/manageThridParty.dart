import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Admin/controller/adminController.dart';
import 'package:mobile/Api/apimodel.dart'; // Ensure DirectoryAccount is imported
import 'component/button.dart';
import 'package:mobile/Component/GlobalScaffold.dart';

class ManageProviderWidget extends StatefulWidget {
  const ManageProviderWidget({super.key});

  @override
  State<ManageProviderWidget> createState() => _ManageProviderWidgetState();
}

class _ManageProviderWidgetState extends State<ManageProviderWidget> {
  // 1. Initialize Controller & Search
  final AdminController adminC = Get.put(AdminController());
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 2. Fetch data on startup (Force refresh to get latest)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      adminC.fetchDirectory(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GlobalScaffold(
      title: 'Manage Providers',
      body: Container(
        color: cs.primary, // Blue background
        child: Column(
          children: [
            const SizedBox(height: 12),

            // --- Search Bar ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: TextFormField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  // Style for typed text
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w400),
                  decoration: InputDecoration(
                    hintText: 'Search Provider...',
                    hintStyle:
                        const TextStyle(color: Colors.grey, fontSize: 14),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: Colors.grey, size: 24),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: Colors.grey, width: 1)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: Colors.blue, width: 1)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // --- Provider List ---
            Expanded(
              child: Obx(() {
                if (adminC.isLoadingDirectory.value) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.white));
                }

                // Filter logic: Role == 'provider' AND Search match
                final search = _searchController.text.toLowerCase();
                final filtered = adminC.directoryList.where((item) {
                  // Role Check
                  if (item.role != 'provider' && item.role != 'thirdparty')
                    return false;

                  // Search Check
                  return item.name.toLowerCase().contains(search) ||
                      (item.email ?? '').toLowerCase().contains(search);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'No providers found',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => adminC.fetchDirectory(force: true),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildProviderCard(filtered[index]);
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

  Widget _buildProviderCard(DirectoryAccount item) {
    // Status Logic
    final bool isActive = !item.isDeleted;
    final Color statusBg =
        isActive ? Colors.green.shade100 : Colors.red.shade100;
    final Color statusTextCol = isActive ? Colors.green : Colors.red;
    final String statusText = isActive ? 'Active' : 'Inactive';

    // Button Logic
    final String deleteBtnText = isActive ? 'Delete' : 'Reactivate';
    final Color deleteBtnBg =
        isActive ? const Color(0xFFFFE6E6) : const Color(0xFFE6FFFA);
    final Color deleteBtnTextCol = isActive ? Colors.red : Colors.green;
    final Color deleteBtnBorder = isActive ? Colors.red : Colors.green;

    // For Provider Actions, we need the ProviderId.
    // DirectoryAccount stores it in `providerId` or `id` depending on API mapping.
    // Based on your DTO, `id` IS `ProviderId` for providers.
    final String providerId = item.id;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            clipBehavior: Clip.antiAlias,
            decoration:
                const BoxDecoration(shape: BoxShape.circle, color: Colors.grey),
            child: Image.network(
              'https://ui-avatars.com/api/?name=${item.name}&background=random',
              fit: BoxFit.cover,
              errorBuilder: (c, o, s) =>
                  const Icon(Icons.person, color: Colors.white),
            ),
          ),

          // Info Column
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, // Provider Name
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w600)),
                  Text(item.email ?? 'No Email',
                      style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  Text(item.phone ?? 'No Phone',
                      style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 6),
                  // Status Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(statusText,
                        style: TextStyle(
                            color: statusTextCol,
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
                width: 130,
                height: 32,
                color: const Color(0xFF4F46E5),
                textColor: Colors.white,
                onPressed: () =>
                    print('Edit $providerId'), // Connect to Edit Page later
              ),
              const SizedBox(height: 8),

              // Reset Password (Requires `providerId` which for DirectoryAccount is `id`)
              UserActionButton(
                text: 'Reset Pwd',
                width: 130,
                height: 32,
                color: const Color(0xFF60A5FA),
                textColor: Colors.white,
                borderColor: const Color(0xFF4F46E5),
                borderRadius: 6,
                onPressed: () => adminC.resetThirdPartyPassword(providerId),
              ),
              const SizedBox(height: 8),

              // Deactivate / Reactivate
              UserActionButton(
                text: deleteBtnText,
                width: 130,
                height: 32,
                color: deleteBtnBg,
                textColor: deleteBtnTextCol,
                borderColor: deleteBtnBorder,
                borderRadius: 6,
                onPressed: () => adminC.deactivateThirdParty(providerId),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
