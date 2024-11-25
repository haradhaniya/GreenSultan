import 'package:flutter/material.dart';
import '../analytics.dart';
import '../pages/Completed_Order.dart';
import '../pages/Whatsapp Orders.dart';
 // Import the necessary screens

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero, // Remove default padding
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue, // Set background color for header
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage('images/app_logo.png'), // Set profile image
                  radius: 30,
                ),
                SizedBox(height: 16),
                Text(
                  'Welcome, Hara Dhaniya', // Header text
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.living_rounded),
            title: const Text('Whatsapp Orders'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WhatsappOrders()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Analysis Pages'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.countertops),
            title: const Text('Completed Orders'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CompletedOrdersList()),
              );
            },
          ),
        ],
      ),
    );
  }
}
