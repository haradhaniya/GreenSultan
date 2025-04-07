import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserNotifier extends StateNotifier<Map<String, dynamic>> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserNotifier() : super({});

  // Save user data to Firestore for login
  Future<void> saveUserData(
      String email, String selectedCity, String selectedRole) async {
    try {
      // Validate that selectedCity is not empty
      if (selectedCity.isEmpty) {
        throw Exception('Selected city cannot be empty');
      }

      // Prevent roles from being used as city names
      final List<String> roleTypes = ['Owner', 'Administrator', 'Rider'];
      if (roleTypes.contains(selectedCity)) {
        throw Exception(
            'Invalid city selected: $selectedCity. This appears to be a role, not a city.');
      }

      // Create a reference to the city document
      final cityDocRef = _firestore.collection('Cities').doc(selectedCity);

      // Ensure the city document exists
      await cityDocRef.set({
        'name': selectedCity,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update the user document under the city
      await cityDocRef.collection('Green_Sultan_Users').doc(email).set({
        'email': email,
        'role': selectedRole,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update the local state
      state = {
        'email': email,
        'city': selectedCity,
        'role': selectedRole,
      };
    } catch (e) {
      throw Exception('Error saving user data: $e');
    }
  }

  // Save user data to Firestore for sign-up with role
  Future<void> saveUser(String name, String email, String selectedCity,
      String selectedRole) async {
    try {
      // Validate that selectedCity is not empty
      if (selectedCity.isEmpty) {
        throw Exception('Selected city cannot be empty');
      }

      // Prevent roles from being used as city names
      final List<String> roleTypes = ['Owner', 'Administrator', 'Rider'];
      if (roleTypes.contains(selectedCity)) {
        throw Exception(
            'Invalid city selected: $selectedCity. This appears to be a role, not a city.');
      }

      // Create a reference to the city document
      final cityDocRef = _firestore.collection('Cities').doc(selectedCity);

      // Ensure the city document exists
      await cityDocRef.set({
        'name': selectedCity,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Now create the user document under the city
      await cityDocRef.collection('Green_Sultan_Users').doc(email).set({
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

  // Check if user has permission to access a specific screen
  bool hasPermission(String screenName) {
    final userRole = state['role'] ?? '';

    // If the user is a rider, they can only access Live Hara Dhaniya and Rider App
    if (userRole.toLowerCase() == 'rider') {
      return screenName == 'RiderApp' || screenName == 'LiveHaraDhaniya';
    }

    // Other roles (Owner, Administrator) have access to all screens
    return true;
  }
}

// User data provider
final userProvider =
    StateNotifierProvider<UserNotifier, Map<String, dynamic>>((ref) {
  return UserNotifier();
});

// Role provider for simple access to current user role
final userRoleProvider = Provider<String>((ref) {
  final userData = ref.watch(userProvider);
  return userData['role'] ?? '';
});

// Permission provider to check if user can access specific screens
final hasPermissionProvider = Provider.family<bool, String>((ref, screenName) {
  final userNotifier = ref.read(userProvider.notifier);
  return userNotifier.hasPermission(screenName);
});

// A widget wrapper to enforce role-based access control
class RoleBasedAccessControl extends ConsumerWidget {
  final String screenName;
  final Widget child;
  final Widget? fallbackWidget;

  const RoleBasedAccessControl({
    required this.screenName,
    required this.child,
    this.fallbackWidget,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPermission = ref.watch(hasPermissionProvider(screenName));
    final userRole = ref.watch(userRoleProvider).toLowerCase();

    if (hasPermission) {
      return child;
    } else {
      // For riders, show a simplified message or empty container to avoid cluttering their UI
      if (userRole == 'rider') {
        return fallbackWidget ??
            Container(); // Hide restricted features completely for riders
      }

      // For other roles, show the access denied screen
      return fallbackWidget ??
          Scaffold(
            appBar: AppBar(
              title: const Text('Access Denied'),
              backgroundColor: Colors.red,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, size: 80, color: Colors.red),
                  const SizedBox(height: 20),
                  const Text(
                    'Access Denied',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'You do not have permission to access this section.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
    }
  }
}
