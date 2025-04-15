import 'package:cloud_firestore/cloud_firestore.dart';

class Subcategory {
  final String id;
  final String name;
  final String categoryId;
  final String imageUrl;
  final bool isActive;
  final DateTime createdAt;

  Subcategory({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.imageUrl,
    required this.isActive,
    required this.createdAt,
  });

  factory Subcategory.fromMap(String id, Map<String, dynamic> map) {
    return Subcategory(
      id: id,
      name: map['name'] ?? '',
      categoryId: map['categoryId'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'categoryId': categoryId,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }

  Subcategory copyWith({
    String? id,
    String? name,
    String? categoryId,
    String? imageUrl,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Subcategory(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Subcategory.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Subcategory.fromMap(doc.id, data);
  }
}
