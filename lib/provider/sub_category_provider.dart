import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_sultan/provider/category_provider.dart';
import 'package:green_sultan/models/subcategoryModel.dart';
import 'package:green_sultan/provider/selected_city_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Provider to fetch subcategories for a specific category
final subcategoriesProvider = StreamProvider.family<List<Subcategory>, (String, String)>((ref, params) {
  final cityId = params.$1;
  final categoryId = params.$2;
  final firestore = ref.watch(firestoreProvider);

  if (cityId.isEmpty) {
    return Stream.value([]);  // Return empty list if no city is selected
  }

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

