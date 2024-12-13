import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_sultan/models/categoryModel.dart';

// Provider to access Firestore instance
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// Provider to fetch categories for a specific city
final categoriesProvider = StreamProvider.family<List<Category>, String>((ref, cityId) {
  final firestore = ref.watch(firestoreProvider);

  return firestore
      .collection('Cities')
      .doc(cityId)
      .collection('categories')
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList();
      });
});