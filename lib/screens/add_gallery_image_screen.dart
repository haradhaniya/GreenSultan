import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:green_sultan/models/recipe_model.dart';
import 'package:green_sultan/services/recipe_service.dart';

class AddGalleryImageScreen extends StatefulWidget {
  final String? initialCategory;
  final String? imageId;
  final bool isAddingRecipe;
  
  const AddGalleryImageScreen({
    Key? key, 
    this.initialCategory,
    this.imageId,
    this.isAddingRecipe = false,
  }) : super(key: key);

  @override
  State<AddGalleryImageScreen> createState() => _AddGalleryImageScreenState();
}

class _AddGalleryImageScreenState extends State<AddGalleryImageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _recipeController = TextEditingController();
  final _ingredientsController = TextEditingController();
  
  late String _selectedCategory;
  File? _selectedImage;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  bool _isEditMode = false;
  String? _existingImageUrl;
  Recipe? _existingRecipe;
  
  final ImagePicker _picker = ImagePicker();
  
  final List<String> _categories = [
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
    
    // Make sure the initialCategory is in our categories list, otherwise use the first item
    if (widget.initialCategory != null && _categories.contains(widget.initialCategory)) {
      _selectedCategory = widget.initialCategory!;
    } else {
      _selectedCategory = _categories[0];
    }
    
    // If imageId is provided, we're in edit mode or adding a recipe to an existing image
    if (widget.imageId != null) {
      _isEditMode = true;
      _loadExistingData();
    }
  }
  
  Future<void> _loadExistingData() async {
    try {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.1; // Show some progress
      });
      
      // Use the RecipeService to get the recipe by ID
      final recipeStream = await RecipeService.getRecipeById(widget.imageId!);
      final recipe = await recipeStream.first;
      
      if (recipe != null) {
        setState(() {
          _existingRecipe = recipe;
          _existingImageUrl = recipe.imageUrl;
          _titleController.text = recipe.title;
          _descriptionController.text = recipe.description;
          _recipeController.text = recipe.recipe;
          _ingredientsController.text = recipe.ingredients;
          _selectedCategory = recipe.category;
          _isUploading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recipe not found')),
        );
        setState(() {
          _isUploading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading recipe: $e')),
      );
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _recipeController.dispose();
    _ingredientsController.dispose();
    super.dispose();
  }

  Future<void> _selectImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
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
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
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
        content: Text('Uploading recipe... This may take a moment'),
        duration: Duration(seconds: 6),
      ),
    );

    try {
      // Create a recipe object with the form data
      Recipe recipe = Recipe(
        id: _isEditMode ? widget.imageId : null,
        title: _titleController.text,
        category: _selectedCategory,
        description: _descriptionController.text,
        recipe: _recipeController.text,
        ingredients: _ingredientsController.text,
        imageUrl: _existingImageUrl ?? '', // Will be replaced if a new image is uploaded
      );
      
      if (_isEditMode) {
        // Update existing recipe
        await RecipeService.updateRecipe(recipe, _selectedImage);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.isAddingRecipe 
              ? 'Recipe added successfully' 
              : 'Recipe updated successfully')),
          );
          setState(() {
            _isUploading = false;
            _uploadProgress = 1.0;
          });
          Navigator.pop(context);
        }
      } else {
        // Add new recipe
        await RecipeService.addRecipe(recipe, _selectedImage);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Recipe added to $_selectedCategory category')),
          );
          setState(() {
            _isUploading = false;
            _uploadProgress = 1.0;
          });
          Navigator.pop(context);
        }
      }
    } catch (e) {
      debugPrint('Error saving recipe: $e');
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.isAddingRecipe
        ? 'Add Recipe'
        : _isEditMode
            ? 'Edit Recipe'
            : 'Add to ${_selectedCategory}';

    return Scaffold(
      appBar: AppBar(
        title: Text(titleText, style: const TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: LoadingOverlay(
        isLoading: _isUploading,
        progressValue: _uploadProgress,
        child: SingleChildScrollView(
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
                              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
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
                                'Tap to add an image',
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
                
                // Title field
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
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
                
                // Description field
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                
                const SizedBox(height: 16),
                
                // Recipe fields
                TextFormField(
                  controller: _ingredientsController,
                  decoration: const InputDecoration(
                    labelText: 'Ingredients (one per line)',
                    border: OutlineInputBorder(),
                    hintText: 'Example:\n2 cups flour\n1 egg\n1/2 cup sugar',
                  ),
                  maxLines: 5,
                ),
                
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _recipeController,
                  decoration: const InputDecoration(
                    labelText: 'Recipe Instructions',
                    border: OutlineInputBorder(),
                    hintText: 'Enter step-by-step instructions here',
                  ),
                  maxLines: 8,
                ),
                
                const SizedBox(height: 24),
                
                // Submit button
                ElevatedButton.icon(
                  onPressed: _isUploading ? null : _uploadRecipe,
                  icon: Icon(widget.isAddingRecipe ? Icons.receipt : Icons.cloud_upload),
                  label: Text(widget.isAddingRecipe ? 'Save Recipe' : 'Save'),
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

// Loading overlay widget to show progress
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final double? progressValue;

  const LoadingOverlay({
    Key? key,
    required this.isLoading,
    required this.child,
    this.progressValue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (progressValue != null)
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        value: progressValue,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 8,
                      ),
                    )
                  else
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  const SizedBox(height: 20),
                  Text(
                    progressValue != null 
                        ? '${(progressValue! * 100).toStringAsFixed(0)}%' 
                        : 'Loading...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
} 