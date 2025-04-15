import 'package:flutter/material.dart';
import 'package:green_sultan/change_veggies_price/veggies/productList.dart';
import 'package:green_sultan/change_veggies_price/veggies/product_add_form.dart';
import 'package:green_sultan/features/home/views/categories_screen.dart';
import '../components/appbar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/city_provider.dart';
import '../../provider/selected_city_provider.dart';
import '../../provider/user_provider.dart';

class VeggiesListScreen extends ConsumerStatefulWidget {
  const VeggiesListScreen({super.key});

  @override
  ConsumerState<VeggiesListScreen> createState() => VeggiesListScreenState();
}

class VeggiesListScreenState extends ConsumerState<VeggiesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });

    // Fetch cities list from Firestore but don't change selected city
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only fetch the list of available cities
      ref.read(cityProvider2.notifier).fetchCities();

      // Don't override user's selected city here
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedCity = ref.watch(cityProvider) ?? '';

    // Check access rights immediately before rendering
    final hasAccess = ref.read(hasPermissionProvider('ChangePrices'));

    if (!hasAccess) {
      // If no access, redirect back or show an access denied screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('You do not have permission to access this section')),
        );
      });
    }

    return Scaffold(
      appBar: ProductAppBar(),
      body: Column(
        children: [
          // Enhanced search bar with animation
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 80,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Icon(
                      _isSearching ? Icons.search : Icons.search_outlined,
                      color: _isSearching ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search products...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onTap: () {
                          setState(() {
                            _isSearching = true;
                          });
                        },
                        onSubmitted: (_) {
                          setState(() {
                            _isSearching = _searchQuery.isNotEmpty;
                          });
                        },
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        color: Colors.grey,
                        onPressed: _clearSearch,
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Search result info
          if (_searchQuery.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.filter_list,
                      color: Colors.green.shade700, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Search results for "$_searchQuery"',
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // Products list
          Expanded(
            child: ProductListView(
                isPinVerified: false, searchQuery: _searchQuery),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddProductScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('ADD PRODUCT'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.category, color: Colors.green),
              tooltip: 'Categories',
              onPressed: () {
                if (selectedCity.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a city first'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoriesScreen(
                      selectedCity: selectedCity,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class PinVerificationScreen extends StatefulWidget {
  const PinVerificationScreen({super.key});

  @override
  State<PinVerificationScreen> createState() => _PinVerificationScreenState();
}

class _PinVerificationScreenState extends State<PinVerificationScreen> {
  final TextEditingController _pinController = TextEditingController();
  final String _correctPin = '786'; // Correct PIN
  bool _isPinVerified = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter PIN'),
        centerTitle: true,
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
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 20),
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
              ProductListWithPinScreen(isPinVerified: _isPinVerified),
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

class ProductListWithPinScreen extends ConsumerWidget {
  final bool isPinVerified;

  const ProductListWithPinScreen({super.key, required this.isPinVerified});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCity = ref.watch(cityProvider) ?? '';
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
      body: ProductListView(isPinVerified: isPinVerified, searchQuery: ''),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddProductScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.category, color: Colors.green),
              tooltip: 'Categories',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CategoriesScreen(selectedCity: '',)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
