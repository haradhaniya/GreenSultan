import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import '../models/subcategoryModel.dart';

final subcategoryProvider = StateNotifierProvider<SubcategoryNotifier, List<Subcategory>>((ref) {
  return SubcategoryNotifier();
});

class SubcategoryNotifier extends StateNotifier<List<Subcategory>> {
  SubcategoryNotifier() : super([]) {
    loadSubcategories();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> loadSubcategories() async {
    try {
      final QuerySnapshot subcategorySnapshot = await _firestore.collection('subcategories').get();
      
      final subcategories = subcategorySnapshot.docs.map((doc) {
        return Subcategory.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
      
      state = subcategories;
    } catch (e) {
      debugPrint('Error loading subcategories: $e');
    }
  }

  Future<List<Subcategory>> getSubcategoriesByCategory(String categoryId) async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection('subcategories')
          .where('categoryId', isEqualTo: categoryId)
          .get();
      
      return snapshot.docs.map((doc) {
        return Subcategory.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      debugPrint('Error getting subcategories by category: $e');
      return [];
    }
  }

  Future<String?> uploadImage(File imageFile) async {
    try {
      final String fileName = path.basename(imageFile.path);
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final Reference ref = _storage.ref().child('subcategories').child('${timestamp}_$fileName');
      
      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<bool> addSubcategory({
    required String name,
    required String categoryId,
    required String imageUrl,
  }) async {
    try {
      final subcategoryData = {
        'name': name,
        'categoryId': categoryId,
        'imageUrl': imageUrl,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final DocumentReference docRef = await _firestore.collection('subcategories').add(subcategoryData);
      
      final newSubcategory = Subcategory(
        id: docRef.id,
        name: name,
        categoryId: categoryId,
        imageUrl: imageUrl,
        isActive: true,
        createdAt: DateTime.now(),
      );

      state = [...state, newSubcategory];
      return true;
    } catch (e) {
      debugPrint('Error adding subcategory: $e');
      return false;
    }
  }

  Future<bool> updateSubcategory(Subcategory subcategory) async {
    try {
      await _firestore.collection('subcategories').doc(subcategory.id).update(subcategory.toMap());
      
      state = state.map((s) => s.id == subcategory.id ? subcategory : s).toList();
      return true;
    } catch (e) {
      debugPrint('Error updating subcategory: $e');
      return false;
    }
  }

  Future<bool> deleteSubcategory(String subcategoryId) async {
    try {
      await _firestore.collection('subcategories').doc(subcategoryId).delete();
      
      state = state.where((s) => s.id != subcategoryId).toList();
      return true;
    } catch (e) {
      debugPrint('Error deleting subcategory: $e');
      return false;
    }
  }

  Future<bool> toggleSubcategoryStatus(String subcategoryId, bool isActive) async {
    try {
      await _firestore.collection('subcategories').doc(subcategoryId).update({
        'isActive': isActive,
      });
      
      state = state.map((s) {
        if (s.id == subcategoryId) {
          return Subcategory(
            id: s.id,
            name: s.name,
            categoryId: s.categoryId,
            imageUrl: s.imageUrl,
            isActive: isActive,
            createdAt: s.createdAt,
          );
        }
        return s;
      }).toList();
      
      return true;
    } catch (e) {
      debugPrint('Error toggling subcategory status: $e');
      return false;
    }
  }
} 