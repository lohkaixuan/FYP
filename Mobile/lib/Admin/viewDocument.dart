import 'dart:ui';
import 'package:flutter/material.dart';
import 'component/button.dart';

/// Generate me a page where the admin can see the link oof the slected
/// document with a paper logo and there will be three button one is view
/// document button, accepct button an d reject button
class ViewDocumentWidget extends StatefulWidget {
  const ViewDocumentWidget({super.key});

  static String routeName = 'ViewDocument';
  static String routePath = '/viewDocument';

  @override
  State<ViewDocumentWidget> createState() => _ViewDocumentWidgetState();
}

class _ViewDocumentWidgetState extends State<ViewDocumentWidget> {
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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 4,
                          color: Color(0x1A000000),
                          offset: Offset(
                            0.0,
                            2,
                          ),
                        )
                      ],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Align(
                                  alignment: AlignmentDirectional(0, 0),
                                  child: Icon(
                                    Icons.description_outlined,
                                    color: Colors.grey,
                                    size: 48,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Text(
                            'Document Review',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Text(
                                      'DOCUMENT LINK',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Icon(
                                          Icons.link_rounded,
                                          color: Colors.grey,
                                          size: 16,
                                        ),
                                        Expanded(
                                          child: Text(
                                            'https://documents.example.com/user-submission-2024-001.pdf',
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.blue),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    ViewDocumentButton(
                      onPressed: () {
                        print('Opening document...');
                        // Add your logic to open the file/url here
                      },
                    ),
                    DocumentDecisionRow(
                      onAccept: () {
                        // Add your accept logic here
                        print('Accept button pressed ...');
                      },
                      onReject: () {
                        // Add your reject logic here
                        print('Reject button pressed ...');
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
