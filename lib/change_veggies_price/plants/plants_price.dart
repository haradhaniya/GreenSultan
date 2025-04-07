import 'package:flutter/material.dart';
import 'package:green_sultan/change_veggies_price/plants/plants_add_form.dart';
import 'package:green_sultan/change_veggies_price/plants/plants_list.dart';
import 'components/plants_app_bar.dart';


class PlantsListBeforeVerification extends StatefulWidget {
  const PlantsListBeforeVerification({super.key});

  @override
  ProductListState createState() => ProductListState();
}

class ProductListState extends State<PlantsListBeforeVerification> {
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
      appBar: PlantsAppBar(),
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
            PlantsListAfterVerification(isPinVerified: false, searchQuery: _searchQuery),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddPlantsScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class PlantsPinCodeScreen extends StatefulWidget {
  const PlantsPinCodeScreen({super.key});

  @override
  State<PlantsPinCodeScreen> createState() => _PinCodeScreenState();
}

class _PinCodeScreenState extends State<PlantsPinCodeScreen> {
  final TextEditingController _pinController = TextEditingController();
  final String _correctPin = '786'; // Correct PIN
  bool _isPinVerified = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter PIN'),
        centerTitle: true,
        // backgroundColor: Colors.green,
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
                      // color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _pinController,
                    decoration: InputDecoration(
                      labelText: 'PIN',
                      prefixIcon: const Icon(Icons.lock),
                      filled: true,
                      fillColor: Colors.green.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(width: 2),
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
        duration: Duration(seconds: 2),
      ));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ProductPlantsListWithPin(isPinVerified: _isPinVerified),
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

class ProductPlantsListWithPin extends StatelessWidget {
  final bool isPinVerified;

  const ProductPlantsListWithPin({super.key, required this.isPinVerified});

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
      body: PlantsListAfterVerification(isPinVerified: isPinVerified, searchQuery: ''),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddPlantsScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}


