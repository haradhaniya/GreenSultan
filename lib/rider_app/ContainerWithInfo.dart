import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StylishContainer extends StatefulWidget {
  final String customerName;
  final String customerAddress;
  final double customerPaidAmount;
  final List<String> items;
  final Function(double) onPaidAmountChanged;

  const StylishContainer({
    super.key,
    required this.customerName,
    required this.customerAddress,
    required this.items,
    required this.customerPaidAmount,
    required this.onPaidAmountChanged,
  });

  @override
  _StylishContainerState createState() => _StylishContainerState();
}

class _StylishContainerState extends State<StylishContainer> {
  bool _isExpanded = false;
  final List<TextEditingController> _paidAmountControllers = [];
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _initializeSharedPreferences();
  }

  Future<void> _initializeSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSavedPaidAmounts();
  }

  void _loadSavedPaidAmounts() {
    // Load saved paid amounts
    List<String>? savedAmounts = _prefs.getStringList(widget.customerName);

    if (savedAmounts != null && savedAmounts.isNotEmpty) {
      for (var amount in savedAmounts) {
        _paidAmountControllers.add(TextEditingController(text: amount));
      }
    } else {
      // Initialize with one TextEditingController if no saved data
      _paidAmountControllers.add(TextEditingController(
        text: widget.customerPaidAmount.toString(),
      ));
    }

    setState(() {});
  }

  void _savePaidAmounts() {
    // Save the current paid amounts to SharedPreferences
    List<String> amounts = _paidAmountControllers
        .map((controller) => controller.text)
        .toList();
    _prefs.setStringList(widget.customerName, amounts);
  }

  void _addNewTextField() {
    setState(() {
      _paidAmountControllers.add(TextEditingController());
    });
  }

  double _calculateTotalPaidAmount() {
    double total = 0.0;
    for (var controller in _paidAmountControllers) {
      final value = double.tryParse(controller.text) ?? 0.0;
      total += value;
    }
    return total;
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (var controller in _paidAmountControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        color: Colors.blue[900],
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Container(
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 16.0,
                    ),
                    const SizedBox(width: 4.0),
                    const Expanded(
                      child: Text(
                        'Customer Detail',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
            if (_isExpanded)
              Column(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SizedBox(
                      height: widget.items.length * 1.5 + 100.0,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: widget.items.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 16.0,
                                ),
                                const SizedBox(width: 8.0),
                                Expanded(
                                  child: Text(
                                    widget.items[index],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 300,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Add Paid Amount"),
                          // Display all text fields
                          for (var controller in _paidAmountControllers)
                            Container(
                              padding: const EdgeInsets.all(5),
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                children: [
                                  const SizedBox(width: 4.0),
                                  Expanded(
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      controller: controller,
                                      onChanged: (value) {
                                        widget.onPaidAmountChanged(
                                            _calculateTotalPaidAmount());
                                        _savePaidAmounts();
                                        setState(() {});
                                      },
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16.0,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: _addNewTextField,
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
          ],
        ),
      ),
    );
  }
}
