import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:green_sultan/provider/user_provider.dart';

import '../../provider/city_provider.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  CustomersScreenState createState() => CustomersScreenState();
}

class CustomersScreenState extends ConsumerState<CustomersScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  late CollectionReference _messagesCollection;
  late DocumentReference _messagesReference;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _filteredMessages = [];
  int messageCount = 0; // New variable to count messages

  @override
  void initState() {
    super.initState();

    final selectedCity = ref.read(cityProvider);

    // Define the Firestore path
    _messagesCollection = FirebaseFirestore.instance
        .collection('Cities')
        .doc(selectedCity)
        .collection('Messages');

    // Reference the 'all_messages' document in the 'Messages' collection
    _messagesReference = _messagesCollection.doc('all_messages');

    _ensureDocumentExists();
    _fetchMessages();
  }

  void _ensureDocumentExists() async {
    final doc = await _messagesReference.get();
    if (!doc.exists) {
      await _messagesReference.set({'messages': []});
    }
  }

  void _fetchMessages() async {
    final messagesSnapshot = await _messagesReference.get();
    final List<Map<String, dynamic>> messages =
        _getMessagesFromSnapshot(messagesSnapshot);
    setState(() {
      _messages = messages;
      _filteredMessages = _messages;
      messageCount = _messages.length; // Update message count
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check access rights immediately before rendering
    final hasAccess = ref.read(hasPermissionProvider('CustomerNumbers'));

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
        title: const Text('Customers'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterMessages('');
                  },
                ),
              ),
              onChanged: _filterMessages,
            ),
            const SizedBox(height: 10),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a message';
                  }
                  return null;
                },
                maxLines: 3,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _sendMessage,
                    child: const Text('Send Message'),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _clearMessage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Clear'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _copyAllMessages,
                  child: const Text('Copy All Messages'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Saved Messages:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _buildMessagesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_filteredMessages.isEmpty) {
      return const Center(child: Text('No messages found'));
    }

    // Calculate total message count
    int totalMessageCount = _filteredMessages.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display total message count
        Center(
          child: Text(
            'Total Messages: $totalMessageCount',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 10),
        // List of messages
        Expanded(
          child: ListView.builder(
            itemCount: _filteredMessages.length,
            itemBuilder: (context, index) {
              final messageData = _filteredMessages[index];
              final message = messageData['message'];
              final timestamp =
                  (messageData['timestamp'] as Timestamp).toDate();

              return ListTile(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Date: ${DateFormat('MMM dd, yyyy hh:mm a').format(timestamp)}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () =>
                          _confirmPinAndEditMessage(context, index, message),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () =>
                          _confirmPinAndDeleteMessage(context, index, message),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _filterMessages(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredMessages = _messages;
      } else {
        _filteredMessages = _messages
            .where((msg) =>
                msg['message'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  List<Map<String, dynamic>> _getMessagesFromSnapshot(
      DocumentSnapshot snapshot) {
    final Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;

    if (data != null &&
        data.containsKey('messages') &&
        data['messages'] is List) {
      List<Map<String, dynamic>> messages =
          List<Map<String, dynamic>>.from(data['messages'] as List<dynamic>);

      // Sort messages based on timestamp in descending order
      messages.sort((a, b) {
        Timestamp timestampA = a['timestamp'];
        Timestamp timestampB = b['timestamp'];
        return timestampB.compareTo(timestampA);
      });

      return messages;
    }
    return [];
  }

  void _sendMessage() async {
    if (_formKey.currentState!.validate()) {
      final message = _messageController.text.trim();
      final timestamp = DateTime.now();

      final phoneNumbersInMessage = _extractPhoneNumbers(message);

      // Check if there are any phone numbers in the message
      if (phoneNumbersInMessage.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Message should contain at least one phone number with country code'),
          duration: Duration(seconds: 2),
        ));
        return;
      }

      final allMessagesSnapshot = await _messagesReference.get();
      final existingMessages = _getMessagesFromSnapshot(allMessagesSnapshot);

      final Set<String> allPhoneNumbers = existingMessages
          .expand((message) => _extractPhoneNumbers(message['message']))
          .toSet();

      final List<Map<String, dynamic>> newMessages = [];

      // Iterate through phone numbers in the message
      for (var phoneNumber in phoneNumbersInMessage) {
        // Add +92 if the number doesn't start with a country code
        if (!phoneNumber.startsWith('+')) {
          if (phoneNumber.startsWith('0')) {
            phoneNumber = '+92 ${phoneNumber.substring(1)}';
          } else {
            phoneNumber = '+92 $phoneNumber';
          }
        }

        // Check if the number already exists in the saved messages
        if (!allPhoneNumbers.contains(phoneNumber)) {
          newMessages.add({'message': phoneNumber, 'timestamp': timestamp});
        }
      }

      // Check if all phone numbers are duplicates
      if (newMessages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('All phone numbers are duplicates and not saved.'),
          duration: Duration(seconds: 2),
        ));
        return;
      }

      _messagesReference.update({
        'messages': FieldValue.arrayUnion(newMessages),
      }).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Message sent and saved successfully'),
          duration: Duration(seconds: 2),
        ));
        _messageController.clear();
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to send message: $error'),
          duration: const Duration(seconds: 2),
        ));
      });
    }
  }

  void _clearMessage() {
    _messageController.clear();
  }

  List<String> _extractPhoneNumbers(String message) {
    final phoneRegExp = RegExp(r'(\+92|0)?\s?3\d{2}\s?\d{7}');
    final matches = phoneRegExp.allMatches(message);
    return matches.map((match) {
      var normalizedNumber = match.group(0)!;
      // Add +92 if necessary
      if (!normalizedNumber.startsWith('+')) {
        if (normalizedNumber.startsWith('0')) {
          normalizedNumber = '+92${normalizedNumber.substring(1)}';
        } else {
          normalizedNumber = '+92$normalizedNumber';
        }
      }
      return normalizedNumber;
    }).toList();
  }

  void _copyAllMessages() async {
    final allMessagesSnapshot = await _messagesReference.get();
    final existingMessages = _getMessagesFromSnapshot(allMessagesSnapshot);

    if (existingMessages.isNotEmpty) {
      final messagesString =
          existingMessages.map((msg) => msg['message']).join('\n');
      await Clipboard.setData(ClipboardData(text: messagesString));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('All messages copied to clipboard'),
        duration: Duration(seconds: 2),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No messages to copy'),
        duration: Duration(seconds: 2),
      ));
    }
  }

  void _showDuplicateNumberDialog(Set<String> duplicateNumbers) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Duplicate Number Found'),
          content: Text(
              'The following number(s) already exist: ${duplicateNumbers.join(', ')}. Please change the number(s).'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _confirmPinAndEditMessage(
      BuildContext context, int index, String message) {
    final TextEditingController pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm PIN'),
          content: TextFormField(
            controller: pinController,
            decoration: const InputDecoration(labelText: 'Enter PIN'),
            keyboardType: TextInputType.number,
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter PIN';
              }
              if (value != '786') {
                return 'Incorrect PIN';
              }
              return null;
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (pinController.text == '786') {
                  Navigator.of(context).pop();
                  _editMessage(index, message);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Incorrect PIN'),
                    duration: Duration(seconds: 2),
                  ));
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _confirmPinAndDeleteMessage(
      BuildContext context, int index, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this message?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteMessage(index);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _editMessage(int index, String message) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController editController =
            TextEditingController(text: message);
        return AlertDialog(
          title: const Text('Edit Message'),
          content: TextFormField(
            controller: editController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Message'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a message';
              }
              return null;
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final updatedMessage = editController.text.trim();
                  final messagesSnapshot = await _messagesReference.get();
                  final List<Map<String, dynamic>> messages =
                      _getMessagesFromSnapshot(messagesSnapshot);
                  messages[index]['message'] = updatedMessage;
                  _messagesReference.update({'messages': messages}).then((_) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Message updated successfully'),
                      duration: Duration(seconds: 2),
                    ));
                  }).catchError((error) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Failed to update message: $error'),
                      duration: const Duration(seconds: 2),
                    ));
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteMessage(int index) async {
    final messagesSnapshot = await _messagesReference.get();
    final List<Map<String, dynamic>> messages =
        _getMessagesFromSnapshot(messagesSnapshot);
    messages.removeAt(index);
    _messagesReference.update({'messages': messages}).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Message deleted successfully'),
        duration: Duration(seconds: 2),
      ));
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to delete message: $error'),
        duration: const Duration(seconds: 2),
      ));
    });
  }
}
