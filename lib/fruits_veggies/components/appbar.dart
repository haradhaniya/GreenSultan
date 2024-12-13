import 'package:flutter/material.dart';
import 'package:green_sultan/fruits_veggies/products/veggies_price.dart';

class ProductAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ProductAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Product Upload'),
      actions: [
        IconButton(
          icon: const Icon(Icons.lock),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PinCodeScreen()),
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
