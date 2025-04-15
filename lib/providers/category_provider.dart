import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import '../models/categoryModel.dart';

final categoryProvider = StateNotifierProvider<CategoryNotifier, List<Category>>((ref) {
  return CategoryNotifier();
});

class CategoryNotifier extends StateNotifier<List<Category>> {
  CategoryNotifier() : super([]) {
    loadCategories();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> loadCategories() async {
    try {
      final QuerySnapshot categorySnapshot = await _firestore.collection('categories').get();
      
      final categories = categorySnapshot.docs.map((doc) {
        return Category.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
      
      state = categories;
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  Future<String?> uploadImage(File imageFile) async {
    try {
      final String fileName = path.basename(imageFile.path);
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final Reference ref = _storage.ref().child('categories').child('${timestamp}_$fileName');
      
      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<bool> addCategory({
    required String name,
    required String imageUrl,
  }) async {
    try {
      final categoryData = {
        'name': name,
        'imageUrl': imageUrl,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final DocumentReference docRef = await _firestore.collection('categories').add(categoryData);
      
      final newCategory = Category(
        id: docRef.id,
        name: name,
        imageUrl: imageUrl,
        isActive: true,
        createdAt: DateTime.now(),
      );

      state = [...state, newCategory];
      return true;
    } catch (e) {
      debugPrint('Error adding category: $e');
      return false;
    }
  }

  Future<bool> updateCategory(Category category) async {
    try {
      await _firestore.collection('categories').doc(category.id).update(category.toMap());
      
      state = state.map((c) => c.id == category.id ? category : c).toList();
      return true;
    } catch (e) {
      debugPrint('Error updating category: $e');
      return false;
    }
  }

  Future<bool> deleteCategory(String categoryId) async {
    try {
      await _firestore.collection('categories').doc(categoryId).delete();
      
      state = state.where((c) => c.id != categoryId).toList();
      return true;
    } catch (e) {
      debugPrint('Error deleting category: $e');
      return false;
    }
  }

  Future<bool> toggleCategoryStatus(String categoryId, bool isActive) async {
    try {
      await _firestore.collection('categories').doc(categoryId).update({
        'isActive': isActive,
      });
      
      state = state.map((c) {
        if (c.id == categoryId) {
          return Category(
            id: c.id,
            name: c.name,
            imageUrl: c.imageUrl,
            isActive: isActive,
            createdAt: c.createdAt,
          );
        }
        return c;
      }).toList();
      
      return true;
    } catch (e) {
      debugPrint('Error toggling category status: $e');
      return false;
    }
  }
} 