import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_sultan/models/productModel.dart';

// Provider to fetch products for a specific subcategory
final productsProvider = StreamProvider.family<List<Product>, (String, String, String)>((ref, params) {
  final cityId = params.$1;
  final categoryId = params.$2;
  final subcategoryId = params.$3;
  final firestore = FirebaseFirestore.instance;

  if (cityId.isEmpty) {
    return Stream.value([]);  // Return empty list if no city is selected
  }

  return firestore
      .collection('Cities')
      .doc(cityId)
      .collection('categories')
      .doc(categoryId)
      .collection('subcategory')
      .doc(subcategoryId)
      .collection('products')
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
      });
}); 