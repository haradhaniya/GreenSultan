import 'dart:io'; // For File operations
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart'; // For opening files
import 'package:share_plus/share_plus.dart'; // For sharing files
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart'; // For PDF viewer

class PdfViewerDialog extends StatelessWidget {
  final Uint8List pdfBytes;
  final double paidAmount; // Added to display paid amount

  const PdfViewerDialog({
    super.key,
    required this.pdfBytes,
    required this.paidAmount,
  });

  Future<void> _shareInvoice() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFilePath = '${tempDir.path}/invoice.pdf';
      File tempFile = File(tempFilePath);

      // Ensure the PDF file is generated and written
      await tempFile.writeAsBytes(pdfBytes);

      // Check if the file exists before sharing
      if (await tempFile.exists()) {
        // Open the PDF file using the open_file package
        OpenFile.open(tempFilePath);

        // Share the file via the Share Plus package
        Share.shareXFiles(
          [XFile(tempFile.path)],
          text: 'Sharing PDF Invoice',
        );
      } else {
        print('Error: PDF file does not exist at $tempFilePath');
      }
    } catch (e) {
      print('Error sharing PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: Column(
          children: [
            Expanded(
              child: SfPdfViewer.memory(
                pdfBytes,
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: _shareInvoice,
          child: const Text('Share'),
        ),
      ],
    );
  }
}
