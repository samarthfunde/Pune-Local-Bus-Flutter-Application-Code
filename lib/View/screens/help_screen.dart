import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  _HelpScreenState createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Emergency contact numbers
  final List<Map<String, dynamic>> emergencyContacts = [
    {
      'title': 'Police Emergency',
      'number': '100',
      'icon': Icons.local_police,
      'color': Colors.red,
      'description': '24/7 Police Emergency Services'
    },
    {
      'title': 'Women Helpline',
      'number': '181',
      'icon': Icons.woman,
      'color': Colors.pink,
      'description': '24/7 Women in Distress Helpline'
    },
    {
      'title': 'Medical Emergency',
      'number': '108',
      'icon': Icons.medical_services,
      'color': Colors.green,
      'description': 'Ambulance & Medical Emergency'
    },
    {
      'title': 'Fire Emergency',
      'number': '101',
      'icon': Icons.fire_truck,
      'color': Colors.orange,
      'description': 'Fire Brigade Emergency Services'
    },
    {
      'title': 'Child Helpline',
      'number': '1098',
      'icon': Icons.child_care,
      'color': Colors.blue,
      'description': 'Child in Need of Care & Protection'
    },
    {
      'title': 'Senior Citizen Helpline',
      'number': '14567',
      'icon': Icons.elderly,
      'color': Colors.purple,
      'description': 'Elder Care & Support Services'
    },
  ];

  // PMPML specific contacts
  final List<Map<String, dynamic>> pmpmlContacts = [
    {
      'title': 'PMPML Customer Care',
      'number': '020-27492323',
      'icon': Icons.support_agent,
      'color': Colors.blue,
      'description': 'General queries and complaints'
    },
    {
      'title': 'PMPML Control Room',
      'number': '020-27492424',
      'icon': Icons.control_camera,
      'color': Colors.indigo,
      'description': 'Bus tracking and route information'
    },
    {
      'title': 'Lost & Found',
      'number': '020-27492525',
      'icon': Icons.search,
      'color': Colors.brown,
      'description': 'Report lost items in buses'
    },
    {
      'title': 'Complaint Cell',
      'number': '020-27492626',
      'icon': Icons.report_problem,
      'color': Colors.red,
      'description': 'Lodge complaints about services'
    },
  ];

  // Safety tips
  final List<Map<String, dynamic>> safetyTips = [
    {
      'title': 'General Safety',
      'tips': [
        'Always keep your tickets and ID ready for verification',
        'Stand away from the bus door until it completely stops',
        'Hold handrails while the bus is moving',
        'Keep your belongings secure and close to you',
        'Be aware of your surroundings at all times',
        'Report any suspicious activity to the conductor or driver',
      ]
    },
    {
      'title': 'Women Safety',
      'tips': [
        'Use reserved seats meant for women when available',
        'Sit near the driver or conductor when traveling alone',
        'Keep emergency contacts easily accessible',
        'Trust your instincts - if something feels wrong, act',
        'Use the women helpline (181) if you feel unsafe',
        'Consider traveling with friends during late hours',
      ]
    },
    {
      'title': 'Digital Safety',
      'tips': [
        'Keep your phone charged for emergencies',
        'Share your live location with trusted contacts',
        'Keep digital copies of important documents',
        'Use official PMPML app for authentic information',
        'Be cautious while using public WiFi in buses',
        'Report technical issues with digital services',
      ]
    },
  ];

  // App instructions
  final List<Map<String, dynamic>> appInstructions = [
    {
      'title': 'Booking Tickets',
      'steps': [
        'Select your source and destination stops',
        'Choose your preferred payment method',
        'Confirm your booking details',
        'Complete the payment process',
        'Show your digital ticket to the conductor',
      ],
      'icon': Icons.confirmation_number,
    },
    {
      'title': 'Finding Routes',
      'steps': [
        'Use the route finder feature',
        'Enter your starting point and destination',
        'View available bus routes and timings',
        'Select the most convenient route',
        'Check real-time bus locations',
      ],
      'icon': Icons.route,
    },
    {
      'title': 'Managing Tickets',
      'steps': [
        'View all your tickets in "My Tickets" section',
        'Check ticket validity and expiry time',
        'Cancel tickets if cancellation is allowed',
      ],
      'icon': Icons.receipt_long,
    },
    {
      'title': 'Payment Options',
      'steps': [
        'UPI payments (PhonePe, Google Pay, etc.)',
        'Net banking from major banks',
        'Credit and debit cards',
        'Digital wallets',
        'Ensure secure payment methods only',
      ],
      'icon': Icons.payment,
    },
  ];

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        _showSnackBar('Could not launch phone dialer');
      }
    } catch (e) {
      _showSnackBar('Error making phone call');
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar('Copied to clipboard');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildEmergencyContactCard(Map<String, dynamic> contact) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              contact['color'].withOpacity(0.1),
              contact['color'].withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: contact['color'],
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                contact['icon'],
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact['title'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contact['description'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    contact['number'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: contact['color'],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  onPressed: () => _makePhoneCall(contact['number']),
                  icon: const Icon(Icons.call, color: Colors.green),
                  tooltip: 'Call',
                ),
                IconButton(
                  onPressed: () => _copyToClipboard(contact['number']),
                  icon: const Icon(Icons.copy, color: Colors.blue),
                  tooltip: 'Copy',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyTipsSection(Map<String, dynamic> section) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          section['title'],
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        leading: Icon(
          section['title'] == 'General Safety' ? Icons.security :
          section['title'] == 'Women Safety' ? Icons.woman :
          Icons.phone_android,
          color: Colors.blue,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: (section['tips'] as List<String>).map((tip) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tip,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionCard(Map<String, dynamic> instruction) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          instruction['title'],
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        leading: Icon(
          instruction['icon'],
          color: Colors.blue,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: (instruction['steps'] as List<String>).asMap().entries.map((entry) {
                int index = entry.key;
                String step = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          step,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection() {
    final List<Map<String, String>> faqs = [
      {
        'question': 'How do I book a ticket?',
        'answer': 'Select your source and destination, choose payment method, and complete the booking process. Your digital ticket will be available in "My Tickets" section.'
      },
      {
        'question': 'Can I cancel my ticket?',
        'answer': 'Ticket cancellation depends on the route and timing. Check the cancellation policy in your ticket details or contact customer care.'
      },
      {
        'question': 'What if I lose my phone with the digital ticket?',
        'answer': 'Contact PMPML customer care with your booking details. Keep a backup of your ticket ID and payment confirmation.'
      },
      {
        'question': 'Are there special fares for students/senior citizens?',
        'answer': 'Yes, PMPML offers concession rates for students and senior citizens. Valid ID proof is required for verification.'
      },
      {
        'question': 'What should I do if the bus is running late?',
        'answer': 'Check real-time bus tracking in the app. For major delays, contact the control room at 020-27492424.'
      },
      {
        'question': 'How do I report a safety concern?',
        'answer': 'Report immediately to the conductor/driver or call the complaint cell at 020-27492626. For emergencies, call 100.'
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: faqs.length,
      itemBuilder: (context, index) {
        final faq = faqs[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            title: Text(
              faq['question']!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  faq['answer']!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Help & Support',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(
              icon: Icon(Icons.emergency, size: 18),
              text: 'Emergency',
            ),
            Tab(
              icon: Icon(Icons.security, size: 18),
              text: 'Safety',
            ),
            Tab(
              icon: Icon(Icons.help_outline, size: 18),
              text: 'Instructions',
            ),
            Tab(
              icon: Icon(Icons.question_answer, size: 18),
              text: 'FAQ',
            ),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
        elevation: 0,
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Emergency Contacts Tab
          ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Emergency Contacts',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              ...emergencyContacts.map((contact) => _buildEmergencyContactCard(contact)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Text(
                  'PMPML Contacts',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              ...pmpmlContacts.map((contact) => _buildEmergencyContactCard(contact)),
            ],
          ),
          
          // Safety Tips Tab
          ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Safety Guidelines',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              ...safetyTips.map((section) => _buildSafetyTipsSection(section)),
            ],
          ),
          
          // App Instructions Tab
          ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'How to Use the App',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              ...appInstructions.map((instruction) => _buildInstructionCard(instruction)),
            ],
          ),
          
          // FAQ Tab
          _buildFAQSection(),
        ],
      ),
    );
  }
}