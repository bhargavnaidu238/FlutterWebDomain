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

  // Initialize Supabase (this also helps restore Supabase auth session if used)
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
    // Determine the starting point based on persistent storage
    final String initialRoute = ApiService.isLoggedIn() ? '/dashboard' : '/';

    return MaterialApp(
      title: "Hotel Booking App",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
      initialRoute: initialRoute,
      onGenerateRoute: _generateRoute,
    );
  }

  Route<dynamic> _noTransitionRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }

  Route<dynamic> _generateRoute(RouteSettings settings) {
    // Always check fresh state from ApiService (which now reads localStorage)
    final bool loggedIn = ApiService.isLoggedIn();

    switch (settings.name) {
      case '/':
        return _noTransitionRoute(const LandingPage(), settings);

      case '/weblogin':
        return _noTransitionRoute(const WebLoginPage(), settings);

      case '/registerlogin':
        return _noTransitionRoute(const WebRegisterPage(), settings);

      case '/dashboard':
        if (!loggedIn) {
          return _noTransitionRoute(const WebLoginPage(), settings);
        }

        // Handle arguments or recovery from refresh
        final args = settings.arguments as Map<String, String>?;

        if (args != null) {
          return _noTransitionRoute(WebDashboardPage(partnerDetails: args), settings);
        } else {
          // RECOVERY LOGIC: If args are null (happens on refresh),
          // pull directly from our persisted ApiService
          final email = ApiService.getEmail();
          final userId = ApiService.getUserId();

          if (email == null || userId == null) {
            debugPrint("Session data missing on refresh, redirecting to login.");
            return _noTransitionRoute(const WebLoginPage(), settings);
          }

          return _noTransitionRoute(
            WebDashboardPage(
              partnerDetails: {
                "email": email,
                "userId": userId,
              },
            ),
            settings,
          );
        }

      default:
        return _errorScreen("Route not found: ${settings.name}");
    }
  }

  MaterialPageRoute _errorScreen(String msg) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(child: Text(msg, style: const TextStyle(color: Colors.red))),
      ),
    );
  }
}