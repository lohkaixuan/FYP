// ==================================================
// Program Name   : GlobalScaffold.dart
// Purpose        : Reusable scaffold layout component
// Developer      : Mr. Loh Kai Xuan 
// Student ID     : TP074510 
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026 
// ==================================================
import 'package:flutter/material.dart';
import 'package:mobile/Component/GlobalAppBar.dart';
import 'package:mobile/Component/GlobalDrawer.dart';

class GlobalScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final PreferredSizeWidget? bottomAppBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool extendBodyBehindAppBar;
  final List<Widget>? actions;

  const GlobalScaffold({
    super.key,
    required this.title,
    required this.body,
    this.bottomAppBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.extendBodyBehindAppBar = false,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: GlobalAppBar(title: title, actions: actions),
      drawer: const GlobalDrawer(),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

