import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  // ===================== Social Media icons Section ========================
  Widget _socialIcon(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: FaIcon(icon, color: color, size: 20)),
      ),
    );
  }

  // Responsive Header
  Widget _header(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 600;

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 40,
          vertical: 16
      ),
      color: Colors.green.shade700,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "partner.com",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/weblogin'),
                child: Text(
                    "Login",
                    style: TextStyle(color: Colors.white, fontSize: isMobile ? 13 : 15)
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 20,
                      vertical: isMobile ? 8 : 12
                  ),
                ),
                onPressed: () => Navigator.pushNamed(context, '/registerlogin'),
                child: Text(
                  isMobile ? "Join" : "Register Now",
                  style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Responsive Hero Section
  Widget _heroSection(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isWide = screenWidth > 900;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          vertical: isWide ? 100 : 60,
          horizontal: isWide ? 80 : 24
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade800, Colors.green.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: isWide
              ? Row(
            children: [
              Expanded(child: _heroContent(context, true)),
              const SizedBox(width: 50),
              Expanded(
                child: Image.asset(
                  'assets/LandingPageImages/LandingImage.png',
                  fit: BoxFit.contain,
                  height: 450,
                ),
              ),
            ],
          )
              : Column(
            children: [
              _heroContent(context, false),
              const SizedBox(height: 50),
              Image.asset(
                'assets/LandingPageImages/LandingImage2.png',
                fit: BoxFit.contain,
                height: 280,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroContent(BuildContext context, bool isWide) {
    return Column(
      crossAxisAlignment: isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(
          "Scale Your Hotel Revenue Effortlessly",
          textAlign: isWide ? TextAlign.left : TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: isWide ? 48 : 32,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "Join the global network of 10,000+ properties using our AI-powered booking engine to increase direct sales by 35%.",
          textAlign: isWide ? TextAlign.left : TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: isWide ? 20 : 17,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => Navigator.pushNamed(context, '/registerlogin'),
          child: Text(
            "Start Your Free Trial",
            style: TextStyle(color: Colors.green.shade800, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // Responsive Offerings Section
  Widget _offeringsSection(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    final offerings = [
      {"title": "Global Exposure", "desc": "Connect to 400+ OTAs instantly via our Channel Manager.", "icon": Icons.public},
      {"title": "Direct Bookings", "desc": "Commission-free booking engine for your own website.", "icon": Icons.touch_app},
      {"title": "Smart Analytics", "desc": "Real-time data on occupancy, ADR, and RevPAR.", "icon": Icons.bar_chart},
      {"title": "Mobile App", "desc": "Manage your front desk from anywhere in the world.", "icon": Icons.smartphone},
    ];

    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        children: [
          Text(
            "Designed for Modern Hospitality",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.green.shade900),
          ),
          const SizedBox(height: 50),
          Wrap(
            spacing: 25,
            runSpacing: 25,
            alignment: WrapAlignment.center,
            children: offerings.map((offer) {
              return Container(
                width: screenWidth > 700 ? 300 : screenWidth * 0.85,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.green.shade50.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(offer["icon"] as IconData, size: 40, color: Colors.green.shade700),
                    const SizedBox(height: 15),
                    Text(
                      offer["title"] as String,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      offer["desc"] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15, color: Colors.black54, height: 1.4),
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
      {"name": "Marina Bay Suites", "feedback": "Revenue grew by 20% in just 3 months. The interface is incredibly fast." },
      {"name": "The Alpine Lodge", "feedback": "Support is 24/7. They helped us migrate 500+ bookings in one day." },
    ];

    return Container(
      color: Colors.grey.shade50,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        children: [
          const Text(
            "Success Stories",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: testimonials.map((t) {
              return Container(
                width: 350,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.format_quote, color: Colors.green, size: 30),
                    const SizedBox(height: 15),
                    Text(
                      "\"${t['feedback']}\"",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      t['name']!,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
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
  Widget _businessSection(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      margin: EdgeInsets.symmetric(
          vertical: 40,
          horizontal: screenWidth > 800 ? 80 : 20
      ),
      decoration: BoxDecoration(
        color: Colors.green.shade900,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: const [
          Text(
            "Grow with us",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 20),
          Text(
            "✉ corporate@partner.com\n☎ +1-800-PARTNER-PRO",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.white, height: 1.6),
          ),
        ],
      ),
    );
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
            _offeringsSection(context),
            _testimonialsSection(),
            _businessSection(context),
            const SizedBox(height: 30),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 15,
              runSpacing: 15,
              children: [
                _socialIcon(FontAwesomeIcons.facebook, const Color(0xFF1877F2), () {}),
                _socialIcon(FontAwesomeIcons.instagram, const Color(0xFFE4405F), () {}),
                _socialIcon(FontAwesomeIcons.twitter, const Color(0xFF1DA1F2), () {}),
                _socialIcon(FontAwesomeIcons.linkedin, const Color(0xFF0A66C2), () {}),
                _socialIcon(FontAwesomeIcons.youtube, const Color(0xFFFF0000), () {}),
              ],
            ),
            const SizedBox(height: 40),
            Text(
              "© 2026 Partner.com. All rights reserved.",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}