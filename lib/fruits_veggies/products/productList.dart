import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:green_sultan/fruits_veggies/products/productCard.dart';
class ProductsList extends StatelessWidget {
  final bool isPinVerified;
  final String searchQuery;
  final TextEditingController _pinController = TextEditingController();
  final String _correctPin = '786';

  ProductsList(
      {super.key, required this.isPinVerified, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // Assuming 'Lahore' is the selected city
      // You can replace it with a dynamic city based on user selection
      stream: FirebaseFirestore.instance
          .collection('Cities') // Cities collection
          .doc('Lahore') // Lahore document (or dynamically selected city)
          .collection('LahoreVeggies') // Veggies collection under Lahore
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No products available'));
        }

        // Filter products based on search query
        var filteredProducts = snapshot.data!.docs.where((doc) {
          var name = doc['name'].toString().toLowerCase();
          return name.contains(searchQuery.toLowerCase());
        }).toList();

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  var product = filteredProducts[index];
                  return ProductCard(
                    product: product,
                    isPinVerified: isPinVerified,
                    index: index + 1,
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _clearValue1(context);
              },
              child: const Text('Clear Value 1'),
            ),
          ],
        );
      },
    );
  }

  void _clearValue1(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter PIN'),
          content: TextField(
            controller: _pinController,
            decoration: const InputDecoration(labelText: 'PIN'),
            keyboardType: TextInputType.number,
            obscureText: true,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _verifyPinForClearValue(context);
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void _verifyPinForClearValue(BuildContext context) {
    if (_pinController.text == _correctPin) {
      Navigator.of(context).pop();

      // Assuming 'Lahore' is the selected city, you can replace it with dynamic city
      String city = 'Lahore'; // You can dynamically choose the city

      // Get all documents from the Veggies collection under the selected city (Lahore)
      FirebaseFirestore.instance
          .collection('Cities') // Cities collection
          .doc(city) // City document (e.g., 'Lahore')
          .collection('LahoreVeggies') // Veggies collection under Lahore
          .get()
          .then((snapshot) {
        WriteBatch batch = FirebaseFirestore.instance.batch();

        for (var doc in snapshot.docs) {
          batch.update(doc.reference, {'value1': '0'});
        }

        return batch.commit().then((_) {
          // Also update the 'veggies_values' collection
          return FirebaseFirestore.instance
              .collection('Cities') // Cities collection
              .doc(city) // City document (e.g., 'Lahore')
              .collection(
              'veggies_values') // veggies_values collection under Lahore
              .get()
              .then((valueSnapshot) {
            WriteBatch valueBatch = FirebaseFirestore.instance.batch();

            for (var valueDoc in valueSnapshot.docs) {
              valueBatch.update(valueDoc.reference, {'value1': '0'});
            }

            return valueBatch.commit();
          });
        });
      }).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Value 1 cleared for all products'),
          duration: Duration(seconds: 2),
        ));
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to clear value 1: $error'),
          duration: const Duration(seconds: 2),
        ));
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Incorrect PIN'),
        duration: Duration(seconds: 2),
      ));
    }
  }
}