import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'partner_portal/web_screens/web_login.dart';
import 'partner_portal/web_screens/web_register.dart';
import 'partner_portal/web_screens/web_dashboard_page.dart';
import 'partner_portal/web_screens/Domain_Landing_Page.dart';
import 'services/api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase from backend config
  await _initializeSupabaseFromBackend();

  runApp(const MyApp());
}

Future<void> _initializeSupabaseFromBackend() async {
  try {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/config/supabase"),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      await Supabase.initialize(
        url: decoded['url'],
        anonKey: decoded['anonKey'],
      );
      debugPrint("Supabase initialized successfully.");
    }
  } catch (e) {
    debugPrint("Supabase initialization error: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Determine the starting point based on persistent storage in ApiService
    final String initialRoute = ApiService.isLoggedIn() ? '/dashboard' : '/';

    return MaterialApp(
      title: "Hotel Booking App",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
      initialRoute: initialRoute,
      onGenerateRoute: _generateRoute,
    );
  }

  // ================== NO TRANSITION ROUTE ==================
  Route<dynamic> _noTransitionRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }

  // ================== ROUTE GENERATOR ==================
  Route<dynamic> _generateRoute(RouteSettings settings) {
    final bool loggedIn = ApiService.isLoggedIn();

    switch (settings.name) {
      case '/':
        return _noTransitionRoute(const LandingPage(), settings);

      case '/weblogin':
        return _noTransitionRoute(const WebLoginPage(), settings);

      case '/registerlogin':
        return _noTransitionRoute(const WebRegisterPage(), settings);

      case '/dashboard':
      // 1. Guard against unauthenticated access
        if (!loggedIn) {
          debugPrint("Blocked unauthorized dashboard access.");
          return _noTransitionRoute(const WebLoginPage(), settings);
        }

        // 2. Try to get arguments (this works during normal navigation)
        final args = settings.arguments as Map<String, String>?;

        if (args != null) {
          return _noTransitionRoute(WebDashboardPage(partnerDetails: args), settings);
        } else {
          // 3. REFRESH RECOVERY: Pull from ApiService (LocalStorage)
          final email = ApiService.getEmail();
          final userId = ApiService.getUserId();

          if (email == null || userId == null) {
            return _noTransitionRoute(const WebLoginPage(), settings);
          }

          // IMPORTANT: We must include 'Partner_ID' as a key because
          // your WebDashboardPage code is looking specifically for it.
          return _noTransitionRoute(
            WebDashboardPage(
              partnerDetails: {
                "email": email,
                "userId": userId,
                "Partner_ID": userId, // Added this to fix your specific error
              },
            ),
            settings,
          );
        }

      default:
        return _errorScreen("Route not found: ${settings.name}");
    }
  }

  // ================= ERROR SCREEN =================
  MaterialPageRoute _errorScreen(String msg) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(
          child: Text(
            msg,
            style: const TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}