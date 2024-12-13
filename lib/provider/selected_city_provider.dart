import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CityNotifier2 extends StateNotifier<List<String>> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CityNotifier2() : super([]) {
    fetchCities(); // Ensure cities are fetched when the notifier is initialized
  }

  Future<void> fetchCities() async {
    try {
      final snapshot = await _firestore.collection('Cities').get();
      state = snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint("Error fetching cities: $e");
      state = [];
    }
  }
}

// This provider is used to expose the cities to the widgets
final cityProvider2 = StateNotifierProvider<CityNotifier2, List<String>>((ref) {
  return CityNotifier2();
});
