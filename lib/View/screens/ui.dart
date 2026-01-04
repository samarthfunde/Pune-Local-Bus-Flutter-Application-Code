import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pmpml_app/constant/constant_ui.dart';

import 'LanguageController.dart';
import 'signup_screen.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class UIScreen extends StatefulWidget {
  const UIScreen({super.key});

  @override
  State<UIScreen> createState() => _UIScreenState();
}

class _UIScreenState extends State<UIScreen> {
  late PageController _controller;
  bool isLastPage = false;

  @override
  void initState() {
    super.initState();
    // Check if there's an initial page argument
    final args = Get.arguments;
    final initialPage = args != null && args['initialPage'] != null ? args['initialPage'] as int : 0;
    
    // Initialize controller with the initial page
    _controller = PageController(initialPage: initialPage);
    
    // Set isLastPage accordingly
    isLastPage = initialPage == 2;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (index) {
                    setState(() {
                      isLastPage = index == 2;
                    });
                  },
                  children: const [
                    SlidePage(
                      icon: Icons.public,
                      title: 'Book Your Online Bus Ticket',
                      subtitle: "Book tickets easily from your phone.",
                    ),
                    SlidePage(
                      icon: Icons.directions_bus,
                      title: 'Digital Bus Management System',
                      subtitle: "Experience a modern and efficient bus service.",
                    ),
                    LanguageSelectionPage(),
                  ],
                ),
              ),
              SmoothPageIndicator(
                controller: _controller,
                count: 3,
                effect: const ExpandingDotsEffect(
                  dotWidth: 10,
                  dotHeight: 10,
                  activeDotColor: Colors.amber,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class SlidePage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const SlidePage({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  
  TextStyle get titleTextStyle => const TextStyle(
    fontSize: 24, 
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
  
  TextStyle get subtitleTextStyle => const TextStyle(
    fontSize: 16,
    color: Colors.white70,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 70, color: Colors.amber),
        const SizedBox(height: 20),
        Text(title, style: titleTextStyle),
        const SizedBox(height: 10),
        Text(subtitle, style: subtitleTextStyle, textAlign: TextAlign.center),
      ],
    );
  }
}

class LanguageSelectionPage extends StatefulWidget {
  const LanguageSelectionPage({super.key});

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
  final List<Map<String, String>> languages = [
    {'code': 'EN', 'name': 'English'},
    {'code': 'HI', 'name': 'हिंदी'},
    {'code': 'MR', 'name': 'मराठी'},
    {'code': 'TA', 'name': 'தமிழ்'},
    {'code': 'TE', 'name': 'తెలుగు'},
  ];

  String? selectedLanguageCode;
  final LanguageController languageController = Get.put(LanguageController());

  // Function to convert language code to language name
  String getLanguageName(String code) {
    switch (code) {
      case 'EN': return 'English';
      case 'HI': return 'Hindi';
      case 'MR': return 'Marathi';
      case 'TA': return 'Tamil';
      case 'TE': return 'Telugu';
      default: return 'English';
    }
  }

  // Function to convert language code to locale code
  String getLocaleCode(String code) {
    switch (code) {
      case 'EN': return 'en';
      case 'HI': return 'hi';
      case 'MR': return 'mr';
      case 'TA': return 'ta';
      case 'TE': return 'te';
      default: return 'en';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Select Your Language',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: languages.map((language) {
            bool isSelected = language['code'] == selectedLanguageCode;
            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedLanguageCode = language['code'];
                });
              },
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: isSelected ? Colors.lightBlueAccent : Colors.white,
                elevation: isSelected ? 6 : 4,
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        language['code']!,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.amber,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        language['name']!,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 30),
        if (selectedLanguageCode != null)
          ElevatedButton(
            onPressed: () async {
              // Get the language name
              String languageName = getLanguageName(selectedLanguageCode!);
              
              // Update the controller with selected language
              languageController.selectLanguage(languageName);
              await languageController.saveLanguage();
              
              // Directly update the app locale
              String localeCode = getLocaleCode(selectedLanguageCode!);
              Get.updateLocale(Locale(localeCode));
              
              // Navigate to LoginScreen instead of HomeScreen
              Get.off(() =>  SignupScreen());
            },
            style: primaryButtonStyle?.copyWith(
              backgroundColor: MaterialStateProperty.all(const Color.fromARGB(255, 7, 218, 255)),
            ) ?? ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 7, 218, 255),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "CONTINUE",
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }
}