import 'dart:convert';
import 'package:green_sultan/rider_app/ContainerWithInfo.dart';
import 'package:green_sultan/rider_app/PdfDialog.dart';
import 'package:green_sultan/rider_app/components/AppBar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:green_sultan/core/performance_optimizer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_sultan/provider/user_provider.dart';

// Add this function outside the class to enable isolate computation
Future<pw.Document> _generatePdfDocument(Map<String, dynamic> params) async {
  final digitItems = params['digitItems'] as List<String>;
  final priceControllers = params['priceControllers'] as List<String>;
  final name = params['name'] as String;
  final address = params['address'] as String;
  final watermarkImage = params['watermarkImage'] as pw.Image;

  // Create a new PDF document
  final pdf = pw.Document();

  // Get the current date
  final now = DateTime.now();
  final formattedDate = '${now.day}/${now.month}/${now.year}';

  // Calculate total price
  double totalPrice = 0.0;
  for (var i = 0; i < priceControllers.length; i++) {
    double price = double.tryParse(priceControllers[i]) ?? 0.0;
    totalPrice += price;
  }

  // Add pages with invoice details that can span across multiple pages
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      // Enable maxPages to allow content to flow across multiple pages
      maxPages: 10,
      footer: (pw.Context context) {
        return pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 10),
          ),
        );
      },
      build: (pw.Context context) {
        // Create a list of widgets that can flow across pages
        List<pw.Widget> widgets = [];

        // Add header section (fixed to first page)
        widgets.add(pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('INVOICE',
                        style: pw.TextStyle(
                            fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    pw.Text('Date: $formattedDate',
                        style: const pw.TextStyle(fontSize: 14)),
                  ],
                ),
                pw.Container(
                  height: 60,
                  width: 60,
                  child: watermarkImage,
                )
              ],
            )));

        // Add customer details section
        widgets.add(pw.SizedBox(height: 20));
        widgets.add(pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Customer Details',
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              pw.Text('Name: $name', style: const pw.TextStyle(fontSize: 12)),
              pw.Text('Address: $address',
                  style: const pw.TextStyle(fontSize: 12)),
            ],
          ),
        ));

        // Add items table header
        widgets.add(pw.SizedBox(height: 20));
        widgets.add(pw.Text('Order Items',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)));
        widgets.add(pw.SizedBox(height: 10));

        // Split items into smaller chunks to avoid large tables
        // that might cause overflow issues
        final int itemsPerTable = 20;
        for (int i = 0; i < digitItems.length; i += itemsPerTable) {
          final int end = (i + itemsPerTable < digitItems.length)
              ? i + itemsPerTable
              : digitItems.length;

          final List<List<String>> tableData = [];
          for (int j = i; j < end; j++) {
            tableData.add([
              '${j + 1}',
              digitItems[j],
              priceControllers[j],
            ]);
          }

          widgets.add(pw.Table.fromTextArray(
            border: null,
            headers: ['#', 'Item', 'Price (Rs)'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.grey300,
            ),
            cellHeight: 25, // Reduced from 30 to fit more items
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerRight,
            },
            data: tableData,
          ));

          // Add spacing between tables if not the last one
          if (end < digitItems.length) {
            widgets.add(pw.SizedBox(height: 10));
          }
        }

        // Add summary section
        widgets.add(pw.SizedBox(height: 20));
        widgets.add(pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Container(
                width: 100,
                child: pw.Text('Total:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Container(
                width: 100,
                child: pw.Text('Rs${totalPrice.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
            ],
          ),
        ));

        // Add footer section
        widgets.add(pw.SizedBox(height: 20));
        widgets.add(pw.Divider());
        widgets.add(pw.SizedBox(height: 10));
        widgets.add(pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Thank you for your business!',
                style: const pw.TextStyle(fontSize: 12)),
            pw.Text('Green Sultan',
                style:
                    pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          ],
        ));

        return widgets;
      },
    ),
  );

  return pdf;
}

class RiderApp extends ConsumerStatefulWidget {
  const RiderApp({super.key});

  @override
  ConsumerState<RiderApp> createState() => _RiderAppState();
}

class _RiderAppState extends ConsumerState<RiderApp> {
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

  @override
  void initState() {
    super.initState();
    // Use performance optimizer to load data after the UI is rendered
    PerformanceOptimizer.runAfterFrame(() {
      _loadData();
    });
  }

  // Function to load saved data
  void _loadData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String savedData = prefs.getString(_dataKey) ?? '';

