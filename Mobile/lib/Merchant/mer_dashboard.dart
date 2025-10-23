import 'package:flutter/material.dart';

class MerchantDashboardScreen extends StatefulWidget {
  const MerchantDashboardScreen({super.key});

  @override
  State<MerchantDashboardScreen> createState() => _MerchantDashboardState();
}
class _MerchantDashboardState extends State<MerchantDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            TotalBalanceWidget(),
            const SizedBox(height: 15),
            BudgetWidget(),
            const SizedBox(height: 15),
            RecentTransactionsWidget(),
          ],
        ),
      ),
    );
  }
}

class TotalBalanceWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monthly Budget', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            LinearProgressIndicator(value: 0.6, backgroundColor: Colors.grey[300], color: Colors.blue),
            SizedBox(height: 10),
            Text('60% of \$5,000 used', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class RecentTransactionsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            ListView(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              children: [
                ListTile(
                  leading: Icon(Icons.shopping_cart, color: Colors.blue),
                  title: Text('Grocery Store'),
                  subtitle: Text('Oct 1, 2024'),
                  trailing: Text('-\$45.67', style: TextStyle(color: Colors.red)),
                ),
                ListTile(
                  leading: Icon(Icons.restaurant, color: Colors.orange),
                  title: Text('Restaurant'),
                  subtitle: Text('Sep 30, 2024'),
                  trailing: Text('-\$78.90', style: TextStyle(color: Colors.red)),
                ),
                ListTile(
                  leading: Icon(Icons.attach_money, color: Colors.green),
                  title: Text('Salary'),
                  subtitle: Text('Sep 28, 2024'),
                  trailing: Text('+\$2,500.00', style: TextStyle(color: Colors.green)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

  