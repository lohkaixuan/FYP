
import 'package:flutter/material.dart';
import 'package:mobile/Component/GlobalAppBar.dart';

class Account extends StatelessWidget {
  const Account({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: GlobalAppBar(
        title: 'Account',
      ),
      body: Center(
        child: Text('Account Screen'),
      ),
    );
  }
}
