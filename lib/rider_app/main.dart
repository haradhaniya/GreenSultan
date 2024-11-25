import 'dart:convert';
import 'package:green_sultan/rider_app/ContainerWithInfo.dart';
import 'package:green_sultan/rider_app/PdfDialog.dart';
import 'package:green_sultan/rider_app/components/AppBar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _messageController = TextEditingController();
  List<String> _digitItems = [];
  List<String> _textItems = [];
  List<TextEditingController> _priceControllers = [];
  double _totalPrice = 0.0;
  String _name = '';
  String _address = '';
  List<bool> _priceAdded = [];
  double _paidAmount = 0.0;
  final double _deliveryCharges = 0.0;
  late pw.Image _watermarkImage;
  // Add a key for SharedPreferences
  final String _dataKey = 'invoice_data';
  late Uint8List _yourFontUint8List;
  List<String> items = [];
  final List<String> _itemsWithPrices = [];
  List<int> _itemCount = [];
  final Set<int> _selectedItems = <int>{};
  bool areItemsSelected = false;
  double deliveryCharges = 0.0;

  // Function to load saved data
  void _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String savedData = prefs.getString(_dataKey) ?? '';
    setState(() {
      Map<String, dynamic> parsedData = jsonDecode(savedData);
      _name = parsedData['name'] ?? '';
      _address = parsedData['address'] ?? '';
      _digitItems = List<String>.from(parsedData['digitItems'] ?? []);
      _textItems = List<String>.from(parsedData['textItems'] ?? []);
      _totalPrice = parsedData['totalPrice'] ?? 0.0;
      _priceControllers = List<TextEditingController>.from(
        (parsedData['priceControllers'] ?? []).map(
          (controllerText) => TextEditingController(text: controllerText),
        ),
      );

      // Load color state from saved data
      _priceAdded = List<bool>.from(
          parsedData['priceAdded'] ?? List.filled(_digitItems.length, false));
    });
  }

  // Function to save data to SharedPreferences
  void _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> dataToSave = {
      'name': _name,
      'address': _address,
      'digitItems': _digitItems,
      'textItems': _textItems,
      'totalPrice': _totalPrice,
      'priceControllers':
          _priceControllers.map((controller) => controller.text).toList(),
      'priceAdded': _priceAdded, // Save color state
    };
    prefs.setString(_dataKey, jsonEncode(dataToSave));
  }
  // Change this to your default font

// Modify the _getTextStyle function
  pw.TextStyle _getTextStyle(String text) {
    // Use a regular expression to match English and numeric characters
    bool containsEnglishOrNumeric = RegExp(r'[A-Za-z0-9\s]+').hasMatch(text);

    // Check if the text contains English or numeric characters
    if (containsEnglishOrNumeric) {
      // If it contains English or numeric characters, return the desired TextStyle
      return pw.TextStyle(
        fontSize: 16,
        fontWeight: pw.FontWeight.bold,
        font: pw.Font.ttf(_yourFontUint8List.buffer.asByteData()),
      );
    } else {
      // If it doesn't contain English or numeric characters, return an empty TextStyle (hide them)
      return const pw.TextStyle();
    }
  }

  String formatQuantity(double quantity) {
    return quantity
        .toStringAsFixed(1); // Adjust the number of decimal places as needed
  }

  Future<void> _loadFonts() async {
    try {
      // Load the English font
      final ByteData robotoData =
          await rootBundle.load('fonts/OpenSans-Regular.ttf');
      _yourFontUint8List = robotoData.buffer.asUint8List();
      print('English font loaded successfully');
    } catch (e) {
      print('Error loading English font: $e');
    }
  }

  Future<void> _loadWatermarkImage() async {
    final ByteData data = await rootBundle.load('images/haradhaniya-logo.png');
    final Uint8List bytes = data.buffer.asUint8List();
    _watermarkImage = pw.Image(pw.MemoryImage(bytes), width: 350, height: 350);
  }

  void identifyLinesAndCalculateTotal(String message) {
    RegExp pattern = RegExp(
      r'^(\d+): \(([\d.]+kg)\) (.+) \|Qty: ([\d.]+) \|Price: ([\d.]+) \|Total: ([\d.]+)$',
      multiLine: true,
    );

    Iterable<Match> matches = pattern.allMatches(message);
    double grandTotal = 0.0;
    int totalLinesCount = 0;

    for (Match match in matches) {
      String total = match.group(6)!;
      double totalPrice = double.parse(total);
      grandTotal += totalPrice;

      String line = match.group(0)!;
      print(line); // Print the line matching the pattern

      if (line.contains('Total:')) {
        totalLinesCount++; // Increment count if line contains 'Total:'
      }
    }

    print('Number of lines with "Total:" : $totalLinesCount');
    print('Grand Total: $grandTotal');
  }

  void _generateAndDisplayInvoice() async {
    _itemCount = List<int>.generate(_digitItems.length, (index) => index + 1);
    await _loadWatermarkImage();
    await _loadFonts();

    // Create a new PDF document
    final pdf = pw.Document();

    // Set the number of items per page to 16
    const itemsPerPage = 16;

    // Get the total number of items in the invoice
    final totalItems = _digitItems.length;

    // Loop through items, creating a new page for every 'itemsPerPage'
    for (var i = 0; i < totalItems; i += itemsPerPage) {
      // Calculate the end index for the current page
      final endIndex =
          (i + itemsPerPage < totalItems) ? i + itemsPerPage : totalItems;

      // Add a new page to the PDF document
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            // Stack allows you to overlay elements on top of each other
            return pw.Stack(
              children: [
                // Watermark: Rotated container with the text 'Hara Dhaniya'
                pw.Transform.rotate(
                  angle: 0.0,
                  child: pw.Align(
                    alignment: pw.Alignment.center,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      child: _watermarkImage,
                    ),
                  ),
                ),

                // Your existing content without the watermark
                pw.Center(
                  child: pw.Stack(
                    children: [
                      // Column for invoice details
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Invoice',
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 20),
                          // Display current date and time
                          pw.Text(
                            'Date: ${DateFormat.yMd().add_jm().format(DateTime.now())}',
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                          pw.SizedBox(height: 20),
                          // Row for customer information
                          pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Expanded(
                                child: pw.Text('Name: $_name'),
                              ),
                              pw.Expanded(
                                child: pw.Text('Address: $_address'),
                              ),
                            ],
                          ),

                          pw.SizedBox(height: 20),
                          pw.Text('Items:'),

                          // Table to display items and prices
                          pw.Table.fromTextArray(
                            border: pw.TableBorder.all(
                                color: PdfColor.fromHex('#000000')),
                            headerDecoration: pw.BoxDecoration(
                              color: PdfColor.fromHex(
                                  '#008000'), // Set the background color to green
                            ),
                            headers: ['Item', 'Price'],
                            headerStyle: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 15,
                              color: PdfColor.fromHex(
                                  '#FFFFFF'), // Set the text color of the header to white
                            ),
                            cellStyle: const pw.TextStyle(fontSize: 12),
                            columnWidths: {
                              0: const pw.FlexColumnWidth(3),
                              1: const pw.FlexColumnWidth(1),
                            },
                            data: List<List<dynamic>>.generate(
                              endIndex - i,
                              (index) {
                                // Extract item details and format quantity
                                String itemDetails = _digitItems[i + index]
                                    .split(':')
                                    .first
                                    .trim(); // Extract item details
                                String quantity = _digitItems[i + index]
                                    .split(':')
                                    .last
                                    .trim(); // Extract quantity

                                // Convert quantity to double and format with decimal places
                                double quantityValue =
                                    double.tryParse(quantity) ?? 0.0;
                                String formattedQuantity =
                                    quantityValue.toStringAsFixed(
                                        1); // Format with decimal places

                                // Get the price from the controller
                                String price = _priceControllers[i + index]
                                        .text
                                        .isNotEmpty
                                    ? 'Rs ${_priceControllers[i + index].text}'
                                    : '';

                                // Create the table row with formatted item details and quantity
                                return [
                                  '${_itemCount[i + index]}: $itemDetails $formattedQuantity',
                                  price
                                ];
                              },
                            ),
                          ),

                          pw.SizedBox(height: 20),

                          // Divider line
                          pw.Divider(
                              thickness: 2, color: PdfColor.fromHex('#000000')),
                          pw.SizedBox(height: 20),

                          // Row to display total amount
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'Total :',
                                style: pw.TextStyle(
                                    fontSize: 16,
                                    fontWeight: pw.FontWeight.bold),
                              ),
                              pw.Text(
                                'Rs ${_totalPrice.toStringAsFixed(2)}', // Ensure total price formatting
                                style: pw.TextStyle(
                                    fontSize: 16,
                                    fontWeight: pw.FontWeight.bold),
                              ),
                            ],
                          ),
                          // Row to display paid amount
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'Paid Amount :',
                                style: pw.TextStyle(
                                    fontSize: 16,
                                    fontWeight: pw.FontWeight.bold),
                              ),
                              pw.Text(
                                'Rs ${_paidAmount.toStringAsFixed(2)}', // Ensure paid amount formatting
                                style: pw.TextStyle(
                                    fontSize: 16,
                                    fontWeight: pw.FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    // Save the PDF as a Uint8List
    final Uint8List pdfBytes = await pdf.save();
    // Show the PDF using a dialog
    showDialog(
      context: context,
      builder: (context) {
        return PdfViewerDialog(
          pdfBytes: pdfBytes,
          paidAmount: _paidAmount,
        );
      },
    );
  }

  // Add this method inside the _MyHomePageState class
  void _calculateTotalPrice() {
    double totalPrice = 0.0;
    for (TextEditingController controller in _priceControllers) {
      double price = double.tryParse(controller.text) ?? 0.0;
      totalPrice += price;
      // Update _itemsWithPrices based on the presence of a price
      setState(() {
        if (price > 0) {
          _itemsWithPrices
              .add(_digitItems[_priceControllers.indexOf(controller)]);
        } else {
          _itemsWithPrices
              .remove(_digitItems[_priceControllers.indexOf(controller)]);
        }
      });
    }
    setState(() {
      _totalPrice = totalPrice;
    });
  }

  void _sendMessage() {
    String message = _messageController.text.trim();
    message = message.replaceAll(RegExp(r'^\s+$', multiLine: true), '');

    // Define the regular expressions for items and the total counts
    RegExp itemRegExp = RegExp(r'^(\d+\.?\d*)?\s*(gm|kg|Bundle)\s*(.+)',
        multiLine: true, caseSensitive: false);
    RegExp totalItemsRegExp = RegExp(r'^Total Items:\s*(\d+)$');
    RegExp totalQuantityRegExp = RegExp(r'^Total Quantity:\s*(\d+(\.\d+)?)$');

    List<String> lines = message.split('\n');
    List<String> formattedLines = [];
    List<String> newDigitItems = [];
    List<String> newTextItems = [];
    List<TextEditingController> newPriceControllers = [];
    int itemCount = 0;

    bool hasValidTotalItems = false;
    bool hasValidTotalQuantity = false;

    // Validate and process the message lines
    for (String line in lines) {
      if (totalItemsRegExp.hasMatch(line)) {
        hasValidTotalItems = true;
        formattedLines.add(line);
        continue;
      }

      if (totalQuantityRegExp.hasMatch(line)) {
        hasValidTotalQuantity = true;
        formattedLines.add(line);
        continue;
      }

      Match? itemMatch = itemRegExp.firstMatch(line);

      if (itemMatch != null) {
        String? quantity = itemMatch.group(1);
        String unit = itemMatch.group(2)!;
        String itemName = itemMatch.group(3)!;

        // Add price text field for all valid items
        TextEditingController priceController = TextEditingController();
        newPriceControllers.add(priceController);
        newDigitItems.add(line);

        itemCount++; // Increment the item count
        String itemPrefix = '$itemCount. ';

        formattedLines.add('$itemPrefix${quantity ?? ''} $unit: $itemName');
      } else {
        formattedLines.add(line);
        newTextItems.add(line);
      }
    }

    // Check if the message contains valid total counts and at least one valid item
    if (!hasValidTotalItems || !hasValidTotalQuantity || itemCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Invalid message format. Please ensure all required fields are present.'),
        ),
      );
      return;
    }

    // Further processing
    setState(() {
      _digitItems = newDigitItems;
      _textItems = newTextItems;
      _priceControllers = newPriceControllers;
      _messageController.clear();
      _calculateTotalPrice();
      _priceAdded = List<bool>.generate(_digitItems.length, (index) => false);
    });

    _saveData();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message processed successfully.'),
      ),
    );
  }

  // Function to launch WhatsApp
  void _launchWhatsApp(String number) async {
    String url = 'https://wa.me/+92$number';
    // ignore: deprecated_member_use
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print('Could not launch WhatsApp chat');
    }
  }

  void moveSelectedItemsToEnd() {
    setState(() {
      // Filter out the selected items and move them to the end
      List<String> selectedDigitItems = [];
      List<TextEditingController> selectedPriceControllers = [];
      List<bool> selectedPriceAdded = [];

      // Iterate through the list in reverse order to avoid index issues
      for (int index = _digitItems.length - 1; index >= 0; index--) {
        if (_selectedItems.contains(index)) {
          selectedDigitItems.add(_digitItems[index]);
          selectedPriceControllers.add(_priceControllers[index]);
          selectedPriceAdded.add(_priceAdded[index]);

          // Remove the selected item from the original position
          _digitItems.removeAt(index);
          _priceControllers.removeAt(index);
          _priceAdded.removeAt(index);
        }
      }

      // Add selected items to the end
      _digitItems.addAll(selectedDigitItems);
      _priceControllers.addAll(selectedPriceControllers);
      _priceAdded.addAll(selectedPriceAdded);

      // Clear the selection
      _selectedItems.clear();
    });
  }

  // Store controllers and focus nodes for digit items
  List<TextEditingController> _digitControllers = [];
  List<FocusNode> _digitFocusNodes = [];

  @override
  void initState() {
    super.initState();
    _loadWatermarkImage();
    _loadPaidAmount();
    _loadData();
    _loadFonts().then((_) {
      // Initialize controllers and focus nodes for existing digit items
      _digitControllers = List.generate(
        _digitItems.length,
        (index) => TextEditingController(text: _digitItems[index]),
      );
      _digitFocusNodes = List.generate(
        _digitItems.length,
        (index) => FocusNode(),
      );
    });
  }

  void _clearitems() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirmation"),
          content: Text("Enter code '786' to clear items:"),
          actions: [
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(hintText: "Enter code"),
              onChanged: (value) {
                if (value == "786") {
                  Navigator.of(context).pop(); // Close the dialog
                  setState(() {
                    _digitItems.clear();
                  });
                }
              },
            ),
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context)
                    .pop(); // Close the dialog without clearing
              },
            ),
          ],
        );
      },
    );
  }
// Load _paidAmount from SharedPreferences
  Future<void> _loadPaidAmount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _paidAmount = prefs.getDouble('paidAmount') ?? 0.0;
    });
  }

  // Save _paidAmount to SharedPreferences
  Future<void> _savePaidAmount() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble('paidAmount', _paidAmount);
  }

  // Update _paidAmount and save it
  void _updatePaidAmount(double amount) {
    setState(() {
      _paidAmount = amount;
    });
    _savePaidAmount();
  }

  @override
  void dispose() {
    // Dispose the controllers and focus nodes to prevent memory leaks
    for (var controller in _digitControllers) {
      controller.dispose();
    }
    for (var focusNode in _digitFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        saveData: _saveData,
        generateAndDisplayInvoice: _generateAndDisplayInvoice,
        launchWhatsApp: _launchWhatsApp,
        clearMessage: _clearitems,
      ),
      body: Column(
        children: [
          StylishContainer(
            customerName: _name,
            customerAddress: _address,
            items: _textItems,
            onPaidAmountChanged: (double paidAmount) {
              setState(() {
                _paidAmount = paidAmount;
              });
            },
            customerPaidAmount: _paidAmount,
          ),
          Expanded(
            child: ReorderableListView.builder(
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }

                  final item = _digitItems.removeAt(oldIndex);
                  final priceController = _priceControllers.removeAt(oldIndex);
                  final priceAdded = _priceAdded.removeAt(oldIndex);

                  _digitItems.insert(newIndex, item);
                  _priceControllers.insert(newIndex, priceController);
                  _priceAdded.insert(newIndex, priceAdded);
                });
              },
              itemCount: _digitItems.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  key: ValueKey(index),
                  tileColor: _priceAdded[index]
                      ? Colors.blue[900]
                      : Colors.blueGrey[900],
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 2.0, horizontal: 4.0),
                  title: Row(
                    children: [
                      // Counter
                      Text(
                        '${index + 1}:',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(width: 8.0),
                      // Move icon at the beginning
                      const Icon(Icons.move_down, color: Colors.white),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2, // Adjust the flex value as needed
                              child: Text(
                                _digitItems[
                                    index], // Display the content of _digitItems[index]
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Expanded(
                              flex: 1, // Adjust the flex value as needed
                              child: TextField(
                                controller: _priceControllers[index],
                                decoration: const InputDecoration(
                                  labelText: 'Price',
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setState(() {
                                    _calculateTotalPrice();
                                    if (value.isNotEmpty) {
                                      _priceAdded[index] = true;
                                    } else {
                                      _priceAdded[index] = false;
                                    }
                                  });
                                  // Save data automatically when there's a change
                                  _saveData();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (areItemsSelected) // Show the button only if items are selected
            ElevatedButton(
              onPressed: () {
                moveSelectedItemsToEnd();
                // Other actions if needed
              },
              child: const Text('Move Selected Items to End'),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Container(
                  constraints: const BoxConstraints(maxHeight: 300.0),
                  child: SingleChildScrollView(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            labelText: 'Message',
                            hintText: 'Enter your message',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            filled: true,
                          ),
                          maxLines: null,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            onPressed: _sendMessage,
                            child: const Text('Send'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_digitItems.isNotEmpty)
                  Card(
                    elevation: 4.0,
                    margin: const EdgeInsets.all(8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total :',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Rs ${_totalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Paid Amount :',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Rs ${_paidAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