      if (savedData.isNotEmpty) {
        // Use compute for JSON parsing to avoid blocking the main thread
        final parsedData = await PerformanceOptimizer.computeAsync<
            Map<String, dynamic>, String>(
          (String data) async => jsonDecode(data) as Map<String, dynamic>,
          savedData,
        );

        setState(() {
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
          _priceAdded = List<bool>.from(parsedData['priceAdded'] ??
              List.filled(_digitItems.length, false));
        });
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
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
      debugPrint('English font loaded successfully');
        } catch (e) {
      debugPrint('Error loading English font: $e');
      // Fallback to a system font if there's an error
      _yourFontUint8List = Uint8List(0); // Empty font data as fallback
    }
  }

  Future<void> _loadWatermarkImage() async {
    try {
      final ByteData data =
          await rootBundle.load('images/haradhaniya-logo.png');
      final Uint8List bytes = data.buffer.asUint8List();
      _watermarkImage =
          pw.Image(pw.MemoryImage(bytes), width: 350, height: 350);
      debugPrint('Watermark image loaded successfully');
    } catch (e) {
      debugPrint('Error loading watermark image: $e');
      // Create a simple placeholder image on error
      // Create an empty PDF document to get a blank image as a fallback
      final pdf = pw.Document();
      _watermarkImage =
          pw.Image(pw.MemoryImage(Uint8List(0)), width: 1, height: 1);
    }
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
    // Show processing indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating invoice, please wait...'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      _itemCount = List<int>.generate(_digitItems.length, (index) => index + 1);

      // Check if we have items
      if (_digitItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No items to generate invoice'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Load resources
      await _loadWatermarkImage();
      await _loadFonts();

      // Prepare data for background processing
      final params = {
        'digitItems': _digitItems,
        'priceControllers': _priceControllers.map((c) => c.text).toList(),
        'name': _name.isEmpty ? 'Customer' : _name,
        'address': _address.isEmpty ? 'Address not provided' : _address,
        'watermarkImage': _watermarkImage,
      };

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Process in background
      final pdfBytes = await PerformanceOptimizer.computeAsync<Uint8List,
          Map<String, dynamic>>(
        (params) async {
          // Generate PDF document using the existing function
          final pdf = await _generatePdfDocument(params);
          return pdf.save();
        },
        params,
      );

      // Close loading indicator
      if (context.mounted) Navigator.pop(context);

      // Show PDF dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => PdfViewerDialog(
            pdfBytes: pdfBytes,
            paidAmount: _paidAmount,
          ),
        );

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice generated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading indicator if it's open
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }

      debugPrint('Error generating PDF: $e');

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

    // Define regex patterns for customer details
    RegExp nameRegExp = RegExp(r'^Customer(?:\s+Name)?[:\s]+(.+)$',
        multiLine: true, caseSensitive: false);
    RegExp addressRegExp =
        RegExp(r'^Address[:\s]+(.+)$', multiLine: true, caseSensitive: false);

    // Extract customer details
    Match? nameMatch = nameRegExp.firstMatch(message);
    Match? addressMatch = addressRegExp.firstMatch(message);

    String? customerName = nameMatch?.group(1)?.trim();
    String? customerAddress = addressMatch?.group(1)?.trim();

    if (customerName != null && customerName.isNotEmpty) {
      setState(() {
        _name = customerName;
      });
    }

    if (customerAddress != null && customerAddress.isNotEmpty) {
      setState(() {
        _address = customerAddress;
      });
    }

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
      // Skip lines that have already been processed as customer details
      if ((nameMatch != null && line.trim() == nameMatch.group(0)?.trim()) ||
          (addressMatch != null &&
              line.trim() == addressMatch.group(0)?.trim())) {
        continue;
      }

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
      SnackBar(
        content: Text(customerName != null || customerAddress != null
            ? 'Message processed with customer details.'
            : 'Message processed successfully.'),
      ),
    );
  }

  // Function to launch WhatsApp
  Future<void> _launchWhatsApp() async {
    final phone = '+923035971000'; // Replace with your phone number
    final message = Uri.encodeComponent(
        'Hello, I would like to place an order.'); // Replace with your message

    final url = 'https://wa.me/$phone?text=$message';

    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching WhatsApp: $e');
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
  final List<TextEditingController> _digitControllers = [];
  final List<FocusNode> _digitFocusNodes = [];

  void _clearMessage() {
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
    // Always allow access to riders, check permission for other roles if needed
    final userRole = ref.watch(userRoleProvider).toLowerCase();
    final hasAccess =
        userRole == 'rider' || ref.read(hasPermissionProvider('RiderApp'));

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
      appBar: CustomAppBar(
        saveData: _saveData,
        generateAndDisplayInvoice: _generateAndDisplayInvoice,
        launchWhatsApp: _launchWhatsApp,
        clearMessage: _clearMessage,
      ),
      body: PerformanceOptimizer.optimizedBuilder(
        builder: (context) => LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                // Wrap StylishContainer in a container with constrained height
                Container(
                  constraints: BoxConstraints(
                    maxHeight: constraints.maxHeight *
                        0.45, // Max 45% of screen height
                  ),
                  child: StylishContainer(
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
                ),
                // Keep the rest in an Expanded widget
                Expanded(
                  child: PerformanceOptimizer.buildOptimizedList<String>(
                    items: _digitItems,
                    itemBuilder: (context, index) {
                      return ListTile(
                        key: ValueKey(index),
                        tileColor: _priceAdded[index]
                            ? Colors.green[100]
                            : Colors.grey[300],
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 2.0, horizontal: 4.0),
                        title: Row(
                          children: [
                            // Counter
                            Text(
                              '${index + 1}:',
                            ),
                            const SizedBox(width: 8.0),
                            // Move icon at the beginning
                            const Icon(Icons.move_down),
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
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
            );
          },
        ),
      ),
    );
  }
}
