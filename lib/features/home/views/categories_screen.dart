import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_sultan/features/home/views/category_card.dart';
import 'package:green_sultan/features/home/views/sub_category_screen.dart';
import 'package:green_sultan/forms/category_form.dart';

class CategoriesScreen extends ConsumerWidget {
  final String selectedCity;
  
  const CategoriesScreen({
    super.key,
    required this.selectedCity,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Categories", style: TextStyle(fontSize: 20)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Cities')
            .doc(selectedCity)
            .collection('categories')
            .where('isActive', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No categories found'));
          }

          var categories = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              var categoryDoc = categories[index];
              var categoryData = categoryDoc.data() as Map<String, dynamic>;
              String name = categoryData['name'] ?? 'Unnamed';
              String imageUrl = categoryData['imageUrl'] ?? '';

              return CategoryCard(
                name: name,
                imageUrl: imageUrl,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SubcategorySelectionScreen(
                        categoryId: categoryDoc.id,
                        selectedCity: selectedCity,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategoryScreen(
                selectedCity: selectedCity,
              ),
            ),
          );
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 6.0,
      ),
    );
  }
}
