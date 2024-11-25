import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:green_sultan/live_hara_dhaniya/total.dart';
import 'package:intl/intl.dart';

class MessageScreen2 extends StatefulWidget {
  const MessageScreen2({super.key});

  @override
  _MessageScreen2State createState() => _MessageScreen2State();
}

class _MessageScreen2State extends State<MessageScreen2> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late SharedPreferences _prefs;
  Map<String, bool> _checkboxStates = {};
  bool _isNavigatingToDetail = false;

  @override
  void initState() {
    super.initState();
    _loadCheckboxStates();
  }

  Future<void> _loadCheckboxStates() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _checkboxStates = _prefs.getKeys().fold({}, (Map<String, bool> map, String key) {
        final value = _prefs.get(key);
        if (value is bool) {
          map[key] = value;
        } else {
          map[key] = false;
        }
        return map;
      });
    });
  }

  Future<void> _saveCheckboxState(String key, bool value) async {
    setState(() {
      _checkboxStates[key] = value;
    });
    await _prefs.setBool(key, value);
  }

  String _generateCheckboxKey(String messageId, String itemName) {
    return '$messageId-$itemName';
  }

  void _deleteMessage(String messageId) {
    _firestore.collection('Orders History').doc(messageId).delete();
  }

  void _sendMessage(String message) {
    String processedMessage = _processMessage(message);
    Timestamp timestamp = Timestamp.now();
    _firestore.collection('Orders History').add({
      'message': processedMessage,
      'timestamp': timestamp,
    });
    _controller.clear();
  }

  String _processMessage(String message) {
    return message.replaceAllMapped(
      RegExp(r'\*(\d+)\*'),
          (match) => match.group(1)!,
    ).replaceAll(RegExp(r'\| Qty'), '|Qty');
  }


  void _navigateToOrderDetail(Map<String, dynamic> itemCounts) {
    if (_isNavigatingToDetail) return;

    _isNavigatingToDetail = true;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewOrderDetailScreen(itemCounts),
      ),
    ).then((_) {
      _isNavigatingToDetail = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Message Orders'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('Orders History').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!.docs.reversed;
                return ListView(
                  reverse: true,
                  children: messages.map((DocumentSnapshot document) {
                    final messageText = document['message'];
                    final messageDate = document['timestamp'] as Timestamp;
                    final messageId = document.id;
                    final lines = messageText.split('\n').skip(3).toList();

                    return Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    messageText.split('\n').take(3).join('\n'),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 5),
                                  Text('Date: ${messageDate.toDate().toString()}'),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteMessage(messageId),
                              ),
                            ),
                            ...lines.map((line) {
                              final pattern = RegExp(r'^(\d+):\s*\(([^)]+)\)\s*([^|]+)\|Qty:\s*([\d\.]+)');
                              final match = pattern.firstMatch(line);
                              if (match != null) {
                                final itemNumber = match.group(1)!;
                                final itemName = '${match.group(2)} ${match.group(3)}';
                                final itemQty = double.parse(match.group(4)!);
                                final checkboxKey = _generateCheckboxKey(messageId, itemName);
                                final isChecked = _checkboxStates[checkboxKey] ?? false;

                                return ListTile(
                                  title: Row(
                                    children: [
                                      Checkbox(
                                        value: isChecked,
                                        onChanged: (bool? checked) {
                                          if (checked != null) {
                                            _saveCheckboxState(checkboxKey, checked);
                                          }
                                        },
                                      ),
                                      Expanded(
                                        child: Text('$itemNumber: $itemName | Qty: $itemQty'),
                                      ),
                                    ],
                                  ),
                                );
                              } else {
                                return Container();
                              }
                            }).toList(),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type your order...',
                      border: InputBorder.none,
                    ),
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_controller.text.isNotEmpty) {
            _sendMessage(_controller.text);
          }
        },
        child: const Icon(Icons.send),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.blue,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.pageview, color: Colors.white,),
              onPressed: () {
                _firestore.collection('Orders History').get().then((querySnapshot) {
                  Map<String, dynamic> itemCounts = {};

                  for (var document in querySnapshot.docs) {
                    final messageText = document['message'];
                    final lines = messageText.split('\n');
                    if (lines.length < 3) continue;

                    final name = lines[0];
                    final address = lines[1];
                    final phone = lines[2];

                    for (var line in lines.skip(3)) {
                      final pattern = RegExp(r'^(\d+):\s*\(([^)]+)\)\s*([^|]+)\|Qty:\s*([\d\.]+)');

                      final match = pattern.firstMatch(line);
                      if (match != null) {
                        final itemNumber = match.group(1)!;
                        final itemName = '${match.group(2)} ${match.group(3)}';
                        final itemQty = double.parse(match.group(4)!);

                        if (itemCounts.containsKey(itemName)) {
                          itemCounts[itemName]['totalQuantity'] += itemQty;
                          itemCounts[itemName]['details'].add({
                            'name': name,
                            'phone': phone,
                            'quantity': itemQty,
                          });
                        } else {
                          itemCounts[itemName] = {
                            'totalQuantity': itemQty,
                            'details': [
                              {
                                'name': name,
                                'phone': phone,
                                'quantity': itemQty,
                              }
                            ]
                          };
                        }
                      }
                    }

                    if (itemCounts.isNotEmpty) {
                      _navigateToOrderDetail(itemCounts);
                    }
                  }
                }).catchError((error) {
                  print('Error fetching documents: $error');
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
              child: const Text("Total", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class NewOrderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> itemCounts;

  const NewOrderDetailScreen(this.itemCounts, {super.key});

  @override
  Widget build(BuildContext context) {
    int totalItems = itemCounts.keys.length;
    double totalQuantity = itemCounts.values.fold(
        0.0, (sum, item) => sum + item['totalQuantity']);
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(
        now); // Format the current date

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        actions: [
          IconButton(

            icon: const Icon(Icons.copy),
            onPressed: () {
              final orderDetails = formatOrderDetails(
                  totalItems, totalQuantity, formattedDate);
              Clipboard.setData(ClipboardData(text: orderDetails)).then((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Order details copied to clipboard')),
                );
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formattedDate, style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
                // Display the date
                Text('Total Items: $totalItems'),
                Text('Total Quantity: $totalQuantity '),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: itemCounts.keys.length,
              itemBuilder: (context, index) {
                String itemName = itemCounts.keys.elementAt(index);
                List<Map<String,
                    dynamic>> itemDetails = itemCounts[itemName]['details'];

                return ExpansionTile(
                  title: Text(
                      '$itemName: ${itemCounts[itemName]['totalQuantity']} '),
                  children: itemDetails.map((detail) {
                    return ListTile(
                      title: Text('Quantity: ${detail['quantity']} '),
                      subtitle: Text('${detail['name']} - ${detail['phone']}'),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String formatOrderDetails(int totalItems, double totalQuantity, String date) {
    final buffer = StringBuffer();
    buffer.writeln('Date: $date'); // Include the date
    buffer.writeln('Total Items: $totalItems');
    buffer.writeln('Total Quantity: $totalQuantity');
    buffer.writeln();
    itemCounts.forEach((itemName, itemData) {
      buffer.writeln('$itemName: ${itemData['totalQuantity']}');
      List<Map<String, dynamic>> itemDetails = itemData['details'];
      for (var detail in itemDetails) {
        buffer.writeln(
            '  Quantity: ${detail['quantity']} - ${detail['name']} (${detail['phone']})');
      }
      buffer.writeln();
    });
    return buffer.toString();
  }
}