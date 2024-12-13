import 'package:flutter/material.dart';
import 'package:green_sultan/Provider/kitchen_item_provider.dart';

class KitchenViewModel extends ChangeNotifier {
  final KitchenRepository _repository = KitchenRepository();
  Map<String, List<Map<String, dynamic>>> categoryProducts = {};
  Map<String, List<double>> categoryQuantities = {};
  Map<String, String> categoryImageUrl = {};
  String selectedCategory = '';
  bool isLoading = false;
  Map<String, dynamic>? selectedProduct; // Track the selected product

  Future<void> fetchCategories() async {
    isLoading = true;
    notifyListeners();

    try {
      // Fetch categories and products
      categoryProducts = await _repository.fetchCategories(); // Correct type
      categoryImageUrl = await _repository.fetchCategoryImages();
      selectedCategory = categoryProducts.keys.first;

      // Initialize quantities
      categoryProducts.forEach((category, products) {
        categoryQuantities[category] =
            List<double>.filled(products.length, 0.0);
      });
    } catch (error) {
      debugPrint("Error: $error");
      // Show a user-friendly error message
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setCategoryImages(Map<String, String> images) {
    categoryImageUrl = images;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    selectedCategory = category;
    notifyListeners();
  }

  void updateQuantity(String category, int index, double newQuantity) {
    categoryQuantities[category]![index] = newQuantity;
    notifyListeners();
  }

  void setSelectedProduct(Map<String, dynamic> product) {
    selectedProduct = product;
    notifyListeners();
  }

  void updateProduct(Map<String, dynamic> updatedProduct) {
    if (selectedProduct == null) return;

    final category = selectedCategory;
    final products = categoryProducts[category];
    if (products == null) return;

    final index = products.indexWhere((p) => p['id'] == selectedProduct!['id']);
    if (index == -1) return;

    products[index] = updatedProduct;
    categoryProducts[category] = products;
    notifyListeners();
  }

  void deleteProduct(Map<String, dynamic> product) {
    final category = selectedCategory;
    final products = categoryProducts[category];
    if (products == null) return;

    final index = products.indexWhere((p) => p['id'] == product['id']);
    if (index == -1) return;

    products.removeAt(index);
    categoryProducts[category] = products;
    categoryQuantities[category]?.removeAt(index);
    notifyListeners();
  }

  void addProduct(Map<String, dynamic> newProduct) {
    final category = selectedCategory;
    final products = categoryProducts[category];
    if (products == null) return;

    products.add(newProduct);
    categoryProducts[category] = products;
    categoryQuantities[category]
        ?.add(0.0); // Initialize quantity for the new product
    notifyListeners();
  }
}
