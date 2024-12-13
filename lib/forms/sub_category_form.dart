import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_sultan/forms/productForm.dart';
import 'package:green_sultan/models/subcategoryModel.dart';
import 'package:green_sultan/provider/category_provider.dart';
import 'package:green_sultan/provider/sub_category_provider.dart';

class SubcategoryScreen extends ConsumerWidget {
  final String selectedCategory;
  final String selectedCity; // Added city parameter

  const SubcategoryScreen({
    super.key, 
    required this.selectedCategory,
    required this.selectedCity,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subcategoriesAsync = ref.watch(subcategoryProvider(selectedCategory));
    final TextEditingController subCategoryController = TextEditingController();
    final TextEditingController subCategoryImageController = TextEditingController();
    String? selectedSubcategory;
    bool showSubCategoryTextFields = true;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Subcategory", style: TextStyle(fontSize: 20)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Subcategory', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: subcategoriesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Text('Error: $error'),
                    data: (subcategories) {
                      return DropdownButton<String>(
                        hint: const Text('Select existing Subcategory'),
                        value: selectedSubcategory,
                        isExpanded: true,
                        items: subcategories.map((subcategory) {
                          return DropdownMenuItem<String>(
                            value: subcategory.name,
                            child: Text(subcategory.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          selectedSubcategory = value;
                          subCategoryController.clear();
                          subCategoryImageController.clear();
                          showSubCategoryTextFields = false;
                        },
                      );
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    if (subCategoryController.text.isNotEmpty &&
                        subCategoryImageController.text.isNotEmpty) {
                      await addCategoryToFirestore(
                        selectedCity,
                        selectedCategory,
                        subCategoryController.text,
                        subCategoryImageController.text,
                      );
                      showSubCategoryTextFields = false;
                      subCategoryController.clear();
                      subCategoryImageController.clear();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please fill in both the subcategory name and image URL.')),
                      );
                    }
                  },
                  tooltip: 'Add new Subcategory',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (showSubCategoryTextFields)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: subCategoryController,
                    decoration: const InputDecoration(
                      labelText: 'Or add new Subcategory',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: subCategoryImageController,
                    decoration: const InputDecoration(
                      labelText: 'Image URL',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (selectedSubcategory != null ||
                    subCategoryController.text.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductForm(
                        categoryId: selectedCategory,
                        subCategoryId: selectedSubcategory ?? subCategoryController.text,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please select or enter a subcategory.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
              ),
              child: Text("Next", style: Theme.of(context).textTheme.labelLarge),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> addCategoryToFirestore(
    String cityId,
    String categoryId,
    String subcategoryName,
    String imageUrl,
  ) async {
    await FirebaseFirestore.instance
        .collection('Cities')
        .doc(cityId)
        .collection('categories')
        .doc(categoryId)
        .collection('subcategory')
        .doc(subcategoryName)
        .set({
          'name': subcategoryName,
          'imageUrl': imageUrl,
        });
  }
}