import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:green_sultan/screens/recipe_management_screen.dart';

class RecipeCategoriesScreen extends StatelessWidget {
  const RecipeCategoriesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Define categories with colors that match app theme
    final List<Map<String, dynamic>> categories = [
      {
        'name': 'ناشتہ', // Breakfast
        'icon': Icons.free_breakfast, // Better symbol for breakfast (cup/mug)
        'color': Theme.of(context).primaryColor,
      },
      {
        'name': 'دالیں', // Lentils
        'icon': Icons.rice_bowl, // Better for grains/dal type
        'color': Theme.of(context).primaryColor,
      },
      {
        'name': 'مرغی', // Chicken
        'icon': Icons.set_meal, // Represents a plated meal, better than kebab
        'color': Theme.of(context).primaryColor,
      },
      {
        'name': 'بچوں کے لیے', // Kids
        'icon': Icons.toys, // Represents kids or child-friendly
        'color': Theme.of(context).primaryColor,
      },
      {
        'name': 'مچھلی', // Fish
        'icon': Icons.lunch_dining, // Suggests a meal, closer to fish concept
        'color': Theme.of(context).primaryColor,
      },
      {
        'name': 'سبزیاں', // Vegetables
        'icon': Icons.eco, // Represents greenery/natural, suits vegetables
        'color': Theme.of(context).primaryColor,
      },
      {
        'name': 'گائے کا گوشت', // Beef
        'icon': Icons.dining, // General food, good fallback for meat
        'color': Theme.of(context).primaryColor,
      },
      {
        'name': 'بکرے کا گوشت', // Mutton
        'icon': Icons.restaurant_menu, // Similar to beef, usable as general food
        'color': Theme.of(context).primaryColor,
      },
      {
        'name': 'خصوصی عید', // Special Eid
        'icon': Icons.star, // For highlighting special/important events
        'color': Theme.of(context).primaryColor,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Categories',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            )),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header
          Container(
            color: Theme.of(context).primaryColor,
            padding:
                const EdgeInsets.only(bottom: 20.0, left: 16.0, right: 16.0),
            child: const Text(
              'Browse Recipe Categories',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Categories grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return _buildCategoryCard(
                  context: context,
                  categoryName: category['name'],
                  icon: category['icon'],
                  color: category['color'],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddRecipe(context),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryCard({
    required BuildContext context,
    required String categoryName,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () => _navigateToCategory(context, categoryName),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              left: BorderSide(color: color, width: 4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 45,
                  color: color,
                ),
                const SizedBox(height: 16),
                Text(
                  categoryName,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Tap to view',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToCategory(BuildContext context, String categoryName) {
    // Navigate to RecipeManagementScreen with category filter
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeManagementScreen(
          initialCategory: categoryName,
        ),
      ),
    );
  }
  
  void _navigateToAddRecipe(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RecipeManagementScreen(),
      ),
    );
  }
} 