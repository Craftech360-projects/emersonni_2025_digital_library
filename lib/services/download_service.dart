import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';

class DownloadService {
  static Future<void> downloadFile(String pdfFilename) async {
    try {
      final String downloadUrl = await Supabase.instance.client.storage
          .from('books')
          .createSignedUrl(pdfFilename, 300);

      if (kIsWeb) {
        // Web platform - create a temporary link and trigger download
        final anchor = html.AnchorElement()
          ..href = downloadUrl
          ..download = pdfFilename
          ..style.display = 'none';
        html.document.querySelector('body')!.append(anchor);
        anchor.click();
        anchor.remove();
      } else {
        // Mobile/Desktop platforms - use url_launcher
        await _launchUrl(downloadUrl);
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
}
