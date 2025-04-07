import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_sultan/provider/city_provider.dart';

class CompletedOrdersList extends ConsumerStatefulWidget {
  const CompletedOrdersList({super.key});

  @override
  ConsumerState<CompletedOrdersList> createState() =>
      _CompletedOrdersListState();
}

class _CompletedOrdersListState extends ConsumerState<CompletedOrdersList> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String selectedCity;
  List<String> _phoneNumbers = [];
  int _largeCounter = 0;
  int _smallCounter = 0;
  bool _isLoading = true;

  // Maps to store button states for each order
  final Map<String, bool> _largeButtonStates = {};
  final Map<String, bool> _smallButtonStates = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Get the selected city from the provider, default to 'Lahore' if null
    selectedCity = ref.read(cityProvider) ?? 'Lahore';
    await _fetchCounters();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchCounters() async {
    final countersSnapshot = await _firestore
        .collection('Cities')
        .doc(selectedCity)
        .collection('order_counters')
        .doc('counters')
        .get();

    if (countersSnapshot.exists) {
      setState(() {
        _largeCounter = countersSnapshot.data()?['large'] ?? 0;
        _smallCounter = countersSnapshot.data()?['small'] ?? 0;
      });
    }
  }

  Future<void> _fetchButtonStates(String orderId) async {
    final buttonStatesSnapshot = await _firestore
        .collection('Cities')
        .doc(selectedCity)
        .collection('button_states')
        .doc(orderId)
        .get();

    if (buttonStatesSnapshot.exists) {
      setState(() {
        _largeButtonStates[orderId] =
            buttonStatesSnapshot.data()?['large'] ?? false;
        _smallButtonStates[orderId] =
            buttonStatesSnapshot.data()?['small'] ?? false;
      });
    }
  }

  void _incrementCounter(String counterType) {
    setState(() {
      if (counterType == 'large') {
        _largeCounter++;
      } else if (counterType == 'small') {
        _smallCounter++;
      }
    });
    _updateCounterInFirestore();
  }

  void _updateCounterInFirestore() {
    _firestore
        .collection('Cities')
        .doc(selectedCity)
        .collection('order_counters')
        .doc('counters')
        .set({
      'large': _largeCounter,
      'small': _smallCounter,
    });
  }

  void _updateButtonStateInFirestore(
      String orderId, bool isLargeDisabled, bool isSmallDisabled) {
    _firestore
        .collection('Cities')
        .doc(selectedCity)
        .collection('button_states')
        .doc(orderId)
        .set({
      'large': isLargeDisabled,
      'small': isSmallDisabled,
    });
  }

  void _promptForCode() async {
    final codeController = TextEditingController();

    final code = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Code to Clear Counters'),
          content: TextField(
            controller: codeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Enter code'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(codeController.text);
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (code == '786') {
      _clearCounters();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect code!')),
      );
    }
  }

  void _clearCounters() {
    setState(() {
      _largeCounter = 0;
      _smallCounter = 0;
      _largeButtonStates.clear(); // Reset button states
      _smallButtonStates.clear();
    });
    _updateCounterInFirestore();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Counters cleared!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen for changes to the selected city
    final currentCity = ref.watch(cityProvider);

    // If city changes, update and refetch data
    if (currentCity != null && currentCity != selectedCity) {
      selectedCity = currentCity;
      _fetchCounters();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Completed Orders - $selectedCity'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(); // Navigate back to the previous screen
          },
        ),
        actions: [
          IconButton(
              onPressed: () {
                _promptForCode();
              },
              icon: const Icon(Icons.clear)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // City selection information
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          const Icon(Icons.location_city, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            'Selected City: $selectedCity',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Large: $_largeCounter',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton(
                        onPressed: _copyAllPhoneNumbers,
                        child: const Text('Copy All Numbers'),
                      ),
                      Text(
                        'Small: $_smallCounter',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('Cities')
                        .doc(selectedCity)
                        .collection('completed_orders')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final orders = snapshot.data?.docs ?? [];
                      _phoneNumbers = [];

                      if (orders.isEmpty) {
                        return const Center(child: Text('No orders found.'));
                      }

                      return ListView.builder(
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          final orderData =
                              order.data() as Map<String, dynamic>;
                          final orderId = order.id;
                          final address = orderData['address'] as String? ?? '';
                          final grandTotal = orderData['grandTotal'] is double
                              ? orderData['grandTotal'].toString()
                              : '0.0';
                          final name = orderData['name'] as String? ?? '';
                          final orderCount =
                              orderData['orderCount'] as int? ?? 0;
                          final phoneNumber =
                              orderData['phoneNumber'] as String? ?? '';
                          final timestamp =
                              orderData['timestamp'] as Timestamp?;
                          final date = timestamp != null
                              ? timestamp.toDate()
                              : DateTime.now();

                          // Fetch button states from Firestore if not already fetched
                          if (_largeButtonStates[orderId] == null &&
                              _smallButtonStates[orderId] == null) {
                            _fetchButtonStates(orderId);
                          }

                          // Calculate the color based on the date difference
                          final currentDate = DateTime.now();
                          final difference =
                              currentDate.difference(date).inDays;
                          final color =
                              difference > 7 ? Colors.red : Colors.green;

                          _phoneNumbers.add(phoneNumber);

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                vertical: 5, horizontal: 10),
                            child: Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            color: color,
                                            child: Text(
                                              '$orderCount',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 25,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                              onPressed: () =>
                                                  _copyPhoneNumber(phoneNumber),
                                              icon: const Icon(Icons.copy)),
                                          Text(
                                            'Days: $difference',
                                            style: TextStyle(
                                              color: color,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text('Name: $name'),
                                      Text('Address: $address'),
                                      Text('Phone: $phoneNumber'),
                                      Text('Grand Total: $grandTotal'),
                                      Text(
                                          'Date: ${date.toString().substring(0, 16)}'),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          ElevatedButton(
                                            onPressed: _largeButtonStates[
                                                        orderId] ==
                                                    true
                                                ? null
                                                : () {
                                                    _incrementCounter('large');
                                                    setState(() {
                                                      _largeButtonStates[
                                                          orderId] = true;
                                                    });
                                                    _updateButtonStateInFirestore(
                                                        orderId,
                                                        true,
                                                        _smallButtonStates[
                                                                orderId] ??
                                                            false);
                                                  },
                                            child: const Text('Large'),
                                          ),
                                          ElevatedButton(
                                            onPressed: _smallButtonStates[
                                                        orderId] ==
                                                    true
                                                ? null
                                                : () {
                                                    _incrementCounter('small');
                                                    setState(() {
                                                      _smallButtonStates[
                                                          orderId] = true;
                                                    });
                                                    _updateButtonStateInFirestore(
                                                        orderId,
                                                        _largeButtonStates[
                                                                orderId] ??
                                                            false,
                                                        true);
                                                  },
                                            child: const Text('Small'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () =>
                                                _resetOrder(orderId),
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red),
                                            child: const Text('Reset'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (difference > 14)
                                  const Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Icon(
                                      Icons.warning,
                                      color: Colors.red,
                                      size: 30,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _copyPhoneNumber(String phoneNumber) async {
    await Clipboard.setData(ClipboardData(text: phoneNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Phone number copied to clipboard')),
    );
  }

  Future<void> _copyAllPhoneNumbers() async {
    if (_phoneNumbers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone numbers to copy')),
      );
      return;
    }

    final allNumbers = _phoneNumbers.join('\n');
    await Clipboard.setData(ClipboardData(text: allNumbers));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_phoneNumbers.length} phone numbers copied')),
    );
  }

  void _resetOrder(String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Order'),
        content: const Text(
            'This will reset the Large and Small buttons for this order. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _largeButtonStates[orderId] = false;
                _smallButtonStates[orderId] = false;
              });
              _updateButtonStateInFirestore(orderId, false, false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Order reset successfully')),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
