import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pmpml_app/constant/constant_ui.dart';
import 'pass_phonepay.dart';

class BusPassScreen extends StatefulWidget {
  final String userEmail;
  final String userPhone;
  final String? userName;
  final String? userId;

  const BusPassScreen({
    Key? key,
    required this.userEmail,
    required this.userPhone,
    this.userName,
    this.userId,
  }) : super(key: key);

  @override
  _BusPassScreenState createState() => _BusPassScreenState();
}

class _BusPassScreenState extends State<BusPassScreen> {
  String? selectedPassType;
  double selectedPassPrice = 0.0;
  String selectedPassDuration = '';

  @override
  void initState() {
    super.initState();
    // 👇 Print the userId in console when screen loads
    print("Logged-in User ID: ${widget.userId}");
    
    // 🔍 Debug: Check if userId is null
    if (widget.userId == null || widget.userId!.isEmpty) {
      print("⚠️ WARNING: userId is null or empty!");
      print("📧 userEmail: ${widget.userEmail}");
      print("📱 userPhone: ${widget.userPhone}");
      print("👤 userName: ${widget.userName}");
      
      // Show warning to user
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar(
          'Warning',
          'User ID is missing. Please login again.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      });
    }
  }

  final List<Map<String, dynamic>> busPassOptions = [
    {
      'type': 'PMC Pass',
      'price': 40.0,
      'duration': 'Daily',
      'description': 'Valid for PMC city buses for 1 day',
      'color': Colors.blue,
      'icon': Icons.directions_bus,
    },
    {
      'type': 'PCMC Pass',
      'price': 60.0,
      'duration': 'Daily',
      'description': 'Valid for PCMC city buses for 1 day',
      'color': Colors.green,
      'icon': Icons.directions_bus,
    },
    {
      'type': 'Student Monthly Pass',
      'price': 1300.0,
      'duration': 'Monthly',
      'description': 'Valid for students for 30 days',
      'color': Colors.orange,
      'icon': Icons.school,
    },
    {
      'type': 'General Monthly Pass',
      'price': 1200.0,
      'duration': 'Monthly',
      'description': 'Valid for all buses for 30 days',
      'color': Colors.purple,
      'icon': Icons.card_membership,
    },
    {
      'type': 'Senior Citizen Pass',
      'price': 800.0,
      'duration': 'Monthly',
      'description': 'Special pass for senior citizens (60+)',
      'color': Colors.teal,
      'icon': Icons.elderly,
    },
    {
      'type': 'Women Special Pass',
      'price': 1000.0,
      'duration': 'Monthly',
      'description': 'Special pass for women with safety features',
      'color': Colors.pink,
      'icon': Icons.woman,
    },
  ];

  void _selectPass(Map<String, dynamic> passData) {
    setState(() {
      selectedPassType = passData['type'];
      selectedPassPrice = passData['price'];
      selectedPassDuration = passData['duration'];
    });
  }

  String _calculateValidTill(DateTime from) {
    if (selectedPassDuration == 'Daily') {
      return from.add(Duration(days: 1)).toIso8601String();
    } else {
      return from.add(Duration(days: 30)).toIso8601String();
    }
  }

  void _bookPass() {
    if (selectedPassType == null) {
      Get.snackbar(
        'Error',
        'Please select a bus pass to continue',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    // 🔍 Check userId before proceeding
    if (widget.userId == null || widget.userId!.isEmpty) {
      Get.snackbar(
        'Error',
        'User ID is missing. Please login again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    DateTime bookingTime = DateTime.now();
    Map<String, dynamic> passData = {
      'passType': selectedPassType,
      'price': selectedPassPrice,
      'duration': selectedPassDuration,
      'userEmail': widget.userEmail,
      'userPhone': widget.userPhone,
      'userName': widget.userName ?? 'User',
      'userId': widget.userId!, // Use ! since we've already checked for null
      'bookingDate': bookingTime.toIso8601String(),
      'bookingTime': bookingTime.toIso8601String(),
      'validFrom': bookingTime.toIso8601String(),
      'validTill': _calculateValidTill(bookingTime),
    };

    // 🔍 Debug: Print passData before navigation
    print('\n=== BOOKING PASS DEBUG ===');
    print('🎫 Pass Type: ${passData['passType']}');
    print('💰 Price: ${passData['price']}');
    print('⏰ Duration: ${passData['duration']}');
    print('🆔 User ID: ${passData['userId']}');
    print('👤 User Name: ${passData['userName']}');
    print('📱 User Phone: ${passData['userPhone']}');
    print('📧 User Email: ${passData['userEmail']}');
    print('📄 Complete Pass Data: $passData');
    print('==========================\n');

    Get.to(() => PhonePePassScreen(passData: passData));
  }

  Widget _buildPassCard(Map<String, dynamic> passData) {
    bool isSelected = selectedPassType == passData['type'];
    
    return GestureDetector(
      onTap: () => _selectPass(passData),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? passData['color'].withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? passData['color'] : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                ? passData['color'].withOpacity(0.3) 
                : Colors.grey.withOpacity(0.2),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: passData['color'].withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  passData['icon'],
                  color: passData['color'],
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              
              // Pass details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passData['type'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? passData['color'] : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      passData['description'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8, 
                            vertical: 4
                          ),
                          decoration: BoxDecoration(
                            color: passData['color'].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            passData['duration'],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: passData['color'],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${passData['price'].toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? passData['color'] : Colors.black87,
                    ),
                  ),
                  if (isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: passData['color'],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          automaticallyImplyLeading: false,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.pink],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: AppBar(
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text(
                'Bus Pass',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Get.back(),
              ),
            ),
          ),
        ),
      ),
      body: GradientBackground(
        child: Column(
          children: [
            // Header section
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(
                    Icons.card_membership,
                    size: 60,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Choose Your Bus Pass',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Select the pass that suits your travel needs',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  // 🔍 Debug: Show userId status
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (widget.userId != null && widget.userId!.isNotEmpty) 
                        ? Colors.green.withOpacity(0.3)
                        : Colors.red.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      (widget.userId != null && widget.userId!.isNotEmpty) 
                        ? 'User ID: ${widget.userId}'
                        : 'User ID: Missing',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Pass options
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Available Passes',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      Expanded(
                        child: ListView.builder(
                          itemCount: busPassOptions.length,
                          itemBuilder: (context, index) {
                            return _buildPassCard(busPassOptions[index]);
                          },
                        ),
                      ),
                      
                      // Selected pass summary
                      if (selectedPassType != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Selected: $selectedPassType',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Total Amount: ₹${selectedPassPrice.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      
                      // Book Pass Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: selectedPassType != null ? _bookPass : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedPassType != null 
                              ? Colors.green 
                              : Colors.grey.shade400,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: selectedPassType != null ? 4 : 0,
                          ),
                          child: Text(
                            selectedPassType != null 
                              ? 'Book Pass - ₹${selectedPassPrice.toStringAsFixed(0)}'
                              : 'Select a Pass to Continue',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}