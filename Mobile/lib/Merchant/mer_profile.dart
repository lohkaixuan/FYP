// import 'package:flutter/material.dart';
// import 'package:mobile/Users/home.dart';

// void main() {
//   runApp(const MaterialApp(
//     debugShowCheckedModeBanner: false,
//     home: HomeScreen(),
//   ));
// }

// class ProfilePage extends StatefulWidget {
//   const ProfilePage({super.key});

//   @override
//   State<ProfilePage> createState() => _ProfilePageState();
// }

// class _ProfilePageState extends State<ProfilePage> {
//   late TextEditingController usernameController; 
//   late TextEditingController idController; 
//   late TextEditingController phoneController;

//   final Map<String, String> profile = {
//     'merchantName': 'Arius Store',
//     'username': 'arius_loi',
//     'id': 'A123456789',
//     'phone': '+60 12-345 6789',
//   };

//   @override
//   void initState() {
//     super.initState();
//       usernameController = TextEditingController(text: profile['username']);
//       idController = TextEditingController(text: profile['id']);
//       phoneController = TextEditingController(text: profile['phone']);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Profile'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.edit),
//             onPressed: () {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text('Edit profile feature coming soon!')),
//               );
//             },
//           ),
//         ],
//       ),

//       backgroundColor: const Color.fromARGB(255, 0, 116, 183),

//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // 头部：头像 + Merchant name
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   const CircleAvatar(
//                     radius: 28,
//                     child: Icon(Icons.store, size: 28),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//                       decoration: BoxDecoration(
//                         border: Border.all(color: Colors.black26),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Row(
//                         children: [
//                           const Text(
//                             'Merchant name: ',
//                             style: TextStyle(fontWeight: FontWeight.w600),
//                           ),
//                           Flexible(
//                             child: Text(
//                               profile['merchantName'] ?? '',
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 16),

//               // 基本信息卡片
//               Card(
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                 elevation: 2,
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Column(
//                     children: [
//                       _InfoRow(label: 'Username', value: profile['username'] ?? ''),
//                       const SizedBox(height: 8),
//                       _InfoRow(label: 'ID', value: profile['id'] ?? ''),
//                       const SizedBox(height: 8),
//                       _InfoRow(label: 'Phone', value: profile['phone'] ?? ''),
//                     ],
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 16),

//               // 两个可跳转的条目
//               Card(
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                 elevation: 2,
//                 child: Column(
//                   children: [
//                     ListTile(
//                       title: const Text('Business License'),
//                       trailing: const Icon(Icons.chevron_right),
//                       onTap: () {
//                         Navigator.of(context).push(
//                           MaterialPageRoute(builder: (_) => const BusinessLicensePage()),
//                         );
//                       },
//                     ),
//                     const Divider(height: 1),
//                     ListTile(
//                       title: const Text('Bank Details'),
//                       trailing: const Icon(Icons.chevron_right),
//                       onTap: () {
//                         Navigator.of(context).push(
//                           MaterialPageRoute(builder: (_) => const BankDetailsPage()),
//                         );
//                       },
//                     ),
//                     const Divider(height: 1),
//                     ListTile(
//                       title: const Text('Change Password'),
//                       trailing: const Icon(Icons.chevron_right),
//                       onTap: () {
//                         Navigator.of(context).push(
//                           MaterialPageRoute(builder: (_) => const HomeScreen()),//change to 6 digit code page
//                         );
//                       },
//                     ),
//                   ],
//                 ),
//               ),

//               const SizedBox(height: 16),

//               Card(
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                 elevation: 1,
//                 child: Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(16),
//                   child: const Text(
//                     'Additional Section\n(例如：上传进度 / 说明 / 备注区域)',
//                     style: TextStyle(color: Colors.black54),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// /// 复用的小部件：左粗体标签 + 右普通文字
// class _InfoRow extends StatelessWidget {
//   final String label;
//   final String value;
//   const _InfoRow({required this.label, required this.value});

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         SizedBox(
//           width: 110,
//           child: Text(
//             '$label:',
//             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//           ),
//         ),
//         Expanded(
//           child: Text(value, style: const TextStyle(fontSize: 16)),
//         ),
//       ],
//     );
//   }
// }

// /// 示例页面：Business License
// class BusinessLicensePage extends StatelessWidget {
//   const BusinessLicensePage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Business License')),
//       body: const Center(child: Text('Upload / View business license here.')),
//     );
//   }
// }

// /// 示例页面：Bank Details
// class BankDetailsPage extends StatelessWidget {
//   const BankDetailsPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Bank Details')),
//       body: const Center(child: Text('Add / Edit bank details here.')),
//     );
//   }
// }
