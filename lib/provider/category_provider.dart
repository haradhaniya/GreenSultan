import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import '../models/categoryModel.dart';

// Provide Firebase Firestore instance
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