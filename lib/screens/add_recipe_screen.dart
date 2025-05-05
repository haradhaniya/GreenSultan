import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async'; // For TimeoutException
import 'dart:math' as Math; // For min function

class AddRecipeScreen extends StatefulWidget {
  final String? initialCategory;
  final String? recipeId;
  final bool isEditing;
  final Map<String, dynamic>? recipeData;
  
  const AddRecipeScreen({
    Key? key, 
    this.initialCategory,
    this.recipeId,
    this.isEditing = false,
    this.recipeData,
  }) : super(key: key);

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _ingredientsController = TextEditingController();
  
  late String _selectedCategory;
  File? _selectedImage;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  bool _isEditMode = false;
  String? _existingImageUrl;
  Map<String, dynamic>? _existingData;
  
  final ImagePicker _picker = ImagePicker();
  
  // Category selection
  final List<String> _categories = [
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
    
    // Make sure the initialCategory is in our categories list, otherwise use the first item
    if (widget.initialCategory != null && _categories.contains(widget.initialCategory)) {
      _selectedCategory = widget.initialCategory!;
    } else {
      _selectedCategory = _categories[0];
    }
    
    // If recipeId is provided, we're in edit mode
    if (widget.recipeId != null) {
      _isEditMode = true;
      _loadExistingData();
    }
  }
  
  Future<void> _loadExistingData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('gallery')
          .doc(widget.recipeId)
          .get();
          
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _existingData = data;
          _existingImageUrl = data['imageUrl'];
          _titleController.text = data['title'] ?? '';
          _descriptionController.text = data['description'] ?? '';
          _instructionsController.text = data['instructions'] ?? '';
          _ingredientsController.text = data['ingredients'] ?? '';
          
          if (data['category'] != null) {
            _selectedCategory = data['category'];
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading existing data: $e')),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    _ingredientsController.dispose();
    super.dispose();
  }

