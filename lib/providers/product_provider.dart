import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import '../models/productModel.dart';

final productProvider = StateNotifierProvider<ProductNotifier, List<Product>>((ref) {
  return ProductNotifier();
});

class ProductNotifier extends StateNotifier<List<Product>> {
  ProductNotifier() : super([]) {
    loadProducts();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> loadProducts() async {
    try {
      final QuerySnapshot productSnapshot = await _firestore.collection('products').get();
      
      final products = productSnapshot.docs.map((doc) {
        return Product.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
      
      state = products;
    } catch (e) {
      debugPrint('Error loading products: $e');
    }
  }

  Future<List<Product>> getProductsBySubcategory(String subcategoryId) async {
    try {
      final QuerySnapshot productSnapshot = await _firestore
          .collection('products')
          .where('subcategoryId', isEqualTo: subcategoryId)
          .get();
      
      return productSnapshot.docs.map((doc) {
        return Product.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      debugPrint('Error loading products by subcategory: $e');
      return [];
    }
  }

  Future<String?> uploadImage(File imageFile) async {
    try {
      final String fileName = path.basename(imageFile.path);
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final Reference ref = _storage.ref().child('products').child('${timestamp}_$fileName');
      
      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<bool> addProduct({
    required String name,
    required String description,
    required double price,
    required int stock,
    required List<String> images,
    required String categoryId,
    required String subcategoryId,
  }) async {
    try {
      final productData = {
        'name': name,
        'description': description,
        'price': price,
        'stock': stock,
        'images': images,
        'categoryId': categoryId,
        'subcategoryId': subcategoryId,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final DocumentReference docRef = await _firestore.collection('products').add(productData);
      
      final newProduct = Product(
        id: docRef.id,
        name: name,
        description: description,
        price: price,
        stock: stock,
        images: images,
        sizesAndPrices: [],
        categoryId: categoryId,
        subcategoryId: subcategoryId,
        isActive: true,
        createdAt: DateTime.now(),
      );

      state = [...state, newProduct];
      return true;
    } catch (e) {
      debugPrint('Error adding product: $e');
      return false;
    }
  }

  Future<bool> updateProduct(Product product) async {
    try {
      await _firestore.collection('products').doc(product.id).update(product.toMap());
      
      state = state.map((p) => p.id == product.id ? product : p).toList();
      return true;
    } catch (e) {
      debugPrint('Error updating product: $e');
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).delete();
      
      state = state.where((p) => p.id != productId).toList();
      return true;
    } catch (e) {
      debugPrint('Error deleting product: $e');
      return false;
    }
  }

  Future<bool> toggleProductStatus(String productId, bool isActive) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'isActive': isActive,
      });
      
      state = state.map((p) {
        if (p.id == productId) {
          return Product(
            id: p.id,
            name: p.name,
            description: p.description,
            price: p.price,
            stock: p.stock,
            images: p.images,
            sizesAndPrices: p.sizesAndPrices,
            categoryId: p.categoryId,
            subcategoryId: p.subcategoryId,
            isActive: isActive,
            createdAt: p.createdAt,
          );
        }
        return p;
      }).toList();
      
      return true;
    } catch (e) {
      debugPrint('Error toggling product status: $e');
      return false;
    }
  }
} 