import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'NewOrders.dart';
import 'components/drawer.dart';
import 'total.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_sultan/provider/user_provider.dart';

class MessageScreen1 extends ConsumerStatefulWidget {
  const MessageScreen1({super.key});

  @override
  ConsumerState<MessageScreen1> createState() => _MessageScreen1State();
}

class _MessageScreen1State extends ConsumerState<MessageScreen1> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    // initBluetooth();
    requestBluetoothPermissions(); // Request Bluetooth permissions
  }

  Future<void> requestBluetoothPermissions() async {
    final statusConnect = await Permission.bluetoothConnect.status;
    if (!statusConnect.isGranted) {
      await Permission.bluetoothConnect.request();
    }

    final statusScan = await Permission.bluetoothScan.status;
    if (!statusScan.isGranted) {
      await Permission.bluetoothScan.request();
    }
  }

  void _deleteMessage(String messageId) {
    _firestore
        .collection('Cities') // Top-level collection
        .doc('Lahore') // Specific document
        .collection('Orders History') // Sub-collection
        .doc(messageId) // Target document ID
        .delete();
  }

  void _navigateToOrderDetail(Map<String, double> itemCounts) {
    final orderDetailsCollection = _firestore
        .collection('Cities')
        .doc('Lahore')
        .collection('OrderDetails');

    // Delete existing order details
    orderDetailsCollection.get().then((querySnapshot) {
      for (var doc in querySnapshot.docs) {
        doc.reference.delete();
      }

      _firestore.collection('OrderDetails').add({
        'name': 'name',
        'itemCounts': itemCounts,
        'timestamp': Timestamp.now(),
      }).then((docRef) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => MainOrderDetailScreen(itemCounts)),
        );
      }).catchError((error) {
        print('Failed to save order detail data: $error');
      });
    }).catchError((error) {
      print('Error deleting existing data: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    // Always allow access to riders, check permission for other roles if needed
    final userRole = ref.watch(userRoleProvider).toLowerCase();
    final hasAccess = userRole == 'rider' ||
        ref.read(hasPermissionProvider('LiveHaraDhaniya'));

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

      // Return a loading indicator until the redirect happens
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Center(
          child: Text('Orders'),
        ),
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('Cities') // Top-level collection
                  .doc('Lahore') // Specific document
                  .collection('Orders History') // Sub-collection
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                final messages = snapshot.data!.docs.reversed;
                return ListView(
                  reverse: true,
                  children: messages.map((DocumentSnapshot document) {
                    final messageText = document['message'];
                    final messageDate = document['timestamp'] as Timestamp;
                    final messageId = document.id;
                    return Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: ListTile(
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Order Details:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                messageText,
                                maxLines: null,
                              ),
                            ],
                          ),
                          subtitle: Text(
                            'Date: ${messageDate.toDate().toString()}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // IconButton(
                              //   icon: const Icon(Icons.print),
                              //   onPressed: () {
                              //     _showPrintDialog(messageText);
                              //   },
                              // ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  _deleteMessage(messageId);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.green[800],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.pageview, color: Colors.white),
              onPressed: () {
                _firestore
                    .collection('Cities') // Top-level collection
                    .doc('Lahore') // Specific document
                    .collection('Orders History') // Sub-collection
                    .get()
                    .then((querySnapshot) {
                  Map<String, double> itemCounts = {};
                  for (var document in querySnapshot.docs) {
                    final messageText = document['message'];
                    final lines = messageText.split('\n');

                    lines.forEach((line) {
                      final pattern =
                          RegExp(r'\(([^)]+)\)\s*(.*)\s+\|Qty:\s*([\d\.]+)');
                      final match = pattern.firstMatch(line);
                      if (match != null) {
                        final itemName = '${match.group(1)} ${match.group(2)}';
                        final itemQty = double.parse(match.group(3)!);
                        itemCounts[itemName] =
                            (itemCounts[itemName] ?? 0) + itemQty;
                      }
                    });
                  }

                  _navigateToOrderDetail(itemCounts);
                });
              },
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Totals()),
                );
              },
              child: const Text(
                "Total",
                style: TextStyle(color: Colors.white),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.new_releases, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MessageScreen2()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class MainOrderDetailScreen extends StatelessWidget {
  final Map<String, double> itemCounts;

  const MainOrderDetailScreen(this.itemCounts, {super.key});

  @override
  Widget build(BuildContext context) {
    final totalItemCount = itemCounts.length;
    final totalQuantity =
        itemCounts.values.fold(0.0, (sum, quantity) => sum + quantity);

    // Format the order details as a string with extra newline for each item
    String formatOrderDetails() {
      final buffer = StringBuffer();
      buffer.writeln('Total Items: $totalItemCount');
      buffer.writeln('Total Quantity: $totalQuantity');
      buffer.writeln();
      itemCounts.forEach((key, value) {
        buffer.writeln('$key: $value\n');
      });
      return buffer.toString();
    }

    // Method to copy the formatted order details to clipboard
    void copyToClipboard() {
      final orderDetails = formatOrderDetails();
      Clipboard.setData(ClipboardData(text: orderDetails));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order details copied to clipboard')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details (Main Screen)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: copyToClipboard,
          ),
        ],
      ),
      body: Column(
        children: [
          ListTile(
            title: Text('Total Items: $totalItemCount'),
            subtitle: Text('Total Quantity: $totalQuantity'),
          ),
          Expanded(
            child: ListView(
              children: itemCounts.entries.map((entry) {
                return ListTile(
                  title: Text('${entry.key}: ${entry.value}'),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
