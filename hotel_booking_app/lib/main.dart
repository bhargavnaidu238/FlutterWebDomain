import 'package:flutter/material.dart';
import 'partner_portal/web_screens/web_login.dart';
import 'partner_portal/web_screens/web_register.dart';
import 'partner_portal/web_screens/web_dashboard_page.dart';
import 'partner_portal/web_screens/Domain_Landing_Page.dart';
import 'services/api_service.dart';

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

      // ✅ AUTO CHECK LOGIN ON APP START
      initialRoute: ApiService.isLoggedIn() ? '/dashboard' : '/',

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

    // ================= LANDING PAGE =================
      case '/':
        return _noTransitionRoute(const LandingPage(), settings);

    // ================= LOGIN PAGE =================
      case '/weblogin':
        return _noTransitionRoute(const WebLoginPage(), settings);

    // ================= REGISTER PAGE =================
      case '/registerlogin':
        return _noTransitionRoute(const WebRegisterPage(), settings);

    // ================= DASHBOARD (PROTECTED) =================
      case '/dashboard':

      // 🔐 BLOCK ACCESS IF NOT LOGGED IN
        if (!loggedIn) {
          debugPrint("Blocked unauthorized dashboard access.");
          return _noTransitionRoute(const WebLoginPage(), settings);
        }

        final args = settings.arguments as Map<String, String>?;

        // If arguments missing but user logged in,
        // retrieve stored values from localStorage
        if (args == null) {

          final email = ApiService.getEmail();
          final userId = ApiService.getUserId();

          if (email == null || userId == null) {
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

        return _noTransitionRoute(
          WebDashboardPage(partnerDetails: args),
          settings,
        );

    // ================= DEFAULT =================
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
            style: const TextStyle(
              color: Colors.red,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}