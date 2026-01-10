import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_strategy/url_strategy.dart';
import 'partner_portal/web_screens/web_login.dart';
import 'partner_portal/web_screens/web_register.dart';
import 'partner_portal/web_screens/web_dashboard_page.dart';
import 'partner_portal/web_screens/Domain_Landing_Page.dart';

void main() {
  if (kIsWeb) {
    // Removes # from Flutter web URLs
    setPathUrlStrategy();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Hotel Booking App",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      initialRoute: '/',
      onGenerateRoute: _generateRoute,
    );
  }

  /// No-animation route (better UX on web)
  Route<dynamic> _noTransitionRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }

  /// Centralized, web-safe routing
  Route<dynamic> _generateRoute(RouteSettings settings) {
    switch (settings.name) {

    // Landing Page
      case '/':
        return _noTransitionRoute(const LandingPage());

    // Login Page
      case '/weblogin':
        return _noTransitionRoute(const WebLoginPage());

    // Register Page
      case '/register':
        return _noTransitionRoute(const WebRegisterPage());

    // Dashboard (REFRESH-SAFE)
      case '/dashboard':
        final Map<String, String> partnerDetails =
        _resolvePartnerDetails(settings.arguments);

        if (partnerDetails.isEmpty) {
          return _errorScreen(
            "Session expired. Please login again.",
          );
        }

        return _noTransitionRoute(
          WebDashboardPage(partnerDetails: partnerDetails),
        );

    // Unknown route
      default:
        return _errorScreen("Route not found: ${settings.name}");
    }
  }

  /// Resolve partner details from:
  /// 1. Navigator arguments
  /// 2. sessionStorage (web refresh-safe)
  Map<String, String> _resolvePartnerDetails(Object? args) {
    // Navigator arguments (normal navigation)
    if (args is Map<String, String> && args.isNotEmpty) {
      if (kIsWeb) {
        html.window.sessionStorage['partnerDetails'] =
            jsonEncode(args);
      }
      return args;
    }

    // sessionStorage (page refresh / direct URL)
    if (kIsWeb) {
      final stored =
      html.window.sessionStorage['partnerDetails'];
      if (stored != null && stored.isNotEmpty) {
        final decoded =
        Map<String, dynamic>.from(jsonDecode(stored));
        return decoded.map(
              (key, value) => MapEntry(key, value.toString()),
        );
      }
    }

    return {};
  }

  /// Simple error screen
  MaterialPageRoute _errorScreen(String msg) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(
          child: Text(
            msg,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 20,
            ),
          ),
        ),
      ),
    );
  }
}
