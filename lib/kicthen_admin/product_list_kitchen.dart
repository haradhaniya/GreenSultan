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

  const ProductDisplayScreen({
    super.key,
    required this.categoryId,
    required this.subcategoryId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCity = ref.watch(cityProvider) ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text("Products")),
      body: selectedCity.isEmpty
          ? const Center(child: Text('Please select a city first'))
          : _buildProductList(selectedCity),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToProductForm(context, selectedCity),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: SizedBox(height: 56.0),
      ),
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
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No products available.'));
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
            childAspectRatio: 1.5, // Adjusted for better image display
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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductForm(
          categoryId: categoryId,
          subCategoryId: subcategoryId,
        ),
      ),
    );
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
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showImageGallery(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductImageGallery(),
              const SizedBox(height: 8),
              _buildProductName(),
              const SizedBox(height: 4),
              _buildProductDescription(),
              const SizedBox(height: 8),
              ..._buildSizesAndPrices(),
              const Spacer(),
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
            fit: BoxFit.cover,
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
    return product.sizesAndPrices
        .map((sizePrice) => Padding(
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
            ))
        .toList();
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