import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Controller/Admin/adminController.dart';
import 'package:mobile/Api/apimodel.dart';
import 'component/button.dart';
import 'package:mobile/Component/GlobalScaffold.dart';
import 'package:mobile/Admin/editUser.dart';
import 'package:mobile/Admin/viewDocument.dart';
import 'package:mobile/Component/AppTheme.dart'; //
import 'package:mobile/Component/GradientWidgets.dart'; //

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
      title: isShowingMerchants ? 'Manage Merchants' : 'Manage Users',
      actions: [
        IconButton(
          onPressed: () {
            setState(() {
              isShowingMerchants = !isShowingMerchants;
              _searchController.clear();
            });
          },
          icon: Icon(
            isShowingMerchants ? Icons.person : Icons.store,
            color: cs.onPrimary,
            size: 28,
          ),
          tooltip: 'Switch To Merchant',
        ),
      ],
      body: SizedBox(
        // Removed hardcoded background color to use Theme's default (White/Dark)
        width: double.infinity,
        height: double.infinity,
        child: Column(
          children: [
            const SizedBox(height: 12),
            // --- SEARCH BAR ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextFormField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: txt.bodyMedium,
                decoration: InputDecoration(
                  hintText: isShowingMerchants
                      ? 'Search merchants...'
                      : 'Search users...',
                  hintStyle: txt.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                  filled: true,
                  fillColor: cs.surface, // Adapts to Dark/Light mode
                  prefixIcon: Icon(Icons.search_rounded,
                      color: cs.onSurfaceVariant, size: 24),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.rMd),
                    borderSide: BorderSide(color: cs.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.rMd),
                    borderSide: BorderSide(color: cs.outline.withOpacity(0.5)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Obx(() {
                if (adminC.isLoadingDirectory.value) {
                  return Center(
                      child: CircularProgressIndicator(color: cs.primary));
                }

                final targetRole = isShowingMerchants ? 'merchant' : 'user';
                final search = _searchController.text.toLowerCase();

                final filtered = adminC.directoryList.where((item) {
                  if (item.role != targetRole) return false;
                  return item.name.toLowerCase().contains(search) ||
                      (item.email ?? '').toLowerCase().contains(search);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No ${isShowingMerchants ? "merchants" : "users"} found',
                      style: txt.bodyLarge?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => adminC.fetchDirectory(force: true),
                  color: cs.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final item = filtered[i];
                      if (isShowingMerchants) {
                        return _buildMerchantCard(context, item);
                      } else {
                        return _buildUserCard(context, item);
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
  // 👤 USER CARD
  // ==========================================
  Widget _buildUserCard(BuildContext context, DirectoryAccount item) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final txt = theme.textTheme;

    String dateStr = "N/A";
    if (item.lastLogin != null) {
      final d = item.lastLogin!;
      dateStr =
          "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
    }

    final bool isDeleted = item.isDeleted;
    // Use AppTheme colors for status
    final Color statusColor = isDeleted ? AppTheme.cError : AppTheme.cSuccess;
    final String statusText = isDeleted ? 'Deactivated' : 'Active';

    // Button Logic
    final String btnText = isDeleted ? 'Reactivate' : 'Delete';
    final Color btnBgColor = isDeleted ? AppTheme.cSuccess : AppTheme.cError;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Container(
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
        padding: const EdgeInsetsDirectional.fromSTEB(12, 16, 12, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar with GradientIcon fallback
            Container(
              width: 50,
              height: 50,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: cs.surfaceVariant),
              child: Image.network(
                'https://ui-avatars.com/api/?name=${item.name}&background=random',
                fit: BoxFit.cover,
                errorBuilder: (c, o, s) =>
                    const Center(child: GradientIcon(Icons.person, size: 28)),
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
                        style: txt.titleMedium?.copyWith(
                          color: cs.onSurface,
                        )),
                    Text(item.email ?? '',
                        style: txt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        )),
                    const SizedBox(height: 4),
                    Text('Last Login: $dateStr',
                        style: txt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant.withOpacity(0.7))),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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
                // 🔥 GRADIENT BUTTON for Edit Info (Primary Action)
                SizedBox(
                  width: 120,
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
                const SizedBox(height: 6),

                UserActionButton(
                  text: 'Reset Pwd',
                  width: 120,
                  height: 32,
                  color: cs.secondary,
                  textColor: cs.onSecondary,
                  borderColor: cs.secondary,
                  borderRadius: 8,
                  onPressed: () => adminC.resetPassword(item.id, item.name),
                ),
                const SizedBox(height: 6),

                UserActionButton(
                  text: btnText,
                  width: 120,
                  height: 32,
                  color: btnBgColor,
                  textColor: Colors.white, // Explicit white text
                  borderColor: btnBgColor,
                  borderRadius: 8,
                  onPressed: () {
                    adminC.toggleAccountStatus(item.id, 'user', isDeleted);
                  },
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
  Widget _buildMerchantCard(BuildContext context, DirectoryAccount item) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final txt = theme.textTheme;

    final bool isActive = !item.isDeleted;
    final Color statusColor = isActive ? AppTheme.cSuccess : AppTheme.cError;
    final String statusText = isActive ? 'Active' : 'Inactive';
    final bool isDeleted = item.isDeleted;
    final bool isPending = item.role == 'user';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Container(
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
            CircleAvatar(
              radius: 25,
              backgroundColor: cs.surfaceVariant,
              backgroundImage: NetworkImage(
                  'https://ui-avatars.com/api/?name=${item.name}&background=0D8ABC&color=fff'),
              onBackgroundImageError: (_, __) {},
              child: item.name.isEmpty
                  ? const GradientIcon(Icons.store, size: 24)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: txt.titleMedium?.copyWith(
                        color: cs.onSurface,
                      )),
                  Text(item.phone ?? 'No Phone',
                      style: txt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      )),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Text(statusText,
                            style:
                                txt.labelSmall?.copyWith(color: Colors.white)),
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
                          "Error", "This merchant has no linked User ID");
                    }
                  },
                ),
                const SizedBox(height: 6),
                UserActionButton(
                  text: isPending ? 'Review Doc' : 'View Doc',
                  width: 130,
                  height: 32,
                  color: AppTheme.cSuccess, // Green
                  textColor: Colors.white, // Explicit white text
                  borderRadius: 8,
                  borderColor: AppTheme.cSuccess,
                  onPressed: () {
                    Get.to(() => ViewDocumentWidget(merchantAccount: item));
                  },
                ),
                const SizedBox(height: 8),
                UserActionButton(
                  text: 'Delete',
                  width: 130,
                  height: 32,
                  color: AppTheme.cError, // Red
                  textColor: Colors.white, // Explicit white text
                  borderRadius: 8,
                  borderColor: AppTheme.cError,
                  onPressed: () {
                    if (isDeleted) return;
                    if (item.ownerUserId != null) {
                      adminC.toggleAccountStatus(
                          item.ownerUserId!, 'merchant', false);
                    } else {
                      Get.snackbar("Error", "No linked User ID found");
                    }
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
