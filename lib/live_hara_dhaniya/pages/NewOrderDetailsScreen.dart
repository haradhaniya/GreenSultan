import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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