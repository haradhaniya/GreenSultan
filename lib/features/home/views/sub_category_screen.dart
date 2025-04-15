import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:green_sultan/kicthen_admin/product_list_kitchen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_sultan/provider/selected_city_provider.dart';
import 'package:green_sultan/forms/productForm.dart';

class SubcategorySelectionScreen extends ConsumerWidget {
  final String categoryId;
  final String selectedCity;

  const SubcategorySelectionScreen({
    super.key, 
    required this.categoryId,
    required this.selectedCity,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Subcategory"),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Navigate to add product directly
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductForm(
                    categoryId: categoryId,
                    subCategoryId: "Other", // Default subcategory
                    selectedCity: selectedCity,
                  ),
                ),
              );
            },
            tooltip: 'Add Product',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Show subcategory creation dialog
          _showAddSubcategoryDialog(context, selectedCity, categoryId);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Subcategory'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Cities')
            .doc(selectedCity)
            .collection('categories')
            .doc(categoryId)
            .collection('subcategory')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No subcategories found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var subcategoryDoc = snapshot.data!.docs[index];
              String subcategoryId = subcategoryDoc.id;
              var data = subcategoryDoc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: data['imageUrl'] != null &&
                            data['imageUrl'].isNotEmpty
                        ? Image.network(
                            data['imageUrl'],
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.image_not_supported,
                              color: Colors.grey.shade600,
                            ),
                          )
                        : Icon(
                            Icons.image,
                            size: 50,
                            color: Colors.grey.shade600,
                          ),
                  ),
                  title: Text(
                    data['name'] ?? 'Unnamed Subcategory',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDisplayScreen(
                          categoryId: categoryId,
                          subcategoryId: subcategoryId,
                          selectedCity: selectedCity,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Add a helper method to show the add subcategory dialog
void _showAddSubcategoryDialog(BuildContext context, String selectedCity, String categoryId) {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController imageUrlController = TextEditingController();
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Add New Subcategory'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Subcategory Name',
                hintText: 'Enter name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: imageUrlController,
              decoration: const InputDecoration(
                labelText: 'Image URL',
                hintText: 'Enter image URL',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (nameController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a subcategory name')),
              );
              return;
            }
            
            // Close dialog first
            Navigator.of(context).pop();
            
            // Show loading indicator
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Creating subcategory...'),
                duration: Duration(seconds: 1),
              ),
            );
            
            try {
              // Reference to the subcategory collection - use auto-generated ID instead of name
              final subcategoryCollectionRef = FirebaseFirestore.instance
                  .collection('Cities')
                  .doc(selectedCity)
                  .collection('categories')
                  .doc(categoryId)
                  .collection('subcategory');
              
              // Create document with auto-generated ID
              final newSubcategoryDoc = await subcategoryCollectionRef.add({
                'name': nameController.text,
                'imageUrl': imageUrlController.text.isNotEmpty 
                  ? imageUrlController.text 
                  : 'https://via.placeholder.com/150',
                'createdAt': FieldValue.serverTimestamp(), // Add timestamp for sorting if needed
              });
              
              // Create an empty products collection
              final placeholderRef = newSubcategoryDoc.collection('products').doc('placeholder');
              await placeholderRef.set({'placeholder': true});
              await placeholderRef.delete();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Subcategory ${nameController.text} created successfully')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error creating subcategory: $e')),
              );
            }
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );
}
