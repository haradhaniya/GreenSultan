import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_sultan/screens/add_recipe_screen.dart';

class RecipeManagementScreen extends ConsumerStatefulWidget {
  final String? initialCategory;
  
  const RecipeManagementScreen({Key? key, this.initialCategory}) : super(key: key);

  @override
  ConsumerState<RecipeManagementScreen> createState() => _RecipeManagementScreenState();
}

class _RecipeManagementScreenState extends ConsumerState<RecipeManagementScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;
  final user = FirebaseAuth.instance.currentUser;
  late TabController _tabController;
  
  // Define categories
  final List<String> _categories = [
    'All',
    'ناشتہ',          // Breakfast
    'دالیں',          // Lentils
    'مرغی',           // Chicken
    'بچوں کے لیے',    // Kids
    'مچھلی',          // Fish
    'سبزیاں',         // Vegetables
    'گائے کا گوشت',    // Beef
    'بکرے کا گوشت',    // Mutton
    'خصوصی عید'       // Special Eid
  ];
  
  @override
  void initState() {
    super.initState();
    // Initialize TabController and select the initial tab if a category is specified
    _tabController = TabController(length: _categories.length, vsync: this);
    
    // If an initial category is provided, select that tab
    if (widget.initialCategory != null) {
      int categoryIndex = _categories.indexOf(widget.initialCategory!);
      if (categoryIndex > 0) { // Valid category found
        _tabController.animateTo(categoryIndex);
      }
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _deleteRecipe(String recipeId) async {
    try {
      await FirebaseFirestore.instance.collection('gallery').doc(recipeId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting recipe: $e')),
      );
    }
  }

  Future<void> _showDeleteConfirmationDialog(String recipeId, String recipeTitle) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete "$recipeTitle"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteRecipe(recipeId);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToEditRecipe(String recipeId, Map<String, dynamic> recipeData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddRecipeScreen(
          isEditing: true,
          recipeId: recipeId,
          recipeData: recipeData,
        ),
      ),
    ).then((_) {
      // Refresh the list when coming back from edit screen
      setState(() {});
    });
  }
  
  void _addNewRecipe([String? category]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddRecipeScreen(
          initialCategory: category != 'All' ? category : null,
        ),
      ),
    ).then((_) {
      // Refresh when returning from add screen
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get current user ID for filtering recipes (if needed)
    final userId = user?.uid;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Book'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addNewRecipe(_categories[_tabController.index]),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _categories.map((category) => Tab(text: category)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _categories.map((category) => _buildRecipeList(category)).toList(),
      ),
    );
  }
  
  Widget _buildRecipeList(String category) {
    // Get current user ID for filtering recipes (if needed)
    final userId = user?.uid;
    
    return StreamBuilder<QuerySnapshot>(
      stream: category == 'All'
          ? FirebaseFirestore.instance
              .collection('gallery')
              .orderBy('timestamp', descending: true)
              .snapshots()
          : FirebaseFirestore.instance
              .collection('gallery')
              .where('category', isEqualTo: category)
              .snapshots(), // Removed the orderBy to avoid composite index requirement
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          // Display a friendlier error message with instructions to create the index
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.orange),
                const SizedBox(height: 16),
                const Text(
                  'Database index needs to be created',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    'This is a one-time setup. Please contact the administrator to create the required database index.',
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Refresh to try again
                    setState(() {});
                  },
                  child: const Text('Refresh'),
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
                Icon(Icons.restaurant_menu, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No ${category != 'All' ? '$category ' : ''}recipes found',
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text('Add ${category != 'All' ? '$category ' : ''}Recipe'),
                  onPressed: () => _addNewRecipe(category != 'All' ? category : null),
                ),
              ],
            ),
          );
        }
        
        final recipes = snapshot.data!.docs;
        
        // Sort manually since we removed the orderBy from the query
        if (category != 'All') {
          recipes.sort((a, b) {
            // Get timestamps (or use current time if not available)
            final timestampA = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
            final timestampB = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
            
            if (timestampA == null && timestampB == null) return 0;
            if (timestampA == null) return 1;
            if (timestampB == null) return -1;
            
            // Sort in descending order (newest first)
            return timestampB.compareTo(timestampA);
          });
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: recipes.length,
          itemBuilder: (context, index) {
            final recipe = recipes[index];
            final recipeData = recipe.data() as Map<String, dynamic>;
            final recipeId = recipe.id;
            
            // Get recipe user ID - handle null case for backward compatibility
            final recipeUserId = recipeData['userId'] as String?;
            
            // Check if current user is the creator of this recipe
            final isOwner = userId != null && recipeUserId != null && recipeUserId == userId;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recipe image
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: recipeData['imageUrl'] != null
                        ? Image.network(
                            recipeData['imageUrl'],
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => 
                              Container(
                                height: 180,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.error, size: 40),
                              ),
                          )
                        : Container(
                            height: 180,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.restaurant_menu, size: 40),
                          ),
                  ),
                  
                  // Recipe details
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                recipeData['title'] ?? 'Untitled Recipe',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Like count
                            Row(
                              children: [
                                const Icon(Icons.favorite, color: Colors.red, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  '${recipeData['likes'] ?? 0}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Category tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            recipeData['category'] ?? 'Uncategorized',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Author and cooking time
                        Row(
                          children: [
                            const Icon(Icons.person, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              recipeData['author'] ?? 'Unknown',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.access_time, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '${recipeData['cookTime'] ?? 'Unknown'} minutes',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Ingredients preview
                        if (recipeData['ingredients'] != null) ...[
                          const Text(
                            'Ingredients:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            recipeData['ingredients'].toString().split('\n').take(3).join(', ') +
                                (recipeData['ingredients'].toString().split('\n').length > 3
                                    ? '...'
                                    : ''),
                            style: const TextStyle(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        
                        const SizedBox(height: 16),
                        
                        // Action buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Only allow edit/delete for the recipe's creator
                            if (isOwner) ...[
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _navigateToEditRecipe(recipeId, recipeData),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _showDeleteConfirmationDialog(
                                  recipeId,
                                  recipeData['title'] ?? 'this recipe',
                                ),
                              ),
                            ],
                            IconButton(
                              icon: const Icon(Icons.visibility),
                              onPressed: () {
                                // View recipe details
                                // TODO: Implement view recipe screen
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
} 