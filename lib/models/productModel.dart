import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final List<String> images; // Changed from String image to List<String>
  final List<SizeAndPrice> sizesAndPrices;
  final int stock;
  final bool isActive;
  final DateTime? createdAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.images, // Now accepts multiple images
    required this.sizesAndPrices,
    required this.stock,
    this.isActive = true,
    this.createdAt,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      images: List<String>.from(data['images'] ?? []), // Handle list of images
      sizesAndPrices: (data['sizesAndPrices'] as List? ?? [])
          .map((e) => SizeAndPrice.fromMap(e))
          .toList(),
      stock: data['stock'] ?? 0,
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'images': images, // Store as list
      'sizesAndPrices': sizesAndPrices.map((e) => e.toMap()).toList(),
      'stock': stock,
      'isActive': isActive,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}

class SizeAndPrice {
  final String size;
  final double price;

  SizeAndPrice({required this.size, required this.price});

  factory SizeAndPrice.fromMap(Map<String, dynamic> map) {
    return SizeAndPrice(
      size: map['size'] ?? '',
      price: (map['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'size': size,
      'price': price,
    };
  }
}