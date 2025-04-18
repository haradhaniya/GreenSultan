import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class WaterProductCard extends ConsumerStatefulWidget {
  final DocumentSnapshot product;
  final bool isPinVerified;
  final int index;

  const WaterProductCard({
    super.key,
    required this.product,
    required this.isPinVerified,
    required this.index,
  });

  @override
  ConsumerState<WaterProductCard> createState() => _WaterProductCardState();
}

class _WaterProductCardState extends ConsumerState<WaterProductCard> {
  final _value1Controller = TextEditingController();
  final _value2Controller = TextEditingController();
  final _value3Controller = TextEditingController();
  final _nameController = TextEditingController();
  final _imageUrlController = TextEditingController();
  bool _isEditing = false;
  bool _isEditingDetails = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadValues();
    _loadProductDetails();
  }

  @override
  void dispose() {
    _value1Controller.dispose();
    _value2Controller.dispose();
    _value3Controller.dispose();
    _nameController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _loadProductDetails() {
    final data = widget.product.data() as Map<String, dynamic>?;
    if (data != null) {
      _nameController.text = data['name'] as String? ?? 'Unnamed Product';
      _imageUrlController.text = data['imageUrl'] ?? data['url'] ?? '';
    }
  }

  Future<void> _loadValues() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final city = widget.product.reference.parent.parent?.id;
      if (city != null) {
        final valueDoc = await FirebaseFirestore.instance
            .collection('Cities')
            .doc(city)
            .collection('water_values')
            .doc(widget.product.id)
            .get();

        if (valueDoc.exists && valueDoc.data() != null) {
          setState(() {
            _value1Controller.text = valueDoc.data()?['value1'] ?? '0';
            _value2Controller.text = valueDoc.data()?['value2'] ?? '0';
            _value3Controller.text = valueDoc.data()?['value3'] ?? '0';
          });
        } else {
          // Initialize with zeros if no values exist
          _value1Controller.text = '0';
          _value2Controller.text = '0';
          _value3Controller.text = '0';
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading values: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveValues() async {
    if (!widget.isPinVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN verification required')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final city = widget.product.reference.parent.parent?.id;
      if (city != null) {
        // Save values to the water_values collection
        await FirebaseFirestore.instance
            .collection('Cities')
            .doc(city)
            .collection('water_values')
            .doc(widget.product.id)
            .set({
          'value1': _value1Controller.text,
          'value2': _value2Controller.text,
          'value3': _value3Controller.text,
        });

        // Calculate and update the price in the main collection
        final value1 = double.tryParse(_value1Controller.text) ?? 0;
        final value2 = double.tryParse(_value2Controller.text) ?? 0;
        final value3 = double.tryParse(_value3Controller.text) ?? 0;
        final price = (value1 + value2 + value3).round().toString();

        await widget.product.reference.update({
          'price': price,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Values saved successfully')),
        );

        setState(() {
          _isEditing = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving values: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProductDetails() async {
    if (!widget.isPinVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN verification required')),
      );
      return;
    }

    // Validate inputs
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product name cannot be empty')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Update product details in Firestore
      await widget.product.reference.update({
        'name': _nameController.text.trim(),
        'imageUrl': _imageUrlController.text.trim(),
        'url': _imageUrlController.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product details updated successfully')),
      );

      setState(() {
        _isEditingDetails = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating product details: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProduct() async {
    if (!widget.isPinVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN verification required')),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text(
          'Are you sure you want to delete this water product? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final city = widget.product.reference.parent.parent?.id;
      if (city != null) {
        // Delete from water_values collection first
        await FirebaseFirestore.instance
            .collection('Cities')
            .doc(city)
            .collection('water_values')
            .doc(widget.product.id)
            .delete();

        // Then delete the product itself
        await widget.product.reference.delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting product: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.product.data() as Map<String, dynamic>?;
    
    if (data == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Error: Invalid product data'),
        ),
      );
    }

    final name = data['name'] as String? ?? 'Unnamed Product';
    final price = data['price'] as String? ?? '0';
    final imageUrl = data['imageUrl'] ?? data['url'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.blue.shade300,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Center(
                                  child: Icon(Icons.image_not_supported, color: Colors.grey),
                                ),
                              )
                            : const Center(
                                child: Icon(Icons.water_drop, color: Colors.blue),
                              ),
                      ),
                      if (widget.isPinVerified && !_isEditingDetails)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.7),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                setState(() {
                                  _isEditingDetails = true;
                                });
                              },
                              tooltip: 'Edit Details',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                
                // Product details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '₹$price',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Product ID: ${widget.product.id}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      
                      // Admin actions
                      if (widget.isPinVerified)
                        Row(
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _isEditing = !_isEditing;
                                  // Close details editing if price editing is opened
                                  if (_isEditing) {
                                    _isEditingDetails = false;
                                  }
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                minimumSize: const Size(0, 32),
                                side: BorderSide(color: Colors.blue),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                _isEditing ? 'Cancel' : 'Edit Price',
                                style: TextStyle(color: Colors.blue),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (_isEditing)
                              ElevatedButton(
                                onPressed: _isLoading ? null : _saveValues,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                  minimumSize: const Size(0, 32),
                                  backgroundColor: Colors.blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Save'),
                              ),
                            const Spacer(),
                            // Delete button
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 24),
                              onPressed: _isLoading ? null : _deleteProduct,
                              tooltip: 'Delete Product',
                              padding: const EdgeInsets.all(4),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.red.withOpacity(0.1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Product Details editing
            if (_isEditingDetails && widget.isPinVerified)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Edit Product Details:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Product Name Field
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Product Name',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Image URL Field
                    TextField(
                      controller: _imageUrlController,
                      decoration: InputDecoration(
                        labelText: 'Image URL',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Save/Cancel buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _isEditingDetails = false;
                              _loadProductDetails(); // reload original values
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            side: BorderSide(color: Colors.grey),
                          ),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _saveProductDetails,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Save Details'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            
            // Value editing fields
            if (_isEditing && widget.isPinVerified)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Price Components:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildValueField(
                            controller: _value1Controller,
                            label: 'Base Price',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildValueField(
                            controller: _value2Controller,
                            label: 'Delivery Fee',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildValueField(
                            controller: _value3Controller,
                            label: 'Other Charges',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueField({
    required TextEditingController controller,
    required String label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            prefixText: '₹',
          ),
        ),
      ],
    );
  }
} 