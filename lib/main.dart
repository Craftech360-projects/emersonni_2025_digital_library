import 'package:digital_library/screens/categories_screen.dart';
import 'package:digital_library/screens/download_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://fujzjccponkdvxktlzjj.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ1anpqY2Nwb25rZHZ4a3RsempqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDMwNzQ2MjgsImV4cCI6MjA1ODY1MDYyOH0.2xcpIK1bNwoO_02LVDaWZY57tLpuq59otSoZHQCbQ3c',
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(DigitalLibraryApp());
}

class DigitalLibraryApp extends StatelessWidget {
  const DigitalLibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Library',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const Wrapper(),
      },
      onGenerateRoute: (settings) {
        // Handle the member_signup route with token parameter
        if (settings.name == '/download') {
          // Extract token from arguments
          final token = settings.arguments as String? ?? '';

          return MaterialPageRoute(
            builder: (context) => DownloadScreen(
              downloadId: token,
            ),
          );
        }
        return null;
      },
      theme: ThemeData(
        fontFamily: 'NotoSans',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6750A4), width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkDownloadLink();
  }

  void _checkDownloadLink() {
    // Check if there's a token in the URL
    final uri = Uri.base;
    final fragment = uri.fragment;

    // Handle hash fragment URLs like /#/member_signup?token=xyz
    if (fragment.startsWith('/download')) {
      final tokenParam = Uri.parse(fragment).queryParameters['token'];
      if (tokenParam != null && tokenParam.isNotEmpty) {
        debugPrint('Found token in URL fragment: $tokenParam');
        // Navigate to signup screen with the token
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/download',
              arguments: tokenParam);
        });
        return;
      }
    }

    // Also check regular query parameters (fallback)
    final token = uri.queryParameters['token'];
    if (token != null && token.isNotEmpty) {
      debugPrint('Found token in URL parameters: $token');
      // Navigate to signup screen with the token
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/download', arguments: token);
      });
    }
    _isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return const CategoriesScreen();
  }
}