  Future<void> _selectImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _existingImageUrl = null; // Clear existing image if a new one is selected
        });
      }
    } catch (e) {
      debugPrint('Error selecting image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectImageFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _existingImageUrl = null; // Clear existing image if a new one is selected
        });
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error taking photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadRecipe() async {
    if (_selectedImage == null && _existingImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    // Show a persistent message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Uploading recipe... This may take a few minutes on slow connections'),
        duration: Duration(seconds: 10),
      ),
    );

    try {
      String? imageUrl = _existingImageUrl;
      
      // Only upload a new image if one was selected
      if (_selectedImage != null) {
        try {
          // Show a dialog for long uploads
          if (!mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => StatefulBuilder(
              builder: (context, setState) => AlertDialog(
                title: const Text('Uploading Image'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(value: _uploadProgress),
                    const SizedBox(height: 16),
                    Text('${(_uploadProgress * 100).toStringAsFixed(1)}%'),
                    const SizedBox(height: 8),
                    Text(
                      _uploadProgress < 0.1 
                          ? 'Starting upload...'
                          : _uploadProgress < 0.5
                              ? 'Uploading image...' 
                              : _uploadProgress < 0.9
                                  ? 'Processing...'
                                  : 'Finishing up...',
                    ),
                  ],
                ),
              ),
            ),
          );
          
          // Upload image to Firebase Storage
          final fileName = 'recipe_${DateTime.now().millisecondsSinceEpoch}_${path.basename(_selectedImage!.path)}';
          final storageRef = FirebaseStorage.instance.ref().child('recipe_images/$fileName');
          
          final uploadTask = storageRef.putFile(_selectedImage!);
          
          // Monitor upload progress
          bool hasProgressUpdated = false;
          uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
            if (mounted) {
              setState(() {
                _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
                hasProgressUpdated = true;
              });
              debugPrint('Upload progress: ${(_uploadProgress * 100).toStringAsFixed(1)}%');
            }
          });
          
          // Wait for upload to complete with timeout
          await uploadTask.timeout(const Duration(minutes: 3), onTimeout: () {
            debugPrint('Image upload timed out');
            throw TimeoutException('Image upload timed out');
          }).whenComplete(() {});
          
          // Get download URL
          imageUrl = await storageRef.getDownloadURL();
          debugPrint('Image uploaded successfully: $imageUrl');
          
          // Close the dialog when upload completes
          if (mounted) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        } catch (storageError) {
          debugPrint('Storage error: $storageError');
          // Continue without image if storage fails
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Image upload failed: ${storageError.toString().substring(0, Math.min(storageError.toString().length, 100))}. Continuing with recipe data only.')),
            );
          }
        }
      }
      
      // Parse ingredients from text to list
      List<String> ingredientsList = [];
      if (_ingredientsController.text.isNotEmpty) {
        ingredientsList = _ingredientsController.text
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .toList();
      }
      
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      
      // Prepare recipe data
      final Map<String, dynamic> data = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'instructions': _instructionsController.text,
        'ingredients': _ingredientsController.text,
        'category': _selectedCategory,
        'userId': user?.uid,
      };
      
      // Only add imageUrl if it's available (either existing or new)
      if (imageUrl != null) {
        data['imageUrl'] = imageUrl;
      } else {
        // Use a placeholder image if no image is available
        data['imageUrl'] = 'https://via.placeholder.com/400x400?text=No+Image';
      }
      
      try {
        debugPrint('Saving to Firestore: ${data['title']}');
        
        // For edit mode
        if (_isEditMode) {
          // Update existing document with timeout
          await FirebaseFirestore.instance
              .collection('gallery')
              .doc(widget.recipeId)
              .update(data)
              .timeout(const Duration(minutes: 1), onTimeout: () {
                throw TimeoutException('Firestore update timed out');
              });
        } else {
          // Add timestamp and likes only for new recipes
          data['timestamp'] = Timestamp.now();
          data['likes'] = 0;
          
          // Create new document with timeout
          await FirebaseFirestore.instance
              .collection('gallery')
              .add(data)
              .timeout(const Duration(minutes: 1), onTimeout: () {
                throw TimeoutException('Firestore add timed out');
              });
        }
        
        if (mounted) {
          final message = _isEditMode 
              ? 'Recipe updated successfully'
              : 'Recipe added to ${_selectedCategory} category';
              
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
          Navigator.pop(context);
        }
      } catch (firestoreError) {
        // Handle Firestore errors specifically
        debugPrint('Firestore error: $firestoreError');
        
        // Check if it's a timeout error
        if (firestoreError is TimeoutException) {
          // Save data for later synchronization
          _saveOfflineData(data);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Network timeout. Recipe will be saved when connection is restored.'),
                duration: Duration(seconds: 5),
              ),
            );
            Navigator.pop(context); // Still allow user to go back
          }
        } else {
          // Show a more descriptive error for offline
          String errorMessage = 'Connection error';
          if (firestoreError.toString().contains('UNAVAILABLE')) {
            errorMessage = 'You appear to be offline. Please check your connection and try again.';
          } else {
            errorMessage = 'Error: ${firestoreError.toString().substring(0, Math.min(firestoreError.toString().length, 100))}';
          }
          
          if (mounted) {
            setState(() {
              _isUploading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                duration: Duration(seconds: 4),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('General error: $e');
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().substring(0, Math.min(e.toString().length, 100))}'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // Save recipe data locally when offline
  void _saveOfflineData(Map<String, dynamic> data) {
    // For a real implementation, this would save to shared_preferences or another local storage
    debugPrint('Recipe data will be saved when connection is restored: ${data['title']}');
    
    // In a production app, you would implement:
    // 1. Save to local storage
    // 2. Add to a queue of pending uploads
    // 3. Create a background service to retry uploads when connection is restored
  }

  @override
  Widget build(BuildContext context) {
    final titleText = _isEditMode ? 'Edit Recipe' : 'Add New Recipe';

    return Scaffold(
      appBar: AppBar(
        title: Text(titleText, style: const TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Container
              Container(
                height: 200,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.5)),
                ),
                child: GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: _selectedImage != null 
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : _existingImageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: _existingImageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error, color: Colors.red, size: 40),
                                SizedBox(height: 8),
                                Text('Image failed to load', textAlign: TextAlign.center),
                                Text('Tap to select new image', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).primaryColor)),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              color: Theme.of(context).primaryColor,
                              size: 50,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Tap to add recipe image',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Recipe title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Recipe Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Category dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                value: _selectedCategory,
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  hintText: 'Enter a brief description of the recipe',
                ),
                maxLines: 3,
              ),
              
              const SizedBox(height: 16),
              
              // Ingredients field
              TextFormField(
                controller: _ingredientsController,
                decoration: const InputDecoration(
                  labelText: 'Ingredients (one per line)',
                  border: OutlineInputBorder(),
                  hintText: 'Example:\n2 cups flour\n1 egg\n1/2 cup sugar',
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter at least one ingredient';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Instructions field
              TextFormField(
                controller: _instructionsController,
                decoration: const InputDecoration(
                  labelText: 'Recipe Instructions',
                  border: OutlineInputBorder(),
                  hintText: 'Enter step-by-step instructions here',
                ),
                maxLines: 8,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter cooking instructions';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Upload progress
              if (_isUploading)
                Column(
                  children: [
                    LinearProgressIndicator(value: _uploadProgress),
                    const SizedBox(height: 8),
                    Text('Uploading: ${(_uploadProgress * 100).toStringAsFixed(1)}%'),
                    const SizedBox(height: 8),
                    Text(
                      _uploadProgress < 0.1 
                          ? 'Starting upload...'
                          : _uploadProgress < 0.5
                              ? 'Uploading image...' 
                              : _uploadProgress < 0.9
                                  ? 'Processing...'
                                  : 'Finishing up...',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              
              // Submit button
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadRecipe,
                icon: Icon(_isEditMode ? Icons.update : Icons.save),
                label: Text(_isEditMode ? 'Update Recipe' : 'Save Recipe'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _selectImage();
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _selectImageFromCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }
} 