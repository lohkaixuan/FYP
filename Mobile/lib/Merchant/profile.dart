import 'package:flutter/material.dart';

void main() {
  runApp(
    const MaterialApp(
      home: Profile(),
    ),
  );
}

class Profile extends StatefulWidget {
  const Profile({super.key});

  // This widget is the root of your application.
  @override
  State<Profile> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<Profile> {
  late List<Map<String, dynamic>> profileField;

  @override
  void initState() {
    super.initState();
    _profileField();
  }

  void _profileField() {
    profileField = [
      // Example profile fields
      {
        'label': 'Merchant Name',
        'value': 'CoffeeKing', //later change to actual data
      },
      {
        'label': 'User Name',
        'value': 'UserName',
      },
      {
        'label': 'ID Number',
        'value': 'ID',
      },
      {
        'label': 'Phone',
        'value': 'phone',
      },
    ];
    // Define profile fields here if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Page'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child:Column(
              children: profileField.map((field) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical:8.0),
                child: Row(
                  children: [
                    Expanded(
                      flex:2,
                      child: 
                      Text('${field['label']}: ', style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 16),),
                    ),
                    Expanded(
                      flex:3,
                      child: Text(field['value'], style: const TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
                );
              }).toList(),
            ),
            )
            ),
            ]
            .toList(),
          ),
        ),
    );
  }
}
