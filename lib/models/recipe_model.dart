import 'package:cloud_firestore/cloud_firestore.dart';

class Recipe {
  final String? id;
  final String title;
  final String category;
  final String imageUrl;
  final String description;
  final String ingredients;
  final String recipe;
  final Timestamp timestamp;
  
  Recipe({
    this.id,
    required this.title,
    required this.category,
    required this.imageUrl,
    this.description = '',
    this.ingredients = '',
    this.recipe = '',
    Timestamp? timestamp,
  }) : timestamp = timestamp ?? Timestamp.now();
  
  // Create a Recipe from Firestore document
  factory Recipe.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Recipe(
      id: doc.id,
      title: data['title'] ?? '',
      category: data['category'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'] ?? '',
      ingredients: data['ingredients'] ?? '',
      recipe: data['recipe'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }
  
  // Convert Recipe to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'imageUrl': imageUrl,
      'description': description,
      'ingredients': ingredients,
      'recipe': recipe,
      'timestamp': timestamp,
    };
  }
  
  // Create a copy of this Recipe with some new values
  Recipe copyWith({
    String? title,
    String? category,
    String? imageUrl,
    String? description,
    String? ingredients,
    String? recipe,
    Timestamp? timestamp,
  }) {
    return Recipe(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
      recipe: recipe ?? this.recipe,
      timestamp: timestamp ?? this.timestamp,
    );
  }
} 