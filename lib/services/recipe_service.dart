import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../models/recipe_model.dart';

class RecipeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Collection references
  static final CollectionReference _recipesCollection = _firestore.collection('gallery');
  
  // Get the current user ID or throw an error if not logged in
  static String _getCurrentUserId() {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    return user.uid;
  }
  
  // Get recipes by category
  static Stream<List<Recipe>> getRecipesByCategory(String category) {
    return _recipesCollection
        .where('category', isEqualTo: category)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList());
  }
  
  // Get all recipes
  static Stream<List<Recipe>> getAllRecipes() {
    return _recipesCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList());
  }
  
  // Get a single recipe by ID
  static Stream<Recipe?> getRecipeById(String recipeId) {
    return _recipesCollection
        .doc(recipeId)
        .snapshots()
        .map((doc) => doc.exists ? Recipe.fromFirestore(doc) : null);
  }
  
  // Add a new recipe
  static Future<String> addRecipe(Recipe recipe, File? imageFile) async {
    try {
      // Upload image if provided
      String imageUrl = recipe.imageUrl;
      if (imageFile != null) {
        String fileName = 'recipe_${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
        Reference ref = _storage.ref().child('gallery/$fileName');
        
        await ref.putFile(imageFile);
        imageUrl = await ref.getDownloadURL();
      }
      
      // Create updated recipe with image URL
      Recipe updatedRecipe = recipe.copyWith(imageUrl: imageUrl);
      
      // Add recipe to Firestore
      DocumentReference docRef = await _recipesCollection.add(updatedRecipe.toMap());
      
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding recipe: $e');
      throw Exception('Failed to add recipe: $e');
    }
  }
  
  // Update an existing recipe
  static Future<void> updateRecipe(Recipe recipe, File? imageFile) async {
    try {
      if (recipe.id == null) {
        throw Exception('Recipe ID is null');
      }
      
      // Upload new image if provided
      String imageUrl = recipe.imageUrl;
      if (imageFile != null) {
        String fileName = 'recipe_${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
        Reference ref = _storage.ref().child('gallery/$fileName');
        
        await ref.putFile(imageFile);
        imageUrl = await ref.getDownloadURL();
      }
      
      // Create updated recipe with new image URL
      Recipe updatedRecipe = recipe.copyWith(imageUrl: imageUrl);
      
      // Update recipe in Firestore
      await _recipesCollection.doc(recipe.id).update(updatedRecipe.toMap());
    } catch (e) {
      debugPrint('Error updating recipe: $e');
      throw Exception('Failed to update recipe: $e');
    }
  }
  
  // Delete a recipe
  static Future<void> deleteRecipe(String recipeId) async {
    try {
      await _recipesCollection.doc(recipeId).delete();
    } catch (e) {
      debugPrint('Error deleting recipe: $e');
      throw Exception('Failed to delete recipe: $e');
    }
  }
  
  // Like a recipe
  static Future<void> toggleLikeRecipe(String recipeId) async {
    try {
      String userId = _getCurrentUserId();
      DocumentReference userInteractionsRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('interactions')
          .doc(recipeId);
      
      DocumentSnapshot interactionDoc = await userInteractionsRef.get();
      
      if (interactionDoc.exists) {
        Map<String, dynamic> data = interactionDoc.data() as Map<String, dynamic>;
        bool isLiked = data['liked'] ?? false;
        
        await userInteractionsRef.update({
          'liked': !isLiked,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        await userInteractionsRef.set({
          'recipeId': recipeId,
          'liked': true,
          'saved': false,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
      throw Exception('Failed to toggle like: $e');
    }
  }
  
  // Save a recipe
  static Future<void> toggleSaveRecipe(String recipeId) async {
    try {
      String userId = _getCurrentUserId();
      DocumentReference userInteractionsRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('interactions')
          .doc(recipeId);
      
      DocumentSnapshot interactionDoc = await userInteractionsRef.get();
      
      if (interactionDoc.exists) {
        Map<String, dynamic> data = interactionDoc.data() as Map<String, dynamic>;
        bool isSaved = data['saved'] ?? false;
        
        await userInteractionsRef.update({
          'saved': !isSaved,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        await userInteractionsRef.set({
          'recipeId': recipeId,
          'liked': false,
          'saved': true,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error toggling save: $e');
      throw Exception('Failed to toggle save: $e');
    }
  }
  
  // Check if a recipe is liked by the current user
  static Future<bool> isRecipeLiked(String recipeId) async {
    try {
      String userId = _getCurrentUserId();
      DocumentSnapshot interactionDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('interactions')
          .doc(recipeId)
          .get();
      
      if (interactionDoc.exists) {
        Map<String, dynamic> data = interactionDoc.data() as Map<String, dynamic>;
        return data['liked'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking if recipe is liked: $e');
      return false;
    }
  }
  
  // Check if a recipe is saved by the current user
  static Future<bool> isRecipeSaved(String recipeId) async {
    try {
      String userId = _getCurrentUserId();
      DocumentSnapshot interactionDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('interactions')
          .doc(recipeId)
          .get();
      
      if (interactionDoc.exists) {
        Map<String, dynamic> data = interactionDoc.data() as Map<String, dynamic>;
        return data['saved'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking if recipe is saved: $e');
      return false;
    }
  }
  
  // Get all liked recipes for the current user
  static Stream<List<Recipe>> getLikedRecipes() {
    try {
      String userId = _getCurrentUserId();
      
      return _firestore
          .collection('users')
          .doc(userId)
          .collection('interactions')
          .where('liked', isEqualTo: true)
          .snapshots()
          .asyncMap((snapshot) async {
            List<Recipe> recipes = [];
            for (var doc in snapshot.docs) {
              String recipeId = doc['recipeId'];
              final recipeStream = getRecipeById(recipeId);
              final recipe = await recipeStream.first;
              if (recipe != null) {
                recipes.add(recipe);
              }
            }
            return recipes;
          });
    } catch (e) {
      debugPrint('Error getting liked recipes: $e');
      return Stream.value([]);
    }
  }
  
  // Get all saved recipes for the current user
  static Stream<List<Recipe>> getSavedRecipes() {
    try {
      String userId = _getCurrentUserId();
      
      return _firestore
          .collection('users')
          .doc(userId)
          .collection('interactions')
          .where('saved', isEqualTo: true)
          .snapshots()
          .asyncMap((snapshot) async {
            List<Recipe> recipes = [];
            for (var doc in snapshot.docs) {
              String recipeId = doc['recipeId'];
              final recipeStream = getRecipeById(recipeId);
              final recipe = await recipeStream.first;
              if (recipe != null) {
                recipes.add(recipe);
              }
            }
            return recipes;
          });
    } catch (e) {
      debugPrint('Error getting saved recipes: $e');
      return Stream.value([]);
    }
  }
} 