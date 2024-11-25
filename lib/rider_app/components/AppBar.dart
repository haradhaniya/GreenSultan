import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Function saveData;
  final Function generateAndDisplayInvoice;
  final Function launchWhatsApp;
  final Function clearMessage;

  const CustomAppBar({
    super.key,
    required this.saveData,
    required this.generateAndDisplayInvoice,
    required this.launchWhatsApp,
    required this.clearMessage,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Row(
        children: [
          Icon(Icons.motorcycle),
          SizedBox(width: 8),
          Text('Rider App'),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.print),
          onPressed: () {
            saveData();
            generateAndDisplayInvoice();
          },
        ),
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            clearMessage();
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
