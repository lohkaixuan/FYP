import 'package:mobile/Admin/controller/adminBottomNavController.dart';
import 'package:mobile/Component/BottomNav.dart';
import 'package:mobile/Controller/BottomNavController.dart';

import 'component/button.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ManageMerchantWidget extends StatefulWidget {
  const ManageMerchantWidget({super.key});

  @override
  State<ManageMerchantWidget> createState() => _ManageMerchantWidgetState();
}

class _ManageMerchantWidgetState extends State<ManageMerchantWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Manage Merchant',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // 1. 切到底部导航的 “Users” tab（index 自己确认：0=Dashboard, 1=API, 2=Users...）
                        final navC = Get.find<BottomNavController>();
                        navC.changeIndex(2); // 如果 Users 不是 2，就改成对应的 index

                        // 2. 回到统一的 admin 外壳（BottomNavApp，role=admin 时会显示 admin 导航）
                        Get.offAllNamed('/admin');
                      },
                      icon: const Icon(
                        Icons.person, // you can choose any icon you like
                        color: Colors.white,
                        size: 28,
                      ),
                      tooltip: 'Manage Merchant',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 0),
                child: Container(
                  width: double.infinity,
                  child: TextFormField(
                    autofocus: false,
                    obscureText: false,
                    decoration: InputDecoration(
                      hintText: 'Search merchants...',
                      hintStyle: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          fontWeight: FontWeight.w400),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Color(0x00000000),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Color(0x00000000),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Color(0x00000000),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Colors.grey,
                        size: 24,
                      ),
                    ),
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w400),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 0),
                child: ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  scrollDirection: Axis.vertical,
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey,
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            10, 20, 10, 20),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              clipBehavior: Clip.antiAlias,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: Image.network(
                                'https://images.unsplash.com/photo-1579623003002-841f9dee24d0?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHJhbmRvbXx8fHx8fHx8fDE3NjI0OTU2MjB8&ixlib=rb-4.1.0&q=80&w=1080',
                                fit: BoxFit.cover,
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    16, 0, 16, 0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'John Smith',
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    const Text(
                                      'Merchant 1 Name ',
                                      style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400),
                                    ),
                                    const Text(
                                      'Joined: March 15, 2024',
                                      style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsetsDirectional
                                              .fromSTEB(0, 0, 8, 0),
                                          child: Container(
                                            height: 34.35,
                                            decoration: BoxDecoration(
                                              color: Colors.greenAccent,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Align(
                                              alignment:
                                                  AlignmentDirectional(0, 0),
                                              child: Padding(
                                                padding: EdgeInsets.all(8),
                                                child: Text(
                                                  'Active',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                ),
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
                                  onPressed: () {
                                    print('Edit pressed');
                                  },
                                ),
                                const SizedBox(height: 8),
                                UserActionButton(
                                  text: 'View Document',
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
                            const SizedBox(height: 8)
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
