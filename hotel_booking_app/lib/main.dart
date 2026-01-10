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

    // 🌍 Landing Page
      case '/':
        return _noTransitionRoute(const LandingPage());

    // 🔐 Login Page (UI route)
      case '/weblogin':
        return _noTransitionRoute(const WebLoginPage());

    // 📝 Register Page (UI route)
      case '/register':
        return _noTransitionRoute(const WebRegisterPage());

    // 📊 Dashboard
      case '/dashboard':
        final args = settings.arguments as Map<String, String>?;
        if (args == null) {
          return _errorScreen("Missing partnerDetails for Dashboard");
        }
        return _noTransitionRoute(
          WebDashboardPage(partnerDetails: args),
        );

    // ❌ Unknown route
      default:
        return _errorScreen("Route not found: ${settings.name}");
    }
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
