import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../core/app_colors.dart';

class PDFViewerScreen extends StatefulWidget {
  final String pdfPath;
  final String title;

  const PDFViewerScreen({
    super.key,
    required this.pdfPath,
    required this.title,
  });

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  String? pdfUrl;
  bool isLoading = true;
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  late PdfViewerController _pdfViewerController;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    loadPDF();
  }

  Future<void> loadPDF() async {
    try {
      final String signedUrl = await Supabase.instance.client.storage
          .from('books')
          .createSignedUrl(widget.pdfPath, 3600);


      setState(() {
        pdfUrl = signedUrl;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          widget.title,
          style: TextStyle(color: AppColors.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(
              Icons.bookmark,
              color: Colors.white,
            ),
            onPressed: () {
              _pdfViewerKey.currentState?.openBookmarkView();
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.zoom_in,
              color: Colors.white,
            ),
            onPressed: () {
              _pdfViewerController.zoomLevel =
                  _pdfViewerController.zoomLevel + 1;
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.zoom_out,
              color: Colors.white,
            ),
            onPressed: () {
              _pdfViewerController.zoomLevel =
                  _pdfViewerController.zoomLevel - 1;
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
              color: AppColors.white,
            ))
          : pdfUrl == null
              ? Center(child: Text('Failed to load PDF'))
              : Center(
                  child: Container(
                    padding: EdgeInsets.all(8),
                    margin: EdgeInsets.all(16),
                    width: MediaQuery.of(context).size.width * 0.4,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppColors.blueGreyDark, width: 3),
                    ),
                    child: SfPdfViewer.network(
                      pdfUrl!,
                      key: _pdfViewerKey,
                      controller: _pdfViewerController,
                      enableTextSelection: true,
                      enableDocumentLinkAnnotation: true,
                      enableDoubleTapZooming: true,
                      pageSpacing: 4,
                      onDocumentLoadFailed:
                          (PdfDocumentLoadFailedDetails details) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${details.error}')),
                        );
                      },
                      onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                      },
                    ),
                  ),
                ),
    );
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }
}
