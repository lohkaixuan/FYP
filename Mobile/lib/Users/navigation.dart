import 'package:flutter/material.dart';

class MyNavigation extends StatelessWidget {
  final int _selectedIndex;
  final ValueChanged<int> _onItemTapped;

  const MyNavigation({
    super.key,
    required int selectedIndex,
    required Function(int) onItemTapped,
  }) : _selectedIndex = selectedIndex,
       _onItemTapped = onItemTapped;

  @override
  Widget build(BuildContext context) {
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        indicatorColor: Colors.black, // Selected item background
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        labelTextStyle: WidgetStateProperty.all<TextStyle>(
          const TextStyle(color: Colors.white),
        ),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Colors.white);
          }
          return const IconThemeData(color: Colors.white);
        }),
      ),
      child: NavigationBar(
        selectedIndex: _selectedIndex,
        backgroundColor: const Color.fromARGB(255, 0, 116, 183),
        onDestinationSelected: _onItemTapped,
        destinations: <Widget>[
          NavigationDestination(
            icon: Image.asset('assets/icons/home.png'),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Image.asset('assets/icons/transactions.png'),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Image.asset('assets/icons/reports.png'),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Badge(child: Image.asset('assets/icons/notifications.png')),
            label: 'Notifications',
          ),
        ],
      ),
    );
  }
}

class QRWidget extends StatelessWidget {
  const QRWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, '/scanQr'),
          shape: const CircleBorder(),
          backgroundColor: Colors.white,
          child: Image.asset('assets/icons/qr_code.png'),
        ),
        Text('Scan QR', style: TextStyle(color: Colors.white)),
      ],
    );
  }
}
