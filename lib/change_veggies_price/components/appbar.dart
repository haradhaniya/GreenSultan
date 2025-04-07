import 'package:flutter/material.dart';

import '../plants/plants_price.dart';
import '../veggies/veggies_price.dart';


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
              MaterialPageRoute(builder: (context) => const PinVerificationScreen()),
            );
          },
        ),
        TextButton(
          child: Text('Plants', style: TextStyle(color: Colors.white),),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PlantsListBeforeVerification()),
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
