import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/city_provider.dart';
import 'water_product_add_form.dart';

class SimpleWaterPanel extends ConsumerStatefulWidget {
  const SimpleWaterPanel({super.key});

  @override
  ConsumerState<SimpleWaterPanel> createState() => _SimpleWaterPanelState();
}

class _SimpleWaterPanelState extends ConsumerState<SimpleWaterPanel> {
  final TextEditingController _pinController = TextEditingController();
  final String _correctPin = '786';
  bool _isPinVerified = false;

  @override
  Widget build(BuildContext context) {
    final selectedCity = ref.watch(cityProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Products'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.lock),
            onPressed: () => _showPinDialog(context),
            tooltip: 'Verify PIN',
          ),
        ],
      ),
      body: Column(
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
              child: _buildProductList(context, selectedCity),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (!_isPinVerified) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please verify PIN first')),
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WaterProductAddForm()),
          ).then((_) => setState(() {})); // Refresh after returning
        },
        icon: const Icon(Icons.add),
        label: const Text('ADD WATER PRODUCT'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildProductList(BuildContext context, String selectedCity) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Cities')
          .doc(selectedCity)
          .collection('${selectedCity}Water')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No water products available'),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            
            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Container(
                        width: double.infinity,
                        color: Colors.blue.shade50,
                        child: data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty
                            ? Image.network(
                                data['imageUrl'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Center(
                                  child: Icon(Icons.image_not_supported, color: Colors.grey.shade400, size: 48),
                                ),
                              )
                            : Center(
                                child: Icon(Icons.water_drop, color: Colors.blue.shade200, size: 48),
                              ),
                      ),
                    ),
                  ),
                  
                  // Product Info
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['name'] ?? 'Unnamed Product',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Price: ₹${data['price'] ?? '0'}',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Edit Button
                            ElevatedButton(
                              onPressed: () {
                                if (!_isPinVerified) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please verify PIN first')),
                                  );
                                  return;
                                }
                                _showEditDialog(context, doc, selectedCity);
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: const Size(40, 36),
                                backgroundColor: Colors.blue,
                              ),
                              child: const Icon(Icons.edit, size: 18),
                            ),
                            
                            // Delete Button
                            ElevatedButton(
                              onPressed: () {
                                if (!_isPinVerified) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please verify PIN first')),
                                  );
                                  return;
                                }
                                _showDeleteConfirmation(context, doc, selectedCity);
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: const Size(40, 36),
                                backgroundColor: Colors.red,
                              ),
                              child: const Icon(Icons.delete, size: 18),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPinDialog(BuildContext context) {
    _pinController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verify PIN'),
        content: TextField(
          controller: _pinController,
          decoration: const InputDecoration(
            labelText: 'Enter admin PIN',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_pinController.text == _correctPin) {
                setState(() {
                  _isPinVerified = true;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN verified successfully')),
                );
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Incorrect PIN'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('VERIFY'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, DocumentSnapshot doc, String selectedCity) {
    final data = doc.data() as Map<String, dynamic>;
    final nameController = TextEditingController(text: data['name']);
    final priceController = TextEditingController(text: data['price']?.toString() ?? '0');
    final imageUrlController = TextEditingController(text: data['imageUrl']);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Water Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await doc.reference.update({
                  'name': nameController.text,
                  'price': priceController.text,
                  'imageUrl': imageUrlController.text,
                  'url': imageUrlController.text,
                });
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Product updated successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating product: $e')),
                );
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, DocumentSnapshot doc, String selectedCity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                // Delete from water_values collection first if it exists
                await FirebaseFirestore.instance
                    .collection('Cities')
                    .doc(selectedCity)
                    .collection('water_values')
                    .doc(doc.id)
                    .delete()
                    .catchError((e) => null); // Ignore error if document doesn't exist
                
                // Then delete the product itself
                await doc.reference.delete();
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Product deleted successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting product: $e')),
                );
              }
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
} 