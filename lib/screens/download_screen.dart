import 'package:digital_library/core/app_colors.dart';
import 'package:digital_library/services/download_service.dart';
import 'package:digital_library/services/email.dart';
import 'package:flutter/material.dart';

class DownloadScreen extends StatefulWidget {
  final String downloadId;

  const DownloadScreen({
    super.key,
    required this.downloadId,
  });

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  final EmailService _emailService = EmailService();
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _checkoutData;
  List<Map<String, dynamic>> _books = [];

  @override
  void initState() {
    super.initState();
    _loadDownloadData();
  }

  Future<void> _loadDownloadData() async {
    try {
      // Get checkout data by token
      final checkoutData =
          await _emailService.getCheckoutByToken(widget.downloadId);

      if (checkoutData == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Download link not found or expired';
        });
        return;
      }

      // Check if link is expired
      final expiresAt = DateTime.parse(checkoutData['expires_at']);
      if (expiresAt.isBefore(DateTime.now())) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'This download link has expired';
        });
        return;
      }

      // Get book details
      final List<String> bookIds = List<String>.from(checkoutData['book_ids']);
      final books = await _emailService.getBookDetailsByIds(bookIds);

      setState(() {
        _isLoading = false;
        _checkoutData = checkoutData;
        _books = books;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load download data: $e';
      });
    }
  }

  Future<void> _downloadPdf(String pdfFilename, String title) async {
    try {
      await DownloadService.downloadFile(pdfFilename);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Downloads'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
              color: AppColors.white,
            ))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your PDFs are ready to download',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Click on each item to download',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                      SizedBox(height: 24),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _books.length,
                          itemBuilder: (context, index) {
                            final book = _books[index];
                            return Card(
                              margin: EdgeInsets.only(bottom: 16),
                              child: ListTile(
                                leading: Icon(Icons.picture_as_pdf,
                                    color: Colors.red),
                                title: Text(book['title']),
                                subtitle: Text('Click to download'),
                                trailing: IconButton(
                                  icon: Icon(Icons.download,
                                      color: AppColors.primary),
                                  onPressed: () => _downloadPdf(
                                      book['pdf_filename'], book['title']),
                                ),
                                onTap: () => _downloadPdf(
                                    book['pdf_filename'], book['title']),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 16),
                      Center(
                        child: Text(
                          'This download link will expire on ${DateTime.parse(_checkoutData!['expires_at']).toLocal().toString().split(' ')[0]}',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
