import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_sultan/change_veggies_price/water/water_product_card.dart';
import '../../provider/city_provider.dart';
import '../../provider/selected_city_provider.dart';

class WaterProductListView extends ConsumerWidget {
  final bool isPinVerified;
  final String searchQuery;
  final TextEditingController _pinController = TextEditingController();
  final String _correctPin = '786';

  WaterProductListView({
    super.key,
    required this.isPinVerified,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCity = ref.watch(cityProvider);

    // Ensure cities are fetched - but in a postFrameCallback to avoid rebuild issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only fetch the list but don't modify selection
      ref.read(cityProvider2.notifier).fetchCities();
    });

    return Column(
      children: [
        // City selection indicator
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.location_city, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: selectedCity == null || selectedCity.isEmpty
                    ? const Text(
                        'No city selected',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : Text(
                        'Selected City: $selectedCity',
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),

        if (selectedCity == null || selectedCity.isEmpty)
          const Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 64, color: Colors.orange),
                  SizedBox(height: 16),
                  Text(
                    'Please select a city to view water products',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: _buildProductList(context, ref, selectedCity),
          ),

        // Admin action button with shadow
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: () => _showPinDialog(context, ref),
            icon: const Icon(Icons.refresh),
            label: const Text('RESET ALL VALUES'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductList(
      BuildContext context, WidgetRef ref, String selectedCity) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Cities')
          .doc(selectedCity)
          .collection('${selectedCity}Water')
          .snapshots(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Colors.blue),
                const SizedBox(height: 16),
                Text(
                  'Loading water products...',
                  style: TextStyle(color: Colors.blue.shade800),
                ),
              ],
            ),
          );
        }

        // Error state
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading data: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Empty state
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.water_drop,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No water products available for $selectedCity',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Filter products based on search query
        var filteredProducts = snapshot.data!.docs.where((doc) {
          var name = doc['name']?.toString().toLowerCase() ?? '';
          return name.contains(searchQuery.toLowerCase());
        }).toList();

        // Empty search results
        if (filteredProducts.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No water products matching "$searchQuery"',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    // This is just a UI suggestion - you'd need to implement
                    // search clearing functionality in the parent widget
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear Search'),
                ),
              ],
            ),
          );
        }

        // Success state with data
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 8),
          itemCount: filteredProducts.length,
          itemBuilder: (context, index) {
            return WaterProductCard(
              product: filteredProducts[index],
              isPinVerified: isPinVerified,
              index: index + 1,
            );
          },
        );
      },
    );
  }

  void _clearValues(BuildContext context, WidgetRef ref) {
    final selectedCity = ref.watch(cityProvider);
    if (selectedCity == null || selectedCity.isEmpty) {
      _showSnackBar(context, 'No city selected');
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.blue),
      ),
    );

    FirebaseFirestore.instance
        .collection('Cities')
        .doc(selectedCity)
        .collection('${selectedCity}Water')
        .get()
        .then((snapshot) {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'value1': '0'});
      }

      return batch.commit().then((_) {
        return FirebaseFirestore.instance
            .collection('Cities')
            .doc(selectedCity)
            .collection('water_values')
            .get();
      });
    }).then((valueSnapshot) {
      WriteBatch valueBatch = FirebaseFirestore.instance.batch();

      for (var valueDoc in valueSnapshot.docs) {
        valueBatch.update(valueDoc.reference, {'value1': '0'});
      }

      return valueBatch.commit();
    }).then((_) {
      // Close loading dialog
      Navigator.of(context).pop();
      _showSnackBar(context, 'Value 1 cleared for all water products');
      Navigator.of(context).pop(); // Close the PIN dialog
    }).catchError((error) {
      // Close loading dialog
      Navigator.of(context).pop();
      _showSnackBar(context, 'Failed to clear value 1: $error');
    });
  }

  void _showPinDialog(BuildContext context, WidgetRef ref) {
    _pinController.clear(); // Clear previous input

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Administrator Authentication',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Please enter your PIN to reset all values.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pinController,
                decoration: const InputDecoration(
                  labelText: 'Enter PIN',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  letterSpacing: 15,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () => _verifyPinAndClearValues(context, ref),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('SUBMIT'),
            ),
          ],
        );
      },
    );
  }

  void _verifyPinAndClearValues(BuildContext context, WidgetRef ref) {
    if (_pinController.text == _correctPin) {
      _clearValues(context, ref);
    } else {
      Navigator.of(context).pop(); // Close the PIN dialog
      _showSnackBar(context, 'Incorrect PIN. Access denied.');
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(10),
      ),
    );
  }
} 