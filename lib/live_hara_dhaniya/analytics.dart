import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  NumberFormat currencyFormatter = NumberFormat.currency(symbol: 'Rs');
  double totalDifference =
      0.0; // State variable to hold the total difference sum

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String formatCurrency(double value) {
    return currencyFormatter.format(value);
  }

  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

  double parseAmount(String amount) {
    return double.tryParse(amount) ?? 0.0;
  }

  void _saveMessage(
      DocumentReference documentRef, String title, String amount) {
    FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot freshSnapshot = await transaction.get(documentRef);
      List<dynamic> messages = List.from(
          (freshSnapshot.data() as Map<String, dynamic>)['messages'] ?? []);

      messages = messages.map((message) {
        if (message is Map<String, dynamic>) {
          return message;
        } else {
          return {'title': 'Unknown', 'amount': 'Unknown'};
        }
      }).toList();

      messages.add({'title': title, 'amount': amount});
      transaction.update(documentRef, {'messages': messages});
    }).then((_) {
      setState(() {
        _titleController.clear();
        _amountController.clear();
      });
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving message: $error')));
    });
  }

  void _deleteMessage(DocumentReference documentRef, int index) {
    FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot freshSnapshot = await transaction.get(documentRef);
      List<dynamic> messages = List.from(
          (freshSnapshot.data() as Map<String, dynamic>)['messages'] ?? []);

      if (index >= 0 && index < messages.length) {
        messages.removeAt(index);
        transaction.update(documentRef, {'messages': messages});
      }
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting message: $error')));
    });
  }

  Map<String, List<DocumentSnapshot<Map<String, dynamic>>>> _groupDataByDate(
      List<DocumentSnapshot<Map<String, dynamic>>> docs) {
    Map<String, List<DocumentSnapshot<Map<String, dynamic>>>> groupedData = {};
    for (var doc in docs) {
      final data = doc.data();
      final timestamp = data?['timestamp'] as Timestamp?;
      String formattedDate = 'N/A';
      if (timestamp != null) {
        formattedDate = formatTimestamp(timestamp);
      }

      if (!groupedData.containsKey(formattedDate)) {
        groupedData[formattedDate] = [];
      }
      groupedData[formattedDate]!.add(doc);
    }
    return groupedData;
  }

  double calculateDifference(
      dynamic mandi, dynamic price, List<dynamic> messages) {
    double difference = 0.0;

    if (mandi is num && price is num) {
      double mandiDouble = mandi.toDouble();
      double priceDouble = price.toDouble();
      difference = priceDouble - mandiDouble;
    }

    // Subtract message amounts from the difference
    for (var message in messages) {
      if (message is Map<String, dynamic>) {
        double amount = parseAmount(message['amount']);
        difference -= amount;
      }
    }

    return difference;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('Cities')
              .doc('Lahore')
              .collection('Totals')
              .snapshots(),
          builder: (context,
              AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting ||
                snapshot.hasError) {
              return const Text('Analytics');
            } else {
              int totalCount = snapshot.data!.docs.length;
              return Text('Total Orders: $totalCount');
            }
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('Cities')
              .doc('Lahore')
              .collection('Totals')
              .snapshots(),
          builder: (context,
              AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            } else {
              final groupedData = _groupDataByDate(snapshot.data!.docs);

              final sortedKeys = groupedData.keys.toList()
                ..sort((a, b) => DateFormat('yyyy-MM-dd')
                    .parse(a)
                    .compareTo(DateFormat('yyyy-MM-dd').parse(b)));

              return ListView.builder(
                itemCount: sortedKeys.length,
                itemBuilder: (context, index) {
                  final date = sortedKeys[index];
                  final docs = groupedData[date]!;

                  double totalSum = 0.0;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    shadowColor: Colors.black,
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Date: $date',
                              style: const TextStyle(
                                  fontSize: 18.0, fontWeight: FontWeight.bold)),
                          ...docs.map((document) {
                            final data = document.data();
                            final grandTotalMandi =
                                data?['grandTotalMandi'] ?? 'N/A';
                            final grandTotalPrice =
                                data?['grandTotalPrice'] ?? 'N/A';
                            final timestamp = data?['timestamp'] as Timestamp?;

                            String formattedTimestamp = 'N/A';
                            if (timestamp != null) {
                              formattedTimestamp = formatTimestamp(timestamp);
                            }

                            final messages =
                                (data?['messages'] as List<dynamic>? ?? [])
                                    .cast<Map<String, dynamic>>();

                            double difference = calculateDifference(
                                grandTotalMandi, grandTotalPrice, messages);
                            totalSum += difference;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  title: Text('Date: $formattedTimestamp'),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      DataTable(
                                        columns: const [
                                          DataColumn(
                                              label: Text('Grand Total Mandi')),
                                          DataColumn(
                                              label: Text('Grand Total Price')),
                                        ],
                                        rows: [
                                          DataRow(cells: [
                                            DataCell(Text('$grandTotalMandi')),
                                            DataCell(Text('$grandTotalPrice')),
                                          ]),
                                        ],
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0, vertical: 8.0),
                                        child: Column(
                                          children: [
                                            TextFormField(
                                              controller: _titleController,
                                              decoration: const InputDecoration(
                                                hintText: 'Enter title',
                                              ),
                                            ),
                                            const SizedBox(height: 8.0),
                                            TextFormField(
                                              controller: _amountController,
                                              decoration: const InputDecoration(
                                                hintText: 'Enter amount',
                                              ),
                                              keyboardType:
                                                  TextInputType.number,
                                            ),
                                            IconButton(
                                              onPressed: () {
                                                String title = _titleController
                                                    .text
                                                    .trim();
                                                String amount =
                                                    _amountController.text
                                                        .trim();
                                                if (title.isNotEmpty &&
                                                    amount.isNotEmpty) {
                                                  _saveMessage(
                                                      document.reference,
                                                      title,
                                                      amount);
                                                }
                                              },
                                              icon: const Icon(Icons.send),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8.0),
                                      const Text('Messages:',
                                          style: TextStyle(
                                              fontSize: 18.0,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4.0),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: messages
                                            .asMap()
                                            .entries
                                            .map((entry) {
                                          final index = entry.key;
                                          final message = entry.value;
                                          final title =
                                              message['title'] ?? 'Unknown';
                                          final amount =
                                              message['amount'] ?? 'Unknown';
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16.0),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text('- $title: $amount'),
                                                IconButton(
                                                  icon:
                                                      const Icon(Icons.delete),
                                                  onPressed: () {
                                                    _deleteMessage(
                                                        document.reference,
                                                        index);
                                                  },
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                      const SizedBox(height: 8.0),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          const Text(
                                            'Difference: ',
                                            style: TextStyle(
                                              fontSize: 16.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            formatCurrency(difference),
                                            style: const TextStyle(
                                              fontSize: 16.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const Text(
                                  'Total Difference Sum: ',
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  formatCurrency(totalSum),
                                  style: const TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          }),
      bottomNavigationBar: BottomAppBar(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('Cities')
              .doc('Lahore')
              .collection('Totals')
              .snapshots(),
          builder: (context,
              AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting ||
                snapshot.hasError) {
              return const SizedBox.shrink();
            } else {
              double totalDifferenceSum =
                  snapshot.data!.docs.fold(0.0, (sum, doc) {
                final data = doc.data();
                final grandTotalMandi = data['grandTotalMandi'];
                final grandTotalPrice = data['grandTotalPrice'];
                final messages = (data['messages'] as List<dynamic>?) ?? [];
                double difference = calculateDifference(
                    grandTotalMandi, grandTotalPrice, messages);
                return sum + difference;
              });

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Total Difference Sum: ${formatCurrency(totalDifferenceSum)}',
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
