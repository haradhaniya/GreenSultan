import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_sultan/screens/add_gallery_image_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class GalleryManagementScreen extends ConsumerStatefulWidget {
  const GalleryManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<GalleryManagementScreen> createState() => _GalleryManagementScreenState();
}

class _GalleryManagementScreenState extends ConsumerState<GalleryManagementScreen> with SingleTickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser;
  TabController? _tabController;
  String? _selectedCategory;
  
  List<String> categories = [
    'All',
    'ناشتہ',
    'دالیں',
    'مرغی',
    'بچوں کے لیے',
    'مچھلی',
    'سبزیاں',
    'گائے کا گوشت',
    'بکرے کا گوشت',
    'خصوصی عید',
  ];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
    _tabController!.addListener(() {
      if (!_tabController!.indexIsChanging) {
        setState(() {
          _selectedCategory = _tabController!.index == 0 
              ? null 
              : categories[_tabController!.index];
        });
      }
    });
  }
  
  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _deleteImage(String imageId) async {
    try {
      await FirebaseFirestore.instance.collection('gallery').doc(imageId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting recipe: $e')),
      );
    }
  }

  Future<void> _showDeleteConfirmationDialog(String imageId, String imageTitle) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete "$imageTitle"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteImage(imageId);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
  
  void _editRecipe(String recipeId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddGalleryImageScreen(
          imageId: recipeId,
          isAddingRecipe: false,
        ),
      ),
    ).then((_) {
      setState(() {});
    });
  }
  
  void _addRecipeToImage(String recipeId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddGalleryImageScreen(
          imageId: recipeId,
          isAddingRecipe: true,
        ),
      ),
    ).then((_) {
      setState(() {});
    });
  }
  
  void _viewRecipeDetails(Map<String, dynamic> recipeData) {
    final hasRecipe = recipeData['recipe'] != null && 
                     recipeData['recipe'].toString().isNotEmpty;
    
    final hasIngredients = recipeData['ingredients'] != null && 
                          recipeData['ingredients'].toString().isNotEmpty;
    
    if (!hasRecipe && !hasIngredients) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No recipe information available')),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image at top
              if (recipeData['imageUrl'] != null)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: recipeData['imageUrl'],
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 180,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.error, size: 40),
                    ),
                  ),
                ),
              
              // Recipe content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        recipeData['title'] ?? 'Recipe',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      if (recipeData['description'] != null && 
                          recipeData['description'].toString().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          recipeData['description'],
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 16),
                      
                      // Ingredients
                      if (hasIngredients) ...[
                        const Text(
                          'Ingredients',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          recipeData['ingredients'],
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Recipe instructions
                      if (hasRecipe) ...[
                        const Text(
                          'Instructions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          recipeData['recipe'],
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Close button
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Gallery'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: categories.map((category) => Tab(text: category)).toList(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddGalleryImageScreen(
                    initialCategory: _selectedCategory,
                  ),
                ),
              ).then((_) {
                // Refresh when returning from add screen
                setState(() {});
              });
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: categories.map((category) {
          return _buildRecipeGrid(category == 'All' ? null : category);
        }).toList(),
      ),
    );
  }
  
  Widget _buildRecipeGrid(String? category) {
    return StreamBuilder<QuerySnapshot>(
      stream: category == null
          ? FirebaseFirestore.instance
              .collection('gallery')
              .orderBy('timestamp', descending: true)
              .snapshots()
          : FirebaseFirestore.instance
              .collection('gallery')
              .where('category', isEqualTo: category)
              .orderBy('timestamp', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.food_bank, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  category == null
                      ? 'No recipes found'
                      : 'No recipes in $category category',
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Tap the + button to add a recipe',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        
        final recipes = snapshot.data!.docs;
        
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: recipes.length,
          itemBuilder: (context, index) {
            final recipe = recipes[index];
            final recipeData = recipe.data() as Map<String, dynamic>;
            final recipeId = recipe.id;
            
            final hasRecipe = recipeData['recipe'] != null && 
                             recipeData['recipe'].toString().isNotEmpty;
                             
            final hasIngredients = recipeData['ingredients'] != null && 
                                  recipeData['ingredients'].toString().isNotEmpty;
            
            return Card(
              clipBehavior: Clip.antiAliasWithSaveLayer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: InkWell(
                onTap: () => _viewRecipeDetails(recipeData),
                child: Stack(
                  children: [
                    // Image
                    Positioned.fill(
                      child: recipeData['imageUrl'] != null
                          ? CachedNetworkImage(
                              imageUrl: recipeData['imageUrl'],
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, error, stackTrace) => 
                                Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.error, size: 40),
                                ),
                            )
                          : Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image, size: 40),
                            ),
                    ),
                    
                    // Gradient overlay for text visibility
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.8),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recipeData['title'] ?? 'Untitled',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (recipeData['category'] != null)
                              Text(
                                recipeData['category'],
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            
                            // Recipe status indicator
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  hasRecipe && hasIngredients 
                                      ? Icons.check_circle 
                                      : Icons.info_outline,
                                  color: hasRecipe && hasIngredients
                                      ? Colors.green
                                      : Colors.amber,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  hasRecipe && hasIngredients
                                      ? 'Complete'
                                      : 'Needs details',
                                  style: TextStyle(
                                    color: hasRecipe && hasIngredients
                                        ? Colors.green
                                        : Colors.amber,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Action buttons
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Row(
                        children: [
                          // Edit button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _editRecipe(recipeId),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(12),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.edit, 
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          // Delete button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showDeleteConfirmationDialog(
                                recipeId, 
                                recipeData['title'] ?? 'this recipe'
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.7),
                                ),
                                child: const Icon(
                                  Icons.delete, 
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}