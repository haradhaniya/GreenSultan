import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_gallery_image_screen.dart';
import '../services/recipe_service.dart';
import '../models/recipe_model.dart';

class RecipeDetailScreen extends StatelessWidget {
  final String recipeId;
  
  const RecipeDetailScreen({
    Key? key,
    required this.recipeId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<Recipe?>(
        stream: RecipeService.getRecipeById(recipeId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }
          
          if (!snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.not_interested, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Recipe not found',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }
          
          final recipe = snapshot.data!;
          
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // App bar with image
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: Theme.of(context).primaryColor,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    recipe.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 8,
                          color: Colors.black54,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  centerTitle: false,
                  background: Hero(
                    tag: 'gallery_${recipe.id}',
                    child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        recipe.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image, size: 64),
                          );
                        },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[300],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            );
                          },
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                                Colors.black.withOpacity(0.2),
                                Colors.black.withOpacity(0.8),
                            ],
                              stops: const [0.5, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ),
                actions: [
                  if (recipe.recipe.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        tooltip: 'Add Recipe',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddGalleryImageScreen(
                                imageId: recipeId,
                                isAddingRecipe: true,
                                initialCategory: recipe.category,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
              
              // Recipe content
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Category & other metadata
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            recipe.category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Ingredients section
                    if (recipe.ingredients.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.list_alt, 
                            color: Colors.grey, size: 28),
                          const SizedBox(width: 12),
                      const Text(
                        'Ingredients',
                        style: TextStyle(
                              fontSize: 22,
                          fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                        ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: _buildIngredientsList(recipe.ingredients),
                      ),
                      const SizedBox(height: 32),
                    ],
                    
                    // Recipe instructions section
                    if (recipe.recipe.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.menu_book, 
                            color: Colors.grey, size: 28),
                          const SizedBox(width: 12),
                      const Text(
                        'Instructions',
                        style: TextStyle(
                              fontSize: 22,
                          fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                        ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Text(
                          recipe.recipe,
                          style: const TextStyle(fontSize: 16, height: 1.6),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 20),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              const Icon(Icons.edit_note, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              const Text(
                                'No recipe available yet',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('Add Recipe'),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddGalleryImageScreen(
                                        imageId: recipeId,
                                        isAddingRecipe: true,
                                        initialCategory: recipe.category,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildIngredientsList(String ingredientsText) {
    final ingredientsList = ingredientsText.split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();
        
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: ingredientsList.map((ingredient) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, size: 16, color: Colors.green),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ingredient.trim(),
                  style: const TextStyle(fontSize: 16, height: 1.4),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
} 