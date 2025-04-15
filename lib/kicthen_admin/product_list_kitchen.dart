import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_sultan/models/productModel.dart';
import 'package:green_sultan/kicthen_admin/edit_product.dart';
import 'package:green_sultan/provider/city_provider.dart';
import '../../forms/productForm.dart';

class ProductDisplayScreen extends ConsumerWidget {
  final String categoryId;
  final String subcategoryId;
  final String selectedCity;

  const ProductDisplayScreen({
    super.key,
    required this.categoryId,
    required this.subcategoryId,
    required this.selectedCity,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Products in ${subcategoryId}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 28),
            onPressed: () => _navigateToProductForm(context, selectedCity),
            tooltip: 'Add New Product',
          ),
        ],
      ),
      body: selectedCity.isEmpty
          ? const Center(child: Text('Please select a city first'))
          : _buildProductList(selectedCity),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToProductForm(context, selectedCity),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildProductList(String selectedCity) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Cities')
          .doc(selectedCity)
          .collection('categories')
          .doc(categoryId)
          .collection('subcategory')
          .doc(subcategoryId)
          .collection('products')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _navigateToProductForm(context, selectedCity),
                  child: const Text('Add First Product'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No products available in this subcategory.'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _navigateToProductForm(context, selectedCity),
                  child: const Text('Add First Product'),
                ),
              ],
            ),
          );
        }

        final products = snapshot.data!.docs
            .map((doc) => Product.fromFirestore(doc))
            .toList();

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2, // Adjusted for better image display
          ),
          itemCount: products.length,
          itemBuilder: (context, index) => ProductItemCard(
            product: products[index],
            categoryId: categoryId,
            subcategoryId: subcategoryId,
          ),
        );
      },
    );
  }

  void _navigateToProductForm(BuildContext context, String selectedCity) {
    if (selectedCity.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a city first')),
      );
      return;
    }

    // Display a loading indicator while navigation is being prepared
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preparing product form...'),
        duration: Duration(seconds: 1),
      ),
    );

    // Verify subcategory exists
    FirebaseFirestore.instance
        .collection('Cities')
        .doc(selectedCity)
        .collection('categories')
        .doc(categoryId)
        .collection('subcategory')
        .doc(subcategoryId)
        .get()
        .then((docSnapshot) {
      if (docSnapshot.exists) {
        // Create products collection if it doesn't exist
        final productsRef = docSnapshot.reference.collection('products');
        productsRef.doc('temp').set({'temp': true}).then((_) {
          productsRef.doc('temp').delete().then((_) {
            // Now navigate to add product form
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductForm(
                  categoryId: categoryId,
                  subCategoryId: subcategoryId,
                  selectedCity: selectedCity,
                ),
              ),
            );
          });
        });
      } else {
        // Show error if subcategory doesn't exist
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subcategory not found. Please try again.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }).catchError((error) {
      // Show error if Firestore operation fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accessing subcategory: $error'),
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }
}

class ProductItemCard extends ConsumerWidget {
  final Product product;
  final String categoryId;
  final String subcategoryId;

  const ProductItemCard({
    super.key,
    required this.product,
    required this.categoryId,
    required this.subcategoryId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
  elevation: 4,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
  child: SingleChildScrollView(
  child: Padding(
    padding: const EdgeInsets.all(8.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProductImageGallery(),
        const SizedBox(height: 5),
        _buildProductName(),
        const SizedBox(height: 2),
        _buildProductDescription(),
        const SizedBox(height: 2),
        ..._buildSizesAndPrices(),
        const SizedBox(height: 8),
        _buildActionButtons(context, ref),
      ],
    ),
  ),
),

);


  }

  Widget _buildProductImageGallery() {
    // Show first image as main image, with indicator for more images
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            product.images.isNotEmpty ? product.images[0] : '',
            width: double.infinity,
            height: 120,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey[200],
              child: const Center(child: Icon(Icons.image, size: 50)),
            ),
          ),
        ),
        if (product.images.length > 1)
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+${product.images.length - 1}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProductName() {
    return Text(
      product.name,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildProductDescription() {
    return Text(
      product.description,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 14, color: Colors.grey),
    );
  }

  List<Widget> _buildSizesAndPrices() {
    if (product.sizesAndPrices.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              const Text(
                'Price:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(width: 4),
              Text(
                'Rs.${product.price.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 13,
                    color: Colors.green,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        )
      ];
    }
    
    return product.sizesAndPrices.map((sizePrice) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '${sizePrice.size}:',
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(width: 4),
          Text(
            'Rs.${sizePrice.price.toStringAsFixed(2)}',
            style: const TextStyle(
                fontSize: 13,
                color: Colors.green,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    )).toList();
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildEditButton(context, ref),
        const SizedBox(width: 8),
        _buildDeleteButton(context, ref),
      ],
    );
  }

  Widget _buildEditButton(BuildContext context, WidgetRef ref) {
    return IconButton(
      onPressed: () => _navigateToEditProductScreen(context, ref),
      icon: const Icon(Icons.edit, size: 20),
      color: Colors.blue,
    );
  }

  Widget _buildDeleteButton(BuildContext context, WidgetRef ref) {
    return IconButton(
      onPressed: () => _deleteProduct(context, ref),
      icon: const Icon(Icons.delete, size: 20),
      color: Colors.red,
    );
  }

  Future<void> _deleteProduct(BuildContext context, WidgetRef ref) async {
    final selectedCity = ref.read(cityProvider) ?? '';

    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete ${product.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      await FirebaseFirestore.instance
          .collection('Cities')
          .doc(selectedCity)
          .collection('categories')
          .doc(categoryId)
          .collection('subcategory')
          .doc(subcategoryId)
          .collection('products')
          .doc(product.id)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} deleted successfully')),
      );
    }
  }

  void _navigateToEditProductScreen(BuildContext context, WidgetRef ref) {
    final selectedCity = ref.read(cityProvider) ?? '';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductScreen(
          product: product,
          cityId: selectedCity,
          categoryId: categoryId,
          subcategoryId: subcategoryId,
        ),
      ),
    );
  }

  void _showImageGallery(BuildContext context) {
    if (product.images.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          backgroundColor: Colors.black,
          body: PageView.builder(
            itemCount: product.images.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                panEnabled: true,
                scaleEnabled: true,
                child: Center(
                  child: Image.network(
                    product.images[index],
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image,
                      color: Colors.white,
                      size: 100,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}