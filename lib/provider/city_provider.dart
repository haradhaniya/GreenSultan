import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CityNotifier extends StateNotifier<String?> {
  CityNotifier() : super(null) {
    _loadSelectedCity(); // Load city from SharedPreferences on initialization
  }

  // Load the selected city from SharedPreferences
  Future<void> _loadSelectedCity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final city = prefs.getString('selectedCity');
      state = city; // Set the state with the loaded city or null
    } catch (e) {
      debugPrint("Error loading city from SharedPreferences: $e");
      state = null; // Default to null if there's an error
    }
  }

  // Set the selected city and save it in SharedPreferences
  Future<void> setSelectedCity(String city) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedCity', city);
      state = city; // Update the state with the new selected city
    } catch (e) {
      debugPrint("Error saving city to SharedPreferences: $e");
    }
  }
}

// Create a StateNotifierProvider for the CityNotifier
final cityProvider = StateNotifierProvider<CityNotifier, String?>((ref) {
  return CityNotifier();
});
