import 'package:emailjs/emailjs.dart' as emailjs;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class EmailService {
  static const String _serviceId = 'service_zpxd5mr';
  // 'service_4okniss';
  static const String _templateId = 'template_mfp3epc';
  //  'template_99s8twi';
  static const String _userId = 'Y2m2PUT2aeoAbMAPC';
  static const String _accessToken = 'HBwHv0Lg_ljVqxgIOnCn3';
  // '2IQ6chhM6W2m7I1uotFQY';

  // static const String _baseDownloadUrl =
  //     'https://digital-library-flutter.vercel.app/#/download';

  late final SupabaseClient _supabase;

  EmailService() {
    _supabase = Supabase.instance.client;
  }

  Future<void> sendDownloadEmail({
    required String toEmail,
    required List<String> bookIds,
    required List<Map<String, dynamic>> bookDetails,
  }) async {
    try {
      // Create a unique download ID
      final downloadToken = const Uuid().v4();

      // Store in Supabase - make sure table name is consistent
      await _supabase.from('checkouts').insert({
        'email': toEmail,
        'book_ids': bookIds,
        'created_at': DateTime.now().toIso8601String(),
        'expires_at':
            DateTime.now().add(const Duration(days: 3)).toIso8601String(),
        'download_token': downloadToken,
      });

      // Create download link with hash
      final downloadLink =
          'https://emersonni-2025-digital-library.vercel.app/#/download?token=$downloadToken';

      // Format book list for email
      final booksList =
          bookDetails.map((book) => '• ${book['title']}').join('\n');

      // Send email using EmailJS
      await emailjs.send(
        _serviceId,
        _templateId,
        {
          'email': toEmail,
          'name': toEmail.split('@').first,
          'download_link': downloadLink,
          'books_list': booksList,
          'book_count': bookDetails.length.toString(),
          'expiry_days': '3',
          'order_date': DateTime.now().toLocal().toString().split(' ')[0],
        },
        const emailjs.Options(
          publicKey: _userId,
          privateKey: _accessToken,
        ),
      );
    } catch (e) {
      throw Exception('Failed to send download email: $e');
    }
  }

  // Get checkout information by token - fix table name to match
  Future<Map<String, dynamic>?> getCheckoutByToken(String token) async {
    try {
      final response = await _supabase
          .from('checkouts')
          .select()
          .eq('download_token', token)
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  // Get book details by IDs
  Future<List<Map<String, dynamic>>> getBookDetailsByIds(
      List<String> bookIds) async {
    final response =
        await _supabase.from('books').select().inFilter('id', bookIds);

    return List<Map<String, dynamic>>.from(response);
  }
}
