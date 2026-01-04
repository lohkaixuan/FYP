// ==================================================
// Program Name   : Report.dart
// Purpose        : Report data model and helpers
// Developer      : Mr. Loh Kai Xuan 
// Student ID     : TP074510 
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026 
// ==================================================
import 'package:flutter/material.dart';
import 'package:mobile/Component/GlobalScaffold.dart';

class Report extends StatelessWidget {
  const Report({super.key});
  @override
  Widget build(BuildContext context) {
    return const GlobalScaffold(
      title: 'Report',
      body: Center(child: Text('Report Screen')),
    );
  }
}
