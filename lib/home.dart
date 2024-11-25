import 'package:flutter/material.dart';
import 'package:green_sultan/fruits_veggies/products/Customers.dart';
import 'package:green_sultan/rider_app/main.dart';
import 'fruits_veggies/products/veggies_price.dart';
import 'live_hara_dhaniya/main.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        backgroundColor: Colors.green,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            buildCard(
              context,
              title: 'Rider App',
              color: Colors.blueAccent,
              icon: Icons.motorcycle,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MyHomePage()),
              ),
            ),
            buildCard(
              context,
              title: 'Live Hara Dhaniya',
              color: Colors.greenAccent,
              icon: Icons.live_tv,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MessageScreen1()),
              ),
            ),
            buildCard(
              context,
              title: 'Change Prices',
              color: Colors.redAccent,
              icon: Icons.local_grocery_store,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProductList()),
              ),
            ),
            buildCard(
              context,
              title: 'Customer Numbers',
              color: Colors.purple,
              icon: Icons.person,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CustomersScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCard(BuildContext context,
      {required String title,
        required Color color,
        required IconData icon,
        required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 12.0),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(
                    icon,
                    color: color,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
