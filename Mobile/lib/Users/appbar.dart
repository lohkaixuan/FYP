import 'package:flutter/material.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isToggled; // True if user, false if merchant
  final ValueChanged<bool> onToggle;

  const MyAppBar({super.key, required this.isToggled, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text(
        'Finance Tracker',
        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
      ),
      backgroundColor: const Color.fromARGB(255, 0, 116, 183),
      actions: [
        const Text('Personal', style: TextStyle(color: Colors.white)),
        Switch(
          value: isToggled,
          activeColor: Colors.white,
          onChanged: onToggle,
        ),
        const Text('Merchant', style: TextStyle(color: Colors.white)),
        Padding(
          padding: EdgeInsets.only(left: 15, right: 15),
          child: GestureDetector(
            onTap: () {
              // TODO: Open a menu that navigates to profile/settings
            },
            child: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 30, color: Colors.black),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
