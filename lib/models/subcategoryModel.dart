import 'package:cloud_firestore/cloud_firestore.dart';

class Subcategory {
  final String id;
  final String name;
  final String image;

  Subcategory({required this.id, required this.name, required this.image});

  factory Subcategory.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Subcategory(
      id: doc.id,
      name: data['name'] ?? '',
      image: data['image'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'image': image,
    };
  }
}
