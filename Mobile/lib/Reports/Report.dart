import 'package:flutter/material.dart';
import 'package:mobile/Component/GlobalAppBar.dart';

class Report extends StatelessWidget {
  const Report({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: GlobalAppBar(
        title: 'Report',
      ),
      body: Center(
        child: Text('Report Screen'),
      ),
    );
  }
}
