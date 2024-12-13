import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_sultan/provider/category_provider.dart';
import 'package:green_sultan/models/subcategoryModel.dart';

import 'package:green_sultan/provider/selected_city_provider.dart'; // Assuming selectedCityProvider is defined here

// Provider to fetch subcategories for a specific category
final subcategoryProvider = StreamProvider.family<List<Subcategory>, String>((ref, categoryId) {
  final firestore = ref.watch(firestoreProvider);
  final cityId = ref.watch(selectedCityProvider); // Assuming you have a selectedCityProvider

  return firestore
      .collection('Cities')
      .doc(cityId)
      .collection('categories')
      .doc(categoryId)
      .collection('subcategory')
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) => Subcategory.fromFirestore(doc)).toList();
      });
});

