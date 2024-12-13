import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_sultan/forms/sub_category_form.dart';
import 'package:green_sultan/provider/category_provider.dart';


class CategoryScreen extends ConsumerWidget {
  final String selectedCity;

  const CategoryScreen({
    Key? key,
    required this.selectedCity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider(selectedCity));
    final TextEditingController categoryController = TextEditingController();
    final TextEditingController categoryImageController = TextEditingController();
    String? selectedCategory;
    bool showCategoryTextFields = true;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Category", style: TextStyle(fontSize: 20)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: categoriesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Text('Error: $error'),
                    data: (categories) {
                      return DropdownButton<String>(
                        hint: const Text('Select existing Category'),
                        value: selectedCategory,
                        isExpanded: true,
                        items: categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category.name,
                            child: Text(category.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          selectedCategory = value;
                          categoryController.clear();
                          categoryImageController.clear();
                          showCategoryTextFields = false;
                        },
                      );
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    if (categoryController.text.isNotEmpty &&
                        categoryImageController.text.isNotEmpty) {
                      await addCategoryToFirestore(
                        selectedCity,
                        categoryController.text,
                        categoryImageController.text,
                      );
                      showCategoryTextFields = false;
                      categoryController.clear();
                      categoryImageController.clear();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill in both the category name and image URL.')),
                      );
                    }
                  },
                  tooltip: 'Add new Category',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (showCategoryTextFields)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Or add new Category',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: categoryImageController,
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
                if (selectedCategory != null ||
                    categoryController.text.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SubcategoryScreen(
                        selectedCategory: selectedCategory ?? categoryController.text,
                        selectedCity: selectedCity,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select or enter a category.')),
                  );
                }
              },
              child: Text("Next", style: Theme.of(context).textTheme.labelLarge),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> addCategoryToFirestore(
    String cityId,
    String categoryName,
    String imageUrl,
  ) async {
    await FirebaseFirestore.instance
        .collection('Cities')
        .doc(cityId)
        .collection('categories')
        .doc(categoryName)
        .set({
          'name': categoryName,
          'imageUrl': imageUrl,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }
}