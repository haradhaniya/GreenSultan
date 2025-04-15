import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final List<String> images;
  final List<SizeAndPrice> sizesAndPrices;
  final String categoryId;
  final String subcategoryId;
  final bool isActive;
  final DateTime? createdAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.images,
    required this.sizesAndPrices,
    required this.categoryId,
    required this.subcategoryId,
    required this.isActive,
    this.createdAt,
  });

  factory Product.fromMap(String id, Map<String, dynamic> data) {
    List<SizeAndPrice> sizesAndPricesList = [];
    if (data['sizesAndPrices'] != null) {
      sizesAndPricesList = List<Map<String, dynamic>>.from(data['sizesAndPrices'])
          .map((map) => SizeAndPrice.fromMap(map))
          .toList();
    }

    return Product(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: sizesAndPricesList.isNotEmpty 
          ? sizesAndPricesList.first.price 
          : ((data['price'] is int) 
              ? (data['price'] as int).toDouble() 
              : (data['price'] as num?)?.toDouble() ?? 0.0),
      stock: data['stock'] ?? 0,
      images: List<String>.from(data['images'] ?? []),
      sizesAndPrices: sizesAndPricesList,
      categoryId: data['categoryId'] ?? '',
      subcategoryId: data['subcategoryId'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] != null ? (data['createdAt'] as dynamic).toDate() : null,
    );
  }

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Product.fromMap(doc.id, data);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'images': images,
      'sizesAndPrices': sizesAndPrices.map((sp) => sp.toMap()).toList(),
      'categoryId': categoryId,
      'subcategoryId': subcategoryId,
      'isActive': isActive,
      'createdAt': createdAt,
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
      price: (map['price'] is int)
          ? (map['price'] as int).toDouble()
          : (map['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'size': size,
      'price': price,
    };
  }
}