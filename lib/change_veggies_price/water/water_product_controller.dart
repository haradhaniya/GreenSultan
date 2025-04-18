import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final waterProductControllerProvider = Provider.autoDispose
    .family<WaterProductController, String>((ref, city) {
  return WaterProductController(city);
});

class WaterProductController {
  final String city;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  WaterProductController(this.city);

  Stream<QuerySnapshot> getWaterProducts() {
    return _firestore
        .collection('Cities')
        .doc(city)
        .collection('${city}Water')
        .orderBy('name')
        .snapshots();
  }

  Stream<List<QueryDocumentSnapshot>> searchWaterProducts(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _firestore
        .collection('Cities')
        .doc(city)
        .collection('${city}Water')
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.where((doc) {
        final name = (doc['name'] as String?)?.toLowerCase() ?? '';
        return name.contains(lowercaseQuery);
      }).toList();
    });
  }


  Future<void> resetAllValues() async {
    // Get all water products
    final products = await _firestore
        .collection('Cities')
        .doc(city)
        .collection('${city}Water')
        .get();

    // Create a batch operation for efficiency
    final batch = _firestore.batch();

    // Reset values for each product
    for (final product in products.docs) {
      final ref = _firestore
          .collection('Cities')
          .doc(city)
          .collection('water_values')
          .doc(product.id);

      batch.set(ref, {
        'value1': '0',
        'value2': '0',
        'value3': '0',
      });

      // Also reset the price in the main collection
      final productRef = _firestore
          .collection('Cities')
          .doc(city)
          .collection('${city}Water')
          .doc(product.id);

      batch.update(productRef, {'price': '0'});
    }

    // Commit the batch
    return batch.commit();
  }

  Future<void> adjustAllPrices(double percentage) async {
    // Get all water products
    final products = await _firestore
        .collection('Cities')
        .doc(city)
        .collection('${city}Water')
        .get();

    // Get all water values
    final valuesQuery = await _firestore
        .collection('Cities')
        .doc(city)
        .collection('water_values')
        .get();

    // Create a map of product ID to values
    final valuesMap = <String, Map<String, dynamic>>{};
    for (final doc in valuesQuery.docs) {
      valuesMap[doc.id] = doc.data();
    }

    // Create a batch operation for efficiency
    final batch = _firestore.batch();

    // Adjust values and price for each product
    for (final product in products.docs) {
      final productId = product.id;
      final values = valuesMap[productId];

      if (values != null) {
        final value1 = double.tryParse(values['value1'] ?? '0') ?? 0;
        final value2 = double.tryParse(values['value2'] ?? '0') ?? 0;
        final value3 = double.tryParse(values['value3'] ?? '0') ?? 0;

        // Apply the percentage adjustment to the values
        final newValue1 = (value1 * (1 + percentage / 100)).toStringAsFixed(2);
        final newValue2 = (value2 * (1 + percentage / 100)).toStringAsFixed(2);
        final newValue3 = (value3 * (1 + percentage / 100)).toStringAsFixed(2);

        // Update the values
        final valuesRef = _firestore
            .collection('Cities')
            .doc(city)
            .collection('water_values')
            .doc(productId);

        batch.update(valuesRef, {
          'value1': newValue1,
          'value2': newValue2,
          'value3': newValue3,
        });

        // Calculate the new price
        final newPrice = (double.parse(newValue1) + 
                          double.parse(newValue2) + 
                          double.parse(newValue3))
                          .round()
                          .toString();

        // Update the price in the main collection
        final productRef = _firestore
            .collection('Cities')
            .doc(city)
            .collection('${city}Water')
            .doc(productId);

        batch.update(productRef, {'price': newPrice});
      }
    }

    // Commit the batch
    return batch.commit();
  }
} 