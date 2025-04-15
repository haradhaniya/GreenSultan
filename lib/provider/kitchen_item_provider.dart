import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class KitchenRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Future<List<Map<String, dynamic>>> fetchAllProducts() async {
    try {
      // Fetch all categories
      QuerySnapshot categoriesSnapshot =
          await _firestore.collection('categories').get();
      List<Map<String, dynamic>> allProducts = [];

      // Loop through each category
      for (var category in categoriesSnapshot.docs) {
        String categoryName =
            category.id; // Get the category name (document ID)

        // Fetch all subcategories under the current category
        QuerySnapshot subcategoriesSnapshot = await _firestore
            .collection('categories')
            .doc(categoryName)
            .collection('subcategory')
            .get();

        // Loop through each subcategory
        for (var subcategory in subcategoriesSnapshot.docs) {
          String subcategoryName =
              subcategory.id; // Get the subcategory name (document ID)

          // Fetch all products under the current subcategory
          QuerySnapshot productsSnapshot = await _firestore
              .collection('categories')
              .doc(categoryName)
              .collection('subcategory')
              .doc(subcategoryName)
              .collection('products')
              .get();

          // Map products and add category/subcategory info
          var products = productsSnapshot.docs.map((doc) {
            var productData = doc.data() as Map<String, dynamic>;
            productData['category'] = categoryName; // Add category name
            productData['subcategory'] =
                subcategoryName; // Add subcategory name
            return productData;
          }).toList();

          allProducts.addAll(products); // Add products to the main list
        }
      }

      return allProducts;
    } catch (error) {
      debugPrint("Error fetching all products: $error");
      rethrow;
    }
  }

  Future<Map<String, String>> fetchCategoryImages() async {
    try {
      QuerySnapshot categoriesSnapshot =
          await _firestore.collection('categories').get();
      Map<String, String> categoryImages = {};

      for (var categoryDoc in categoriesSnapshot.docs) {
        Map<String, dynamic> categoryData =
            categoryDoc.data() as Map<String, dynamic>;

        String categoryName = categoryDoc.id;
        String categoryImage = categoryData.containsKey('imageUrl')
            ? categoryData['imageUrl']
            : '';

        categoryImages[categoryName] = categoryImage;
      }

      return categoryImages;
    } catch (error) {
      debugPrint("Error fetching category images: $error");
      rethrow;
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> fetchCategories() async {
    try {
      QuerySnapshot categoriesSnapshot =
          await _firestore.collection('categories').get();
      Map<String, List<Map<String, dynamic>>> categories = {};

      for (var categoryDoc in categoriesSnapshot.docs) {
        String categoryName = categoryDoc.id;
        QuerySnapshot subcategoriesSnapshot =
            await categoryDoc.reference.collection('subcategory').get();
        List<Map<String, dynamic>> categoryProductsList = [];

        for (var subcategoryDoc in subcategoriesSnapshot.docs) {
          QuerySnapshot productsSnapshot = await subcategoryDoc.reference
              .collection('products')
              .where('stock', isGreaterThan: 0)
              .get();

          // Convert documents to Map<String, dynamic>
          List<Map<String, dynamic>> products = productsSnapshot.docs
              .map((productDoc) => productDoc.data() as Map<String, dynamic>)
              .toList();

          categoryProductsList.addAll(products);
        }

        categories[categoryName] = categoryProductsList;
      }

      return categories;
    } catch (error) {
      debugPrint("Error fetching categories: $error");
      rethrow;
    }
  }
}
