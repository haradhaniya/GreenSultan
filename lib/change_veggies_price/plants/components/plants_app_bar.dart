import 'package:flutter/material.dart';
import '../plants_price.dart';



class PlantsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PlantsAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Upload Plants'),
      actions: [
        IconButton(
          icon: const Icon(Icons.lock),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PlantsPinCodeScreen()),
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
