import 'package:flutter/material.dart';
import 'package:green_sultan/change_veggies_price/water/water_product_list_view.dart';
import 'package:green_sultan/change_veggies_price/water/water_product_add_form.dart';
import 'package:green_sultan/features/home/views/categories_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/city_provider.dart';
import '../../provider/selected_city_provider.dart';
import '../../provider/user_provider.dart';

class WaterPriceScreen extends ConsumerStatefulWidget {
  const WaterPriceScreen({super.key});

  @override
  ConsumerState<WaterPriceScreen> createState() => WaterPriceScreenState();
}

class WaterPriceScreenState extends ConsumerState<WaterPriceScreen> {
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
        ],
      ),
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
                      color: _isSearching ? Colors.blue : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search water products...',
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
                      color: Colors.blue.shade700, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Search results for "$_searchQuery"',
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // Products list
          Expanded(
            child: WaterProductListView(
                isPinVerified: false, searchQuery: _searchQuery),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WaterProductAddForm()),
          ).then((_) => setState(() {})); // Refresh after returning
        },
        icon: const Icon(Icons.add),
        label: const Text('ADD WATER PRODUCT'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.water_drop, color: Colors.blue),
              tooltip: 'Water Products',
              onPressed: () {
                // Already on water products screen
              },
            ),
            IconButton(
              icon: const Icon(Icons.inventory_2, color: Colors.blue),
              tooltip: 'Products',
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