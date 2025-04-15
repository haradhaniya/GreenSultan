import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_sultan/forms/sub_category_form.dart';
import 'package:green_sultan/models/categoryModel.dart';
import 'package:green_sultan/provider/category_provider.dart';
import 'package:green_sultan/provider/selected_city_provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class CategoryScreen extends ConsumerStatefulWidget {
  final String selectedCity;
  
  const CategoryScreen({Key? key, required this.selectedCity}) : super(key: key);

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  File? _imageFile;
  bool _isUploading = false;
  bool _isProcessing = false;
  Category? _selectedCategory;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;
    
    setState(() {
      _isUploading = true;
    });
    
    try {
      final selectedCity = widget.selectedCity;
      
      final fileName = path.basename(_imageFile!.path);
      final destination = 'categories/$selectedCity/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final storageRef = FirebaseStorage.instance.ref().child(destination);
      
      final task = await storageRef.putFile(_imageFile!);
      final downloadUrl = await task.ref.getDownloadURL();
      
      setState(() {
        _isUploading = false;
      });
      
      return downloadUrl;
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
      return null;
    }
  }

  Future<void> _createCategory() async {
    if (!_formKey.currentState!.validate()) return;
    
    final selectedCity = widget.selectedCity;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await _uploadImage();
        if (imageUrl == null) {
          setState(() {
            _isProcessing = false;
          });
          return;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an image')),
        );
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // Create category document
      final docRef = await FirebaseFirestore.instance
          .collection('Cities')
          .doc(selectedCity)
          .collection('categories')
          .add({
            'name': _nameController.text,
            'imageUrl': imageUrl,
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
          });
      
      // Fetch the newly created category
      final docSnapshot = await docRef.get();
      final newCategory = Category.fromFirestore(docSnapshot);
      
      setState(() {
        _selectedCategory = newCategory;
        _nameController.clear();
        _imageFile = null;
        _isProcessing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category created successfully')),
      );
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating category: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCity = widget.selectedCity;
    final categoriesAsync = ref.watch(categoriesProvider(selectedCity));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Create category form
          Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Selected City: $selectedCity', 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  
                  // Category name field
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Category Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a category name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Image preview
                  if (_imageFile != null)
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(_imageFile!),
                          fit: BoxFit.cover,
                        ),
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                    ),
                  
                  // Image picker button
                  ElevatedButton.icon(
                    onPressed: _isUploading ? null : _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text('Select Image'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Create button
                  ElevatedButton(
                    onPressed: _isProcessing || _isUploading ? null : _createCategory,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: _isProcessing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Create Category', 
                            style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
          
          // Divider
          const Divider(thickness: 1),
          
          // Category list
          Expanded(
            child: categoriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
              data: (categories) {
                if (categories.isEmpty) {
                  return const Center(
                    child: Text('No categories found. Create one above.'),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = _selectedCategory?.id == category.id;
                    
                    return Card(
                      elevation: isSelected ? 4 : 1,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isSelected
                            ? const BorderSide(color: Colors.green, width: 2)
                            : BorderSide.none,
                      ),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              // Category image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: category.imageUrl.isNotEmpty
                                    ? Image.network(
                                        category.imageUrl,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Icon(
                                          Icons.image_not_supported,
                                          size: 60,
                                          color: Colors.grey,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.category,
                                        size: 60,
                                        color: Colors.grey,
                                      ),
                              ),
                              
                              const SizedBox(width: 16),
                              
                              // Category name
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      category.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'ID: ${category.id}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // View subcategories button
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SubcategoryScreen(
                                        categoryId: category.id, 
                                        categoryName: category.name,
                                        selectedCity: selectedCity,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.arrow_forward),
                                label: const Text('View'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}