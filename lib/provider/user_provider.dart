import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserNotifier extends StateNotifier<Map<String, dynamic>> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserNotifier() : super({});

  // Save user data to Firestore for login
  Future<void> saveUserData(String email, String selectedCity) async {
    try {
      await _firestore
          .collection('Cities')
          .doc(selectedCity)
          .collection('Green_Sultan_Users')
          .doc(email)
          .set({
        'email': email,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update the local state
      state = {'email': email, 'city': selectedCity};
    } catch (e) {
      throw Exception('Error saving user data: $e');
    }
  }

  // Save user data to Firestore for sign-up with role
  Future<void> saveUser(String name, String email, String selectedCity, String selectedRole) async {
    try {
      await _firestore
          .collection('Cities')
          .doc(selectedCity)
          .collection('Green_Sultan_Users')
          .doc(email)
          .set({
        'name': name,
        'email': email,
        'role': selectedRole, // Add role to Firestore
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update the local state with role included
      state = {
        'name': name,
        'email': email,
        'city': selectedCity,
        'role': selectedRole, // Save role in the state
      };
    } catch (e) {
      throw Exception('Error saving user: $e');
    }
  }
}

// User data provider
final userProvider = StateNotifierProvider<UserNotifier, Map<String, dynamic>>((ref) {
  return UserNotifier();
});
