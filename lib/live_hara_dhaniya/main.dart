import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'NewOrders.dart';
import 'components/drawer.dart';
import 'total.dart';


class MessageScreen1 extends StatefulWidget {
  const MessageScreen1({super.key});

  @override
  _MessageScreen1State createState() => _MessageScreen1State();
}

class _MessageScreen1State extends State<MessageScreen1> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  // List<BluetoothDevice> _devices = [];
  // BluetoothDevice? _selectedDevice;

  @override
  void initState() {
    super.initState();
    // initBluetooth();
    requestBluetoothPermissions(); // Request Bluetooth permissions
  }

  // void initBluetooth() async {
  //   bool isConnected = (await bluetooth.isConnected) ?? false;
  //   if (!isConnected) {
  //     refreshDevices();
  //   }
  // }
  //
  // void refreshDevices() async {
  //   _devices = await bluetooth.getBondedDevices();
  //   setState(() {});
  // }

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

  // void _showPrintDialog(String message) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: const Text('Order Details'),
  //         content: SingleChildScrollView(
  //           child: Text(message),
  //         ),
  //         actions: [
  //           DropdownButton<BluetoothDevice>(
  //             hint: const Text('Select Bluetooth Printer'),
  //             value: _selectedDevice,
  //             onChanged: (BluetoothDevice? device) {
  //               setState(() {
  //                 _selectedDevice = device;
  //               });
  //             },
  //             items: _devices
  //                 .map((device) => DropdownMenuItem(
  //               value: device,
  //               child: Text(device.name!),
  //             ))
  //                 .toList(),
  //           ),
  //           // TextButton(
  //           //   onPressed: () {
  //           //     _printMessage(message);
  //           //     Navigator.of(context).pop();
  //           //   },
  //           //   child: const Text('Print'),
  //           // ),
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //             child: const Text('Close'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }
  //
  // void _printMessage(String message) async {
  //   if (_selectedDevice != null) {
  //     await bluetooth.connect(_selectedDevice!);
  //
  //     // ESC/POS command to select UTF-8 encoding
  //     final escPosUtf8 = Uint8List.fromList([0x1B, 0x74, 0x11]);
  //
  //     // ESC/POS command to select custom font (replace with actual command if different)
  //     final selectCustomFont = Uint8List.fromList([0x1B, 0x33, 0x01]); // Example command, may vary for your printer
  //
  //     // ESC/POS command to set text size (optional)
  //     final textSize = Uint8List.fromList([0x1B, 0x21, 0x00]);
  //
  //     // ESC/POS command to print and feed
  //     final printAndFeed = Uint8List.fromList([0x0A]);
  //
  //     // Send ESC/POS commands to configure the printer
  //     bluetooth.writeBytes(escPosUtf8);
  //     bluetooth.writeBytes(selectCustomFont);
  //     bluetooth.writeBytes(textSize);
  //
  //     // Send the encoded message
  //     bluetooth.writeBytes(Uint8List.fromList(utf8.encode(message)));
  //
  //     // Add line feed and perform the printing
  //     bluetooth.writeBytes(printAndFeed);
  //
  //     bluetooth.printNewLine();
  //     bluetooth.printNewLine();
  //     bluetooth.printNewLine();
  //     await bluetooth.disconnect();
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Please select a Bluetooth printer')),
  //     );
  //   }
  // }

  void _deleteMessage(String messageId) {
    _firestore.collection('Orders History').doc(messageId).delete();
  }

  void _sendMessage(String message) {
    Timestamp timestamp = Timestamp.now(); // Generate timestamp once
    _firestore.collection('Orders History').add({
      'message': message,
      'timestamp': timestamp, // Use the same timestamp for the entire message
    });
    _controller.clear();
  }

  void _navigateToOrderDetail(Map<String, double> itemCounts) {
    _firestore.collection('OrderDetails').get().then((querySnapshot) {
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
          MaterialPageRoute(builder: (context) => MainOrderDetailScreen(itemCounts)),
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
              stream: _firestore.collection('Orders History').snapshots(),
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
          // Padding(
          //   padding: const EdgeInsets.all(8.0),
          //   child: Container(
          //     height: 200,
          //     decoration: BoxDecoration(
          //       border: Border.all(color: Colors.grey),
          //       borderRadius: BorderRadius.circular(8.0),
          //     ),
          //     child: SingleChildScrollView(
          //       child: Padding(
          //         padding: const EdgeInsets.symmetric(horizontal: 8.0),
          //         child: TextField(
          //           controller: _controller,
          //           decoration: const InputDecoration(
          //             hintText: 'Type your order...',
          //             border: InputBorder.none,
          //           ),
          //           keyboardType: TextInputType.multiline,
          //           maxLines: null,
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
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
                _firestore.collection('Orders History').get().then((querySnapshot) {
                  Map<String, double> itemCounts = {};
                  for (var document in querySnapshot.docs) {
                    final messageText = document['message'];
                    final lines = messageText.split('\n');

                    lines.forEach((line) {
                      final pattern = RegExp(r'\(([^)]+)\)\s*(.*)\s+\|Qty:\s*([\d\.]+)');
                      final match = pattern.firstMatch(line);
                      if (match != null) {
                        final itemName = '${match.group(1)} ${match.group(2)}';
                        final itemQty = double.parse(match.group(3)!);
                        itemCounts[itemName] = (itemCounts[itemName] ?? 0) + itemQty;
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
              icon: const Icon(Icons.new_releases,  color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MessageScreen2()),
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
    final totalQuantity = itemCounts.values.fold(0.0, (sum, quantity) => sum + quantity);

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
