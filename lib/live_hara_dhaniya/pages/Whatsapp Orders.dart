import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WhatsappOrders extends StatelessWidget {
  const WhatsappOrders({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: false),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Orders WhatsApp',
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.blue,
          actions: const [],
        ),
        body: const OrdersList(),
      ),
    );
  }
}

class OrdersList extends StatefulWidget {
  const OrdersList({super.key});

  @override
  _OrdersListState createState() => _OrdersListState();
}

class _OrdersListState extends State<OrdersList> {
  final CollectionReference ordersCollection =
      FirebaseFirestore.instance.collection('Whatsapp Orders');
  final CollectionReference orderHistoryCollection =
      FirebaseFirestore.instance.collection('Whatsapp Order History');
  final CollectionReference completedOrdersCollection =
      FirebaseFirestore.instance.collection('completed_orders');
  final CollectionReference phoneNumbersCollection =
      FirebaseFirestore.instance.collection('phone_numbers');

  String? _enteredName;

  @override
  void initState() {
    super.initState();
    _loadEnteredName();
  }

  Future<void> _loadEnteredName() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _enteredName = prefs.getString('enteredName');
    });
  }

  Future<void> _saveAllOrders(BuildContext context) async {
    try {
      final QuerySnapshot querySnapshot = await ordersCollection.get();
      for (final order in querySnapshot.docs) {
        final customerDetails = order['customerDetails'] ?? 'N/A';
        final details = _extractDetails(customerDetails);

        // Check if the phone number already exists in `completed_orders` collection
        final existingOrderSnapshot = await completedOrdersCollection
            .where('phoneNumber', isEqualTo: details['phoneNumber'])
            .get();

        if (existingOrderSnapshot.docs.isNotEmpty) {
          // If the phone number exists, update the existing document
          final docRef = existingOrderSnapshot.docs.first.reference;
          await docRef.update({
            'orderCount': FieldValue.increment(1),
            'timestamp': DateTime
                .now(), // Update the timestamp to reflect the latest order
            'grandTotal': details['grandTotal'], // Update grand total
          });
        } else {
          // If phone number is not found, save the order with an order count of 1
          await completedOrdersCollection.add({
            'name': details['name'],
            'address': details['address'],
            'phoneNumber': details['phoneNumber'],
            'orderCount': 1, // Start the counter with 1
            'timestamp':
                (order['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
            'grandTotal': details['grandTotal'], // Save grand total
          });
        }

        // Update or create the record in `phone_numbers` collection
        final querySnapshotPhoneNumbers = await phoneNumbersCollection
            .where('phoneNumber', isEqualTo: details['phoneNumber'])
            .get();

        if (querySnapshotPhoneNumbers.docs.isNotEmpty) {
          // Phone number already exists, update the existing document
          final docRef = querySnapshotPhoneNumbers.docs.first.reference;
          await docRef.update({
            'count': FieldValue.increment(1),
            'lastOrderDate': DateTime.now(),
          });
        } else {
          // Phone number does not exist, create a new record
          await phoneNumbersCollection.add({
            'phoneNumber': details['phoneNumber'],
            'count': 1,
            'firstOrderDate': DateTime.now(),
            'lastOrderDate': DateTime.now(),
          });
        }
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('All orders saved.')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _transferOrdersToHistory(BuildContext context) async {
    try {
      final QuerySnapshot querySnapshot = await ordersCollection.get();

      for (QueryDocumentSnapshot order in querySnapshot.docs) {
        // Add each order to the "Whatsapp Order History" collection
        await orderHistoryCollection.add(order.data());
        // Delete the order from the "Whatsapp Orders" collection
        await order.reference.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Orders transferred to history and cleared.')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _saveAndTransferOrders(BuildContext context) async {
    await _saveAllOrders(context);
    await _transferOrdersToHistory(context);
  }

  String formatOrderSummary(String orderSummary) {
    final regex = RegExp(r'\s+\|\s+');
    return orderSummary.replaceAll(regex, ' | ');
  }

  Map<String, dynamic> _extractDetails(String customerDetails) {
    final lines = customerDetails.split('\n');
    final name = lines.isNotEmpty ? lines[0].trim() : '';
    final address = lines.length > 1 ? lines[1].trim() : '';
    final phoneNumber =
        lines.length > 2 ? lines[2].replaceAll('number ', '').trim() : '';

    // Find and extract the grand total
    final grandTotalLine = lines.firstWhere(
      (line) => line.toLowerCase().startsWith('grand total:'),
      orElse: () => 'Grand Total: 0.00',
    );
    final grandTotalString = grandTotalLine.split(':').last.trim();

    print('Grand total string: $grandTotalString'); // Debug print statement

    // Remove any non-numeric characters and convert to double
    final grandTotal = double.tryParse(
            grandTotalString.replaceAll(',', '').replaceAll(' ', '')) ??
        0.0;
    print('Extracted grand total: $grandTotal'); // Debug print statement

    return {
      'name': name,
      'address': address,
      'phoneNumber': phoneNumber,
      'grandTotal': grandTotal,
    };
  }

  Future<void> _deleteOrder(BuildContext context, String orderId) async {
    try {
      await ordersCollection.doc(orderId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order deleted successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting order: $e')),
      );
    }
  }

  Future<void> _copyOrderToClipboard(BuildContext context,
      String customerDetails, String orderSummary, DateTime timestamp) async {
    final orderDetails = '''
Order Details:
$customerDetails
Order Summary:
$orderSummary
Timestamp: $timestamp
''';

    await Clipboard.setData(ClipboardData(text: orderDetails));
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order details copied to clipboard.')));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: ordersCollection
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No orders found.'));
              }

              final orders = snapshot.data!.docs;

              return ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final customerDetails = order['customerDetails'] ?? 'N/A';
                  final orderSummary = order['orderSummary'] ?? 'N/A';
                  final timestamp =
                      (order['timestamp'] as Timestamp?)?.toDate() ??
                          DateTime.now();
                  final riderName = _enteredName ??
                      'Rider'; // Use the stored entered name or a default

                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Order ${index + 1}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    _deleteOrder(context, order.id),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8.0),
                          Text('$customerDetails'),
                          const SizedBox(height: 4.0),
                          Text(formatOrderSummary(orderSummary)),
                          const SizedBox(height: 4.0),
                          Text('Timestamp: $timestamp'),
                          const SizedBox(height: 8.0),
                          ElevatedButton(
                            onPressed: () => _copyOrderToClipboard(context,
                                customerDetails, orderSummary, timestamp),
                            child: const Text('Copy Order'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: () => _saveAndTransferOrders(context),
            child: const Text('Save All Orders and Transfer to History'),
          ),
        ),
      ],
    );
  }
}