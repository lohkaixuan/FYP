import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Admin/controller/adminController.dart';
import 'package:mobile/Api/apimodel.dart';
import 'component/button.dart';
import 'package:mobile/Component/GlobalScaffold.dart';
import 'package:mobile/Admin/editUser.dart';
import 'package:mobile/Component/AppTheme.dart'; //
import 'package:mobile/Component/GradientWidgets.dart'; //

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
    final txt = theme.textTheme;

    return GlobalScaffold(
      title: 'Manage Providers',
      body: Container(
        // FIXED: Removed 'color: cs.primary' to use default theme background
        width: double.infinity,
        height: double.infinity,
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
                  style: txt.bodyMedium?.copyWith(color: cs.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Search Provider...',
                    hintStyle:
                        txt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                    filled: true,
                    fillColor: cs.surface,
                    prefixIcon: Icon(Icons.search_rounded,
                        color: cs.onSurfaceVariant, size: 24),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.rMd),
                      borderSide: BorderSide(color: cs.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.rMd),
                      borderSide:
                          BorderSide(color: cs.outline.withOpacity(0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.rMd),
                      borderSide: BorderSide(color: cs.primary),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // --- Provider List ---
            Expanded(
              child: Obx(() {
                if (adminC.isLoadingDirectory.value) {
                  return Center(
                      child: CircularProgressIndicator(color: cs.primary));
                }

                // Filter logic: Role == 'provider' or 'thirdparty' AND Search match
                final search = _searchController.text.toLowerCase();
                final filtered = adminC.directoryList.where((item) {
                  // Role Check
                  if (item.role != 'provider' && item.role != 'thirdparty') {
                    return false;
                  }

                  // Search Check
                  return item.name.toLowerCase().contains(search) ||
                      (item.email ?? '').toLowerCase().contains(search);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No providers found',
                      style: txt.bodyLarge?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => adminC.fetchDirectory(force: true),
                  color: cs.primary,
                  child: ListView.separated(
                    padding:
                        const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildProviderCard(context, filtered[index]);
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

  Widget _buildProviderCard(BuildContext context, DirectoryAccount item) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final txt = theme.textTheme;

    // Status Logic
    final bool isActive = !item.isDeleted;
    final bool isDeleted = item.isDeleted;
    final Color statusColor = isActive ? AppTheme.cSuccess : AppTheme.cError;
    final String statusText = isActive ? 'Active' : 'Inactive';

    // Button Logic
    final String deleteBtnText = isActive ? 'Delete' : 'Reactivate';
    final Color deleteBtnBg = isActive ? AppTheme.cError : AppTheme.cSuccess;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppTheme.rMd),
        border: Border.all(color: cs.outline.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            clipBehavior: Clip.antiAlias,
            decoration:
                BoxDecoration(shape: BoxShape.circle, color: cs.surfaceVariant),
            child: Image.network(
              'https://ui-avatars.com/api/?name=${item.name}&background=random',
              fit: BoxFit.cover,
              errorBuilder: (c, o, s) =>
                  const Center(child: GradientIcon(Icons.business, size: 24)),
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
                      style: txt.titleMedium?.copyWith(
                        color: cs.onSurface,
                      )),
                  Text(item.email ?? 'No Email',
                      style: txt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      )),
                  Text(item.phone ?? 'No Phone',
                      style: txt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant.withOpacity(0.8),
                      )),
                  const SizedBox(height: 6),
                  // Status Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(statusText,
                        style: txt.labelSmall?.copyWith(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),

          // Actions Column
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 🔥 GRADIENT BUTTON for Edit Info
              SizedBox(
                width: 130,
                height: 32,
                child: BrandGradientButton(
                  borderRadius: BorderRadius.circular(8),
                  onPressed: () async {
                    await Get.to(() => EditUserWidget(account: item));
                    adminC.fetchDirectory(force: true);
                  },
                  child: const Text('Edit Info',
                      style: TextStyle(fontSize: 12, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 8),

              // Reset Password
              UserActionButton(
                text: 'Reset Pwd',
                width: 130,
                height: 32,
                color: cs.secondary,
                textColor: cs.onSecondary,
                borderColor: cs.secondary,
                borderRadius: 8,
                onPressed: () {
                  if (item.ownerUserId != null) {
                    adminC.resetPassword(item.ownerUserId!, item.name);
                  } else {
                    Get.snackbar(
                        "Error", "This provider has no linked User ID");
                  }
                },
              ),
              const SizedBox(height: 8),

              // Deactivate / Reactivate
              UserActionButton(
                text: deleteBtnText,
                width: 130,
                height: 32,
                color: deleteBtnBg, // Red or Green
                textColor: Colors.white, // Explicit White Text
                borderColor: deleteBtnBg,
                borderRadius: 8,
                onPressed: () {
                  if (item.ownerUserId != null) {
                    adminC.toggleAccountStatus(
                        item.ownerUserId!, 'provider', isDeleted);
                  } else {
                    Get.snackbar("Error", "No linked User ID found");
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
