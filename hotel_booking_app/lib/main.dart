import 'package:flutter/material.dart';
import 'partner_portal/web_screens/web_login.dart';
import 'partner_portal/web_screens/web_register.dart';
import 'partner_portal/web_screens/web_dashboard_page.dart';
import 'partner_portal/web_screens/Domain_Landing_Page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Hotel Booking App",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
      initialRoute: '/',
      onGenerateRoute: _generateRoute,
    );
  }

  // Helper for instant page switching (standard for Web Apps)
  Route<dynamic> _noTransitionRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }

  Route<dynamic> _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return _noTransitionRoute(const LandingPage(), settings);

      case '/weblogin':
        return _noTransitionRoute(const WebLoginPage(), settings);

      case '/registerlogin':
        return _noTransitionRoute(const WebRegisterPage(), settings);

      case '/dashboard':
      // Try to cast the arguments
        final args = settings.arguments as Map<String, String>?;

        // If arguments are missing, we redirect to login instead of showing a red error
        if (args == null) {
          debugPrint("Redirecting to login: No partner details found.");
          return _noTransitionRoute(const WebLoginPage(), settings);
        }

        return _noTransitionRoute(
          WebDashboardPage(partnerDetails: args),
          settings,
        );

      default:
        return _errorScreen("Route not found: ${settings.name}");
    }
  }

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