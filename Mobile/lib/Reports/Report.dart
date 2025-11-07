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
