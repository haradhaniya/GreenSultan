import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_sultan/change_veggies_price/plants/plants_card.dart';
import '../../provider/city_provider.dart';

class PlantsListAfterVerification extends ConsumerWidget {
  final bool isPinVerified;
  final String searchQuery;
  final TextEditingController _pinController = TextEditingController();
  final String _correctPin = '786';

  PlantsListAfterVerification({
    super.key,
    required this.isPinVerified,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCity = ref.watch(cityProvider);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Cities')
          .doc(selectedCity)
          .collection('${selectedCity}Plants')
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

        return ListView(
          children: [
            // Displaying filtered products
            ...filteredProducts.map((product) {
              return PlantsCard(
                product: product,
                isPinVerified: isPinVerified,
                index: filteredProducts.indexOf(product) + 1,
              );
            }),
            // Elevated Button to show PIN dialog
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () => _showPinDialog(context, ref),
                child: const Text('Clear Value 1'),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPinDialog(BuildContext context, WidgetRef ref) {
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
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => _verifyPinAndClearValues(context, ref),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void _verifyPinAndClearValues(BuildContext context, WidgetRef ref) {
    if (_pinController.text == _correctPin) {
      _clearValues(context, ref);
    } else {
      _showSnackBar(context, 'Incorrect PIN');
    }
  }

  void _clearValues(BuildContext context, WidgetRef ref) {
    final selectedCity = ref.watch(cityProvider);
    WriteBatch batch = FirebaseFirestore.instance.batch();

    // Clear 'value1' in Veggies collection
    FirebaseFirestore.instance
        .collection('Cities')
        .doc(selectedCity)
        .collection('${selectedCity}Plants')
        .get()
        .then((snapshot) {
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'value1': '0'});
      }

      // Clear 'value1' in veggies_values collection
      return FirebaseFirestore.instance
          .collection('Cities')
          .doc(selectedCity)
          .collection('plants_values')
          .get();
    }).then((valueSnapshot) {
      for (var valueDoc in valueSnapshot.docs) {
        batch.update(valueDoc.reference, {'value1': '0'});
      }
      return batch.commit();
    }).then((_) {
      _showSnackBar(context, 'Value 1 cleared for all products');
      Navigator.of(context).pop(); // Close the dialog
    }).catchError((error) {
      _showSnackBar(context, 'Failed to clear value 1: $error');
    });
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}

