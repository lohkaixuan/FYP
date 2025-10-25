import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const MerchantDashboardScreen(),
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
    );
  }
}

class MerchantDashboardScreen extends StatefulWidget {
  const MerchantDashboardScreen({super.key});

  @override
  State<MerchantDashboardScreen> createState() => _MerchantDashboardState();
}

class _MerchantDashboardState extends State<MerchantDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Merchant Dashboard')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: const [
          TotalBalanceWidget(),
          BudgetWidget(),
          RecentTransactionsWidget(),
        ],
      ),
    );
  }
}

class TotalBalanceWidget extends StatelessWidget {
  const TotalBalanceWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Total Balance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('\$12,345.67', style: TextStyle(fontSize: 32, color: Colors.green, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class BudgetWidget extends StatelessWidget {
  const BudgetWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monthly Budget', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            LinearProgressIndicator(value: 0.6),
            SizedBox(height: 10),
            Text('60% of \$5,000 used', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class RecentTransactionsWidget extends StatelessWidget {
  const RecentTransactionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            // Use simple Column of ListTiles to avoid nested scroll issues
            _TxTile(icon: Icons.shopping_cart, iconColor: Colors.blue, title: 'Grocery Store', date: 'Oct 1, 2024', amountText: '-\$45.67', amountColor: Colors.red),
            _TxTile(icon: Icons.restaurant, iconColor: Colors.orange, title: 'Restaurant', date: 'Sep 30, 2024', amountText: '-\$78.90', amountColor: Colors.red),
            _TxTile(icon: Icons.attach_money, iconColor: Colors.green, title: 'Salary', date: 'Sep 28, 2024', amountText: '+\$2,500.00', amountColor: Colors.green),
          ],
        ),
      ),
    );
  }
}

class _TxTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String date;
  final String amountText;
  final Color amountColor;

  const _TxTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.date,
    required this.amountText,
    required this.amountColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      subtitle: Text(date),
      trailing: Text(amountText, style: TextStyle(color: amountColor, fontWeight: FontWeight.w600)),
    );
  }
}
