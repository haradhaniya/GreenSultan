import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class FruitsPage extends StatefulWidget {
  const FruitsPage({super.key});

  @override
  _FruitsPageState createState() => _FruitsPageState();
}

class _FruitsPageState extends State<FruitsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  List<double> _priceList = []; // List to hold pasted prices

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Products',
          style: TextStyle(
            color: Colors.white, // Change text color to white
          ),
        ),
        backgroundColor: Colors.indigo[900], // Dark blue
        actions: [
          TextButton(
            onPressed: () {
              _navigateToFruitsPage(context);
            },
            child: const Text(
              'Fruits',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.0,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildProductList()),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProductDialog(context),
        tooltip: 'Add Product',
        backgroundColor: Colors.indigo[900], // Dark blue
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _reload,
            ),
            IconButton(
              icon: const Icon(Icons.paste),
              onPressed: () {
                _showPastePricesDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('Fruits').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No products available.'));
        }

        return ListView(
          children: snapshot.data!.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            TextEditingController priceController =
            TextEditingController(text: data['price'].toString());
            TextEditingController nameController =
            TextEditingController(text: data['name']);
            return ListTile(
              title: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Product Name'),
                    ),
                  ),
                  const SizedBox(width: 16), // Adjust the width as needed
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16), // Adjust the width as needed
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          flex: 1,
                          child: ElevatedButton(
                            onPressed: () {
                              _updateProduct(
                                doc.id,
                                nameController.text,
                                double.parse(priceController.text),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor: Colors.indigo[900], // Dark blue
                              foregroundColor: Colors.white,
                            ),
                            child: const Icon(Icons.update),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          flex: 1,
                          child: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              _deleteProductConfirmation(doc.id);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _showAddProductDialog(BuildContext context) async {
    final TextEditingController urlController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Product'),
          backgroundColor: Colors.white,
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Product Name'),
                ),
                TextField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(labelText: 'Image URL'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _addProduct(
                  _nameController.text,
                  double.parse(_priceController.text),
                  urlController.text,
                );
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addProduct(String name, double price, String url) {
    _firestore.collection('Fruits').add({
      'name': name,
      'price': price,
      'url': url,
    });
  }

  void _updateProduct(String productId, String newName, double newPrice) {
    _firestore.collection('Fruits').doc(productId).update({
      'name': newName,
      'price': newPrice,
    });
  }

  void _reload() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content: const Text('Are you sure you want to reload?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performReload();
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  void _performReload() {
    _firestore.collection('Fruits').get().then((snapshot) {
      for (var doc in snapshot.docs) {
        _firestore.collection('Fruits').doc(doc.id).update({'price': 0});
      }
    });
  }

  void _deleteProduct(String productId) {
    _firestore.collection('Fruits').doc(productId).delete();
  }

  void _deleteProductConfirmation(String productId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content: const Text('Are you sure you want to delete this product?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                _deleteProduct(productId);
                Navigator.of(context).pop();
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  void _showPastePricesDialog(BuildContext context) {
    final TextEditingController pasteController = TextEditingController();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Paste Prices'),
          backgroundColor: Colors.white,
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextField(
                  controller: pasteController,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  decoration: const InputDecoration(
                    labelText: 'Enter prices (one per line)',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _parseAndSetPrices(pasteController.text);
                Navigator.of(context).pop();
              },
              child: const Text('Paste'),
            ),
          ],
        );
      },
    );
  }

  void _parseAndSetPrices(String pricesText) {
    List<String> lines = pricesText.split('\n');
    List<double> prices = [];

    for (String line in lines) {
      if (line.isNotEmpty) {
        prices.add(double.parse(line.trim()));
      }
    }

    setState(() {
      _priceList = prices;
    });

    _updateProducts();
  }

  void _updateProducts() {
    int index = 0;
    _firestore.collection('Fruits').get().then((snapshot) {
      for (var doc in snapshot.docs) {
        if (index < _priceList.length) {
          double price = _priceList[index];
          _firestore.collection('Fruits').doc(doc.id).update({'price': price});
          index++;
        }
      }
    });
  }

  void _navigateToFruitsPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FruitsPage()),
    );
  }
}
