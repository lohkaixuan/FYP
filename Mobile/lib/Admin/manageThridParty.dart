import 'package:flutter/material.dart';
import 'component/button.dart';
import 'package:mobile/Component/GlobalScaffold.dart';

class ManageProviderWidget extends StatefulWidget {
  const ManageProviderWidget({super.key});

  @override
  State<ManageProviderWidget> createState() => _ManageProviderWidgetState();
}

class _ManageProviderWidgetState extends State<ManageProviderWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GlobalScaffold(
      title: 'Manage Providers',
      body: Container(
        color: cs.primary,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 0),
              child: SizedBox(
                width: double.infinity,
                child: TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Search Provider...',
                    hintStyle:
                        const TextStyle(color: Colors.grey, fontSize: 16),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: Colors.grey, size: 24),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          clipBehavior: Clip.antiAlias,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: Colors.grey),
                          child: Image.network(
                            'https://images.unsplash.com/photo-1579623003002-841f9dee24d0?w=200',
                            fit: BoxFit.cover,
                            errorBuilder: (c, o, s) =>
                                const Icon(Icons.person, color: Colors.white),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('John Smith',
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600)),
                                const Text('Provider Name 1',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 14)),
                                const Text('Joined: March 15, 2024',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 14)),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(12)),
                                  child: const Text('Active',
                                      style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            UserActionButton(
                                text: 'Edit Info',
                                width: 130,
                                height: 32,
                                color: const Color(0xFF4F46E5),
                                textColor: Colors.white,
                                onPressed: () => print('Edit')),
                            const SizedBox(height: 8),
                            UserActionButton(
                                text: 'Reset Pass',
                                width: 130,
                                height: 32,
                                color: const Color(0xFF60A5FA),
                                textColor: Colors.white,
                                borderColor: const Color(0xFF4F46E5),
                                borderRadius: 6,
                                onPressed: () => print('Reset')),
                            const SizedBox(height: 8),
                            UserActionButton(
                                text: 'Delete',
                                width: 130,
                                height: 32,
                                color: const Color(0xFFFFE6E6),
                                textColor: Colors.red,
                                borderColor: Colors.red,
                                borderRadius: 6,
                                onPressed: () => print('Delete')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
