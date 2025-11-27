import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Auth/auth.dart';

class AdminDashboardWidget extends StatefulWidget {
  const AdminDashboardWidget({super.key});

  @override
  State<AdminDashboardWidget> createState() => _AdminDashboardWidgetState();
}

class _AdminDashboardWidgetState extends State<AdminDashboardWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedRange = '7D';

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
    final auth = Get.find<AuthController>();
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
          child: SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Analytics Dashboard',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            await auth.logout();
                            Get.offAllNamed('/login');
                          },
                          icon: const Icon(
                            Icons.logout, // logout icon
                            color: Colors.white,
                            size: 28,
                          ),
                          tooltip: 'Logout',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 0),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(
                          child: Container(
                            width: 100,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '1,247',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF105DFB)),
                                  ),
                                  Text(
                                    'Today',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF5A5C60)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            width: 100,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '28,456',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF02CA79)),
                                    ),
                                    Text(
                                      'This Month',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF5A5C60)),
                                    ),
                                  ]),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            width: 100,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '342K',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFEE8B60)),
                                  ),
                                  Text(
                                    'This Year',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF5A5C60)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text('New User Growth',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                            const SizedBox(width: 12),
                            // Give chips space to layout; Expanded prevents Row from forcing infinite width
                            Expanded(
                              flex: 3,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: SizedBox(
                                  height: 48,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        ChoiceChip(
                                          label: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            child: Text(
                                              '7D',
                                              style: TextStyle(
                                                color: _selectedRange == '7D'
                                                    ? Colors.white
                                                    : const Color(0xFF5A5C60),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          selected: _selectedRange == '7D',
                                          selectedColor:
                                              const Color(0xFF105DFB),
                                          backgroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            side: BorderSide(
                                                color: _selectedRange == '7D'
                                                    ? const Color(0xFF105DFB)
                                                    : const Color(0xFFE6E6E6)),
                                          ),
                                          onSelected: (_) => setState(
                                              () => _selectedRange = '7D'),
                                        ),
                                        const SizedBox(width: 10),
                                        ChoiceChip(
                                          label: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            child: Text(
                                              '30D',
                                              style: TextStyle(
                                                color: _selectedRange == '30D'
                                                    ? Colors.white
                                                    : const Color(0xFF5A5C60),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          selected: _selectedRange == '30D',
                                          selectedColor:
                                              const Color(0xFF105DFB),
                                          backgroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            side: BorderSide(
                                                color: _selectedRange == '30D'
                                                    ? const Color(0xFF105DFB)
                                                    : const Color(0xFFE6E6E6)),
                                          ),
                                          onSelected: (_) => setState(
                                              () => _selectedRange = '30D'),
                                        ),
                                        const SizedBox(width: 10),
                                        ChoiceChip(
                                          label: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            child: Text(
                                              '90D',
                                              style: TextStyle(
                                                color: _selectedRange == '90D'
                                                    ? Colors.white
                                                    : const Color(0xFF5A5C60),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          selected: _selectedRange == '90D',
                                          selectedColor:
                                              const Color(0xFF105DFB),
                                          backgroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            side: BorderSide(
                                                color: _selectedRange == '90D'
                                                    ? const Color(0xFF105DFB)
                                                    : const Color(0xFFE6E6E6)),
                                          ),
                                          onSelected: (_) => setState(
                                              () => _selectedRange = '90D'),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.network(
                                  'https://images.unsplash.com/photo-1692859415442-94eabe7a7488?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHJhbmRvbXx8fHx8fHx8fDE3NjI5NDIyNTd8&ixlib=rb-4.1.0&q=80&w=1080',
                                  width: double.infinity,
                                  height: 160,
                                  fit: BoxFit.contain,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Monthly Overview',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          height: 250,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            height: 250,
                            child: Stack(
                              children: [
                                PageView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'January 2024',
                                                style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white),
                                              ),
                                              Text(
                                                '+12.5%',
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xFF02CA79)),
                                              ),
                                            ],
                                          ),
                                          Padding(
                                            padding: const EdgeInsetsDirectional
                                                .fromSTEB(0, 12, 0, 0),
                                            child: Image.network(
                                              'https://images.unsplash.com/photo-1612310595736-9e2a8c1d676a?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHJhbmRvbXx8fHx8fHx8fDE3NjI5NDIyNTd8&ixlib=rb-4.1.0&q=80&w=1080',
                                              width: double.infinity,
                                              height: 150,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                          const Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0, 8, 0, 0),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Peak: 2,847 users',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      color: Color(0xFF5A5C60)),
                                                ),
                                                Text(
                                                  'Avg: 1,923 users',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      color: Color(0xFF5A5C60)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'February 2024',
                                                style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white),
                                              ),
                                              Text(
                                                '+8.3%',
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xFF02CA79)),
                                              ),
                                            ],
                                          ),
                                          Padding(
                                            padding: const EdgeInsetsDirectional
                                                .fromSTEB(0, 12, 0, 0),
                                            child: Image.network(
                                              'https://images.unsplash.com/photo-1616534846636-2372539a94a8?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHJhbmRvbXx8fHx8fHx8fDE3NjI5NDIyNTd8&ixlib=rb-4.1.0&q=80&w=1080',
                                              width: double.infinity,
                                              height: 150,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                          const Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0, 8, 0, 0),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Peak: 3,124 users',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      color: Color(0xFF5A5C60)),
                                                ),
                                                Text(
                                                  'Avg: 2,156 users',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      color: Color(0xFF5A5C60)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'March 2024',
                                                style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white),
                                              ),
                                              Text(
                                                '+15.7%',
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xFF02CA79)),
                                              ),
                                            ],
                                          ),
                                          Padding(
                                            padding: const EdgeInsetsDirectional
                                                .fromSTEB(0, 12, 0, 0),
                                            child: Image.network(
                                              'https://images.unsplash.com/photo-1588343823210-663b8e34d258?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHJhbmRvbXx8fHx8fHx8fDE3NjI5NDIyNTd8&ixlib=rb-4.1.0&q=80&w=1080',
                                              width: double.infinity,
                                              height: 150,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                          const Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0, 8, 0, 0),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Peak: 3,567 users',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      color: Color(0xFF5A5C60)),
                                                ),
                                                Text(
                                                  'Avg: 2,489 users',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      color: Color(0xFF5A5C60)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                // Align(
                                //   alignment: const AlignmentDirectional(0, 1),
                                //   child: Padding(
                                //     padding: const EdgeInsetsDirectional.fromSTEB(
                                //         0, 0, 0, 16),
                                //     child:
                                //         smooth_page_indicator.SmoothPageIndicator(
                                //       controller: _model.pageViewController1 ??=
                                //           PageController(initialPage: 0),
                                //       count: 3,
                                //       axisDirection: Axis.horizontal,
                                //       onDotClicked: (i) async {
                                //         await _model.pageViewController1!
                                //             .animateToPage(
                                //           i,
                                //           duration: Duration(milliseconds: 500),
                                //           curve: Curves.ease,
                                //         );
                                //         safeSetState(() {});
                                //       },
                                //       effect: const smooth_page_indicator.SlideEffect(
                                //         spacing: 8,
                                //         radius: 4,
                                //         dotWidth: 8,
                                //         dotHeight: 8,
                                //         dotColor: Color(0xFFE0E3E7),
                                //         activeDotColor: Color(0xFF105DFB),
                                //         paintStyle: PaintingStyle.fill,
                                //       ),
                                //     ),
                                //   ),
                                // ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ]),
          ),
        ),
      ),
    );
  }
}
