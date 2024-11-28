import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:green_sultan/live_hara_dhaniya/pages/NewOrderDetailsScreen.dart';
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
    _firestore
        .collection('Cities') // Top-level collection
        .doc('Lahore') // Specific document
        .collection('Orders History') // Sub-collection
        .doc(messageId) // Target document ID
        .delete();
  }
  void _sendMessage(String message) {
    String processedMessage = _processMessage(message);
    Timestamp timestamp = Timestamp.now();
    _firestore
        .collection('Cities') // Top-level collection
        .doc('Lahore') // Specific document
        .collection('Orders History') // Sub-collection
        .add({
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
              stream: _firestore
                  .collection('Cities') // Top-level collection
                  .doc('Lahore') // Specific document
                  .collection('Orders History') // Sub-collection
                  .snapshots(),
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
                              final pattern = RegExp(
                                  r'^(\d+):\s*\(([^)]+)\)\s*([^|]+)\|Qty:\s*([\d\.]+)');
                              final match = pattern.firstMatch(line);
                              if (match != null) {
                                final itemNumber = match.group(1)!;
                                final itemName = '${match.group(2)} ${match.group(3)}';
                                final itemQty = double.parse(match.group(4)!);
                                final checkboxKey =
                                _generateCheckboxKey(messageId, itemName);
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
                                        child:
                                        Text('$itemNumber: $itemName | Qty: $itemQty'),
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
        color: Colors.green[700],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.pageview, color: Colors.white,),
              onPressed: () {
                _firestore.collection('Cities') // Top-level collection
                    .doc('Lahore') // Specific document
                    .collection('Orders History') // Sub-collection
                    .get()
                    .then((querySnapshot) {
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
