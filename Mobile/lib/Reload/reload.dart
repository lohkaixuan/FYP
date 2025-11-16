import 'package:flutter/material.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:mobile/Component/GlobalScaffold.dart';
import 'package:mobile/Transfer/transfer.dart';

class ReloadScreen extends StatefulWidget {
  const ReloadScreen({super.key});

  @override
  State<ReloadScreen> createState() => _ReloadScreenState();
}

class _ReloadScreenState extends State<ReloadScreen> {
  @override
  Widget build(BuildContext context) {
    return TransferScreen(mode: 'reload',);
  }
}
