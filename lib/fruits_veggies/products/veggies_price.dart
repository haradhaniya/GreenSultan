import 'package:flutter/material.dart';
import 'package:green_sultan/fruits_veggies/components/appbar.dart';
import 'package:green_sultan/fruits_veggies/products/productList.dart';
import 'package:green_sultan/fruits_veggies/products/product_add_form.dart';

class ProductList extends StatefulWidget {
  const ProductList({super.key});

  @override
  _ProductListState createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ProductAppBar(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Products',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child:
                ProductsList(isPinVerified: false, searchQuery: _searchQuery),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddProductScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class PinCodeScreen extends StatefulWidget {
  const PinCodeScreen({super.key});

  @override
  State<PinCodeScreen> createState() => _PinCodeScreenState();
}

class _PinCodeScreenState extends State<PinCodeScreen> {
  final TextEditingController _pinController = TextEditingController();
  final String _correctPin = '786'; // Correct PIN
  bool _isPinVerified = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter PIN'),
        centerTitle: true,
        backgroundColor: Colors.green,
        elevation: 4,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Please Enter Your PIN',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _pinController,
                    decoration: InputDecoration(
                      labelText: 'PIN',
                      prefixIcon: const Icon(Icons.lock, color: Colors.green),
                      filled: true,
                      fillColor: Colors.green.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.green, width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    obscureText: true, // Hide PIN characters
                    maxLength: 4, // Limit PIN length to 4
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      _verifyPin(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Submit',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _verifyPin(BuildContext context) {
    if (_pinController.text == _correctPin) {
      setState(() {
        _isPinVerified = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('PIN Verified Successfully'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ProductFruitsListWithPin(isPinVerified: _isPinVerified),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Incorrect PIN'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ));
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }
}

class ProductFruitsListWithPin extends StatelessWidget {
  final bool isPinVerified;

  const ProductFruitsListWithPin({super.key, required this.isPinVerified});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Upload (PIN Verified)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_open),
            onPressed: () {
              Navigator.pop(context); // Close PIN-verified screen
            },
          ),
        ],
      ),
      body: ProductsList(isPinVerified: isPinVerified, searchQuery: ''),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddProductScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}


