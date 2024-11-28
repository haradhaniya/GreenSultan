import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CompletedOrdersList extends StatefulWidget {
  const CompletedOrdersList({super.key});

  @override
  _CompletedOrdersListState createState() => _CompletedOrdersListState();
}

class _CompletedOrdersListState extends State<CompletedOrdersList> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> _phoneNumbers = [];
  int _largeCounter = 0;
  int _smallCounter = 0;

  // Maps to store button states for each order
  Map<String, bool> _largeButtonStates = {};
  Map<String, bool> _smallButtonStates = {};

  @override
  void initState() {
    super.initState();
    _fetchCounters(); // Fetch counters from Firestore when the screen loads
  }

  Future<void> _fetchCounters() async {
    final countersSnapshot =
    await _firestore.collection('order_counters').doc('counters').get();
    if (countersSnapshot.exists) {
      setState(() {
        _largeCounter = countersSnapshot.data()?['large'] ?? 0;
        _smallCounter = countersSnapshot.data()?['small'] ?? 0;
      });
    }
  }

  Future<void> _fetchButtonStates(String orderId) async {
    final buttonStatesSnapshot =
    await _firestore.collection('button_states').doc(orderId).get();
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
    _firestore.collection('order_counters').doc('counters').set({
      'large': _largeCounter,
      'small': _smallCounter,
    });
  }

  void _updateButtonStateInFirestore(String orderId, bool isLargeDisabled,
      bool isSmallDisabled) {
    _firestore.collection('button_states').doc(orderId).set({
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Orders'),
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
      body: Column(
        children: [
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
                  .collection('Cities') // Navigate to Cities collection
                  .doc('Lahore') // Reference the Lahore document
                  .collection('completed_orders') // Access the completed_orders subcollection
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
                    final orderData = order.data() as Map<String, dynamic>;
                    final orderId = order.id;
                    final address = orderData['address'] as String? ?? '';
                    final grandTotal = orderData['grandTotal'] is double
                        ? orderData['grandTotal'].toString()
                        : '0.0';
                    final name = orderData['name'] as String? ?? '';
                    final orderCount = orderData['orderCount'] as int? ?? 0;
                    final phoneNumber = orderData['phoneNumber'] as String? ?? '';
                    final timestamp = orderData['timestamp'] as Timestamp?;
                    final date = timestamp != null ? timestamp.toDate() : DateTime.now();

                    // Fetch button states from Firestore if not already fetched
                    if (_largeButtonStates[orderId] == null &&
                        _smallButtonStates[orderId] == null) {
                      _fetchButtonStates(orderId);
                    }

                    // Calculate the color based on the date difference
                    final currentDate = DateTime.now();
                    final difference = currentDate.difference(date).inDays;
                    final color = difference > 7 ? Colors.red : Colors.green;

                    _phoneNumbers.add(phoneNumber);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                        onPressed: () => _copyPhoneNumber(phoneNumber),
                                        icon: Icon(Icons.copy)),
                                    Text(
                                      'Days: $difference',
                                      style: TextStyle(
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple,
                                        letterSpacing: 1.2,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 2.0,
                                            color: Colors.grey,
                                            offset: Offset(2.0, 2.0),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text('Name: $name'),
                                Text('Address: $address'),
                                Text('Phone Number: $phoneNumber'),
                                Text('Grand Total: $grandTotal'),
                                Text('Date: ${date.toString()}'),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    ElevatedButton(
                                      onPressed: _largeButtonStates[orderId] == true
                                          ? null
                                          : () {
                                        setState(() {
                                          _largeButtonStates[orderId] = true;
                                          _incrementCounter('large');
                                          _updateButtonStateInFirestore(
                                            orderId,
                                            _largeButtonStates[orderId]!,
                                            _smallButtonStates[orderId] ?? false,
                                          );
                                        });
                                      },
                                      child: const Text('Large'),
                                    ),
                                    ElevatedButton(
                                      onPressed: _smallButtonStates[orderId] == true
                                          ? null
                                          : () {
                                        setState(() {
                                          _smallButtonStates[orderId] = true;
                                          _incrementCounter('small');
                                          _updateButtonStateInFirestore(
                                            orderId,
                                            _largeButtonStates[orderId] ?? false,
                                            _smallButtonStates[orderId]!,
                                          );
                                        });
                                      },
                                      child: const Text('Small'),
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
            ),
          ),
        ],
      ),
    );
  }

  void _copyPhoneNumber(String phoneNumber) {
    Clipboard.setData(ClipboardData(text: phoneNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Phone number copied to clipboard!')),
    );
  }

  void _copyAllPhoneNumbers() {
    final allPhoneNumbers = _phoneNumbers.join(', ');
    Clipboard.setData(ClipboardData(text: allPhoneNumbers));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All phone numbers copied to clipboard!')),
    );
  }
}
