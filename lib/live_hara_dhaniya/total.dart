import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_sultan/live_hara_dhaniya/analytics.dart';

class Totals extends StatefulWidget {
  const Totals({super.key});

  @override
  State<Totals> createState() => _TotalsState();
}

class _TotalsState extends State<Totals> {
  late Map<String, String> nameToValue1;
  late Map<String, String> nameToValue3;
  late Map<String, String> nameToPrice;

  int grandTotalMandi = 0;
  int grandTotalPrice = 0;

  @override
  void initState() {
    super.initState();
    nameToValue1 = {};
    nameToValue3 = {};
    nameToPrice = {};
    fetchValueData();
  }

  Future<void> fetchValueData() async {
    try {
      final fruitsSnapshot =
      await FirebaseFirestore.instance.collection('Fruits').get();
      final veggiesSnapshot =
      await FirebaseFirestore.instance.collection('Veggies').get();

      final tempNameToValue1 = <String, String>{};
      final tempNameToValue3 = <String, String>{};
      final tempNameToPrice = <String, String>{};

      processSnapshot(
          fruitsSnapshot, tempNameToValue1, tempNameToValue3, tempNameToPrice);
      processSnapshot(
          veggiesSnapshot, tempNameToValue1, tempNameToValue3, tempNameToPrice);

      setState(() {
        nameToValue1 = tempNameToValue1;
        nameToValue3 = tempNameToValue3;
        nameToPrice = tempNameToPrice;
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching data: $e");
      }
    }
  }

  void processSnapshot(
      QuerySnapshot snapshot,
      Map<String, String> tempNameToValue1,
      Map<String, String> tempNameToValue3,
      Map<String, String> tempNameToPrice) {
    for (final document in snapshot.docs) {
      final data = document.data() as Map<String, dynamic>?;
      final name = data?['name'] ?? 'Unknown';
      final value1 = data?['value1']?.toString() ?? 'N/A';
      final value3 = data?['value3']?.toString() ?? 'N/A';
      final price = data?['price']?.toString() ?? 'N/A';
      tempNameToValue1[name.toLowerCase()] = value1;
      tempNameToValue3[name.toLowerCase()] = value3;
      tempNameToPrice[name.toLowerCase()] = price;
    }
  }

  Future<void> saveGrandTotalMandi(int mandiTotal) async {
    try {
      final DateTime now = DateTime.now();
      final String formattedDate = "${now.year}-${now.month}-${now.day}";

      final totalsRef =
      FirebaseFirestore.instance.collection('Totals').doc(formattedDate);

      // Get the existing document data
      final documentSnapshot = await totalsRef.get();
      final data = documentSnapshot.data() ?? {};

      // Update only the mandi grand total
      data['grandTotalMandi'] = mandiTotal;

      // Set the updated data back to the document
      await totalsRef.set({
        ...data,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print("Grand total (Mandi) saved successfully for $formattedDate");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error saving grand total (Mandi): $e");
      }
    }
  }

  Future<void> saveGrandTotalPrice(int priceTotal) async {
    try {
      final DateTime now = DateTime.now();
      final String formattedDate = "${now.year}-${now.month}-${now.day}";

      final totalsRef =
      FirebaseFirestore.instance.collection('Totals').doc(formattedDate);

      // Get the existing document data
      final documentSnapshot = await totalsRef.get();
      final data = documentSnapshot.data() ?? {};

      // Update only the price grand total
      data['grandTotalPrice'] = priceTotal;

      // Set the updated data back to the document
      await totalsRef.set({
        ...data,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print("Grand total (Price) saved successfully for $formattedDate");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error saving grand total (Price): $e");
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Total"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AnalyticsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.analytics_sharp),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            buildOrderHistoryMessageTable(),
            buildSaveButtons(),
          ],
        ),
      ),
    );
  }

  Widget buildOrderHistoryMessageTable() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('OrderDetails').snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return buildMessageTable(snapshot);
      },
    );
  }

  Widget buildMessageTable(AsyncSnapshot<QuerySnapshot> snapshot) {
    final rows = <DataRow>[];
    grandTotalMandi = 0;
    grandTotalPrice = 0;

    for (final document in snapshot.data!.docs) {
      final data = document.data() as Map<String, dynamic>?;
      final itemCounts = data?['itemCounts'] as Map<String, dynamic>?;

      if (itemCounts != null) {
        var subtotalMandi = 0;
        var subtotalPrice = 0;

        itemCounts.forEach((itemName, itemCount) {
          final fuzzyNameMatch =
          findBestMatch(itemName.toLowerCase(), nameToValue1.keys.toList());
          final value1 = nameToValue1[fuzzyNameMatch] ?? 'N/A';
          final value3 = nameToValue3[fuzzyNameMatch] ?? 'N/A';
          final price = nameToPrice[fuzzyNameMatch] ?? 'N/A';

          var totalValue1 = 0;
          var mandiTotal = 0;
          var totalPrice = 0;

          try {
            if (value1 != 'N/A' && _isValidNumber(value1)) {
              totalValue1 = (int.parse(value1) * itemCount).toInt();
            }
            if (price != 'N/A' && _isValidNumber(price)) {
              totalPrice = (int.parse(price) * itemCount).toInt();
            }
            if (value3 != 'N/A' && value3 != '0') {
              if (value3.contains('/')) {
                var parts = value3.split('/');
                if (parts.length == 2) {
                  var divisor = double.parse(parts[1].trim());
                  if (divisor != 0) {
                    mandiTotal = (totalValue1 / divisor).toInt();
                  }
                }
              } else if (value3.contains('*')) {
                var parts = value3.split('*');
                if (parts.length == 2) {
                  var factor = double.parse(parts[1].trim());
                  mandiTotal = (totalValue1 * factor).toInt();
                }
              }
            } else {
              mandiTotal = totalValue1;
            }
          } catch (e) {
            if (kDebugMode) {
              print("Error parsing values: $e");
            }
          }

          subtotalMandi += mandiTotal;
          subtotalPrice += totalPrice;

          rows.add(DataRow(cells: [
            DataCell(Text(itemName)),
            DataCell(Text(itemCount.toString())),
            DataCell(Text(mandiTotal.toString())),
            DataCell(Text(value1)),
            DataCell(Text(price)),
            DataCell(Text(totalPrice.toString())),
          ]));
        });

        grandTotalMandi += subtotalMandi;
        grandTotalPrice += subtotalPrice;
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Aligns children to the start (left)
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          DataTable(
            columns: const [
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Count')),
              DataColumn(label: Text('MandiTotal')),
              DataColumn(label: Text('Value1')),
              DataColumn(label: Text('Price')),
              DataColumn(label: Text('Total Price')),
            ],
            rows: rows,
          ),
          const SizedBox(height: 20),
          Column(
            // crossAxisAlignment: CrossAxisAlignment.start, // Aligns children to the start (left)
            // mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'Grand Total (MandiTotal): $grandTotalMandi',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 20),
              Text(
                'Grand Total (Total Price): $grandTotalPrice',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 20),
            ],
          )
        ],
      ),


    );
  }

  Future<void> saveGrandTotals(int mandiTotal, int priceTotal) async {
    try {
      final DateTime now = DateTime.now();
      final String formattedDate = "${now.year}-${now.month}-${now.day}";

      final totalsRef =
      FirebaseFirestore.instance.collection('Totals').doc(formattedDate);

      await totalsRef.set({
        'grandTotalMandi': mandiTotal,
        'grandTotalPrice': priceTotal,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print("Grand totals saved successfully for $formattedDate");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error saving grand totals: $e");
      }
    }
  }

  Widget buildSaveButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => saveGrandTotalMandi(grandTotalMandi),
            child: const Text('Save Grand Total (Mandi)'),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: ElevatedButton(
            onPressed: () => saveGrandTotalPrice(grandTotalPrice),
            child: const Text('Save Grand Total (Price)'),
          ),
        ),
      ],
    );
  }


  bool _isValidNumber(String str) {
    final number = int.tryParse(str);
    return number != null;
  }

  String findBestMatch(String itemName, List<String> options) {
    var bestMatch = '';
    var highestScore = 0;

    for (var option in options) {
      var score = _calculateStringMatchScore(itemName, option);
      if (score > highestScore) {
        highestScore = score;
        bestMatch = option;
      }
    }

    return bestMatch;
  }

  int _calculateStringMatchScore(String input, String option) {
    var score = 0;
    var inputWords = input.split(' ');
    var optionWords = option.split(' ');

    for (var inputWord in inputWords) {
      for (var optionWord in optionWords) {
        if (inputWord.toLowerCase() == optionWord.toLowerCase()) {
          score++;
        }
      }
    }

    return score;
  }
}