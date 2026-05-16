import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  // ===================== Social Media icons Section or Row ========================
  Widget _socialIcon(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      splashColor: color.withOpacity(0.3),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Center(child: FaIcon(icon, color: color, size: 22)),
      ),
    );
  }

  // Header and NavBar
  Widget _header(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 600;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 16),
      color: Colors.green.shade700,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "flemingostays.com",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/weblogin'),
                child: Text(
                    "Login",
                    style: TextStyle(color: Colors.white, fontSize: isMobile ? 14 : 16)
                ),
              ),
              SizedBox(width: isMobile ? 4 : 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
                ),
                onPressed: () => Navigator.pushNamed(context, '/registerlogin'),
                child: Text(
                  isMobile ? "Join" : "List Your Property",
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 12 : 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Hero Section
  Widget _heroSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade700, Colors.green.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 900;
          return isWide
              ? Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Grow Your Hotel Business with flemingostays.com",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Join 5,000+ hotel partners worldwide. Increase your occupancy by up to 40% using our AI-driven booking engine and seamless property management tools.",
                      style: TextStyle(color: Colors.white, fontSize: 20, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                        elevation: 4,
                      ),
                      onPressed: () => Navigator.pushNamed(context, '/registerlogin'),
                      child: Text(
                        "Start Growing Today",
                        style: TextStyle(color: Colors.green.shade700, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 50),
              Expanded(
                child: Image.asset(
                  'assets/LandingPageImages/LandingImage.png',
                  fit: BoxFit.contain,
                  height: 400,
                ),
              ),
            ],
          )
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Grow Your Hotel Business with flemingostays.com",
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                "Join 5,000+ hotel partners. Increase occupancy by up to 40% with our automated tools.",
                style: TextStyle(color: Colors.white, fontSize: 18, height: 1.4),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                onPressed: () => Navigator.pushNamed(context, '/registerlogin'),
                child: Text(
                  "Get Started",
                  style: TextStyle(color: Colors.green.shade700, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 40),
              Center(
                child: Image.asset(
                  'assets/LandingPageImages/LandingImage2.png',
                  fit: BoxFit.contain,
                  height: 250,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Offerings Section
  Widget _offeringsSection() {
    final offerings = [
      {"title": "Smart PMS", "desc": "Automated room allocation and guest check-ins to reduce operational overhead.", "icon": Icons.hotel_class},
      {"title": "Revenue Manager", "desc": "Dynamic pricing algorithms that adjust rates based on local demand.", "icon": Icons.payments},
      {"title": "Global Distribution", "desc": "Sync your inventory instantly across 200+ booking channels.", "icon": Icons.language},
      {"title": "Guest Analytics", "desc": "Detailed reporting on guest preferences to personalize their stay.", "icon": Icons.analytics},
    ];

    return Container(
      color: Colors.green.shade50,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Column(
        children: [
          Text(
            "Powerful Features to Scale Your Property",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green.shade900),
          ),
          const SizedBox(height: 12),
          const Text(
            "Everything you need to manage your business efficiently.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 48),
          Wrap(
            spacing: 30,
            runSpacing: 30,
            alignment: WrapAlignment.center,
            children: offerings.map((offer) {
              return Container(
                width: 280,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.green.shade100, blurRadius: 15, offset: const Offset(0, 8))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                      child: Icon(offer["icon"] as IconData, size: 36, color: Colors.green.shade700),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      offer["title"] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      offer["desc"] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Testimonials Section
  Widget _testimonialsSection() {
    final testimonials = [
      {"name": "The Grand Heritage", "feedback": "Switching to flemingostays.com reduced our double-booking errors to zero.", "location": "Hyderbad, Telangana"},
      {"name": "Urban Stay Boutique", "feedback": "The revenue management tool boosted our profit by 30%.", "location": "Bangalore, Karnataka"},
      {"name": "Sunset Resort", "feedback": "Highly recommended for streamlining daily operations.", "location": "Chennai, Tamil Nadu"},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Column(
        children: [
          Text(
            "Trusted by Owners Worldwide",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green.shade700),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: testimonials.map((t) {
              return Container(
                width: 300,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade100),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.format_quote, color: Colors.green, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      "${t['feedback']}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t['name']!,
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade900),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Business Section
  Widget _businessSection() {
    return LayoutBuilder(builder: (context, constraints) {
      bool isMobile = constraints.maxWidth < 600;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.green.shade900,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Text(
              "Ready to Optimize Your Property?",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: isMobile ? 22 : 26, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 20,
              runSpacing: 10,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.email, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text("admin@flemingostays.com", style: TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.phone, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text("+91-93811-01173", style: TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _header(context),
            _heroSection(context),
            _offeringsSection(),
            _testimonialsSection(),
            _businessSection(),
            const SizedBox(height: 24),
            const Text(
              "Follow our community:",
              style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 22,
              runSpacing: 15,
              children: [
                _socialIcon(FontAwesomeIcons.facebookF, const Color(0xFF1877F2), () {}),
                _socialIcon(FontAwesomeIcons.instagram, const Color(0xFFE4405F), () {}),
                _socialIcon(FontAwesomeIcons.xTwitter, const Color(0xFF000000), () {}),
                _socialIcon(FontAwesomeIcons.linkedinIn, const Color(0xFF0A66C2), () {}),
                _socialIcon(FontAwesomeIcons.youtube, const Color(0xFFFF0000), () {}),
              ],
            ),
            const SizedBox(height: 40),
            const Divider(indent: 50, endIndent: 50),
            const SizedBox(height: 20),
            const Text(
              "© 2026 flemingostays.com. All rights reserved.",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}