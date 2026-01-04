import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:pmpml_app/config/api_config.dart';

import 'dart:convert';
import 'pass_ticket.dart';
import 'package:pmpml_app/config/api_config.dart';


class PhonePePassScreen extends StatefulWidget {
  final Map<String, dynamic> passData;

  const PhonePePassScreen({Key? key, required this.passData}) : super(key: key);

  @override
  _PhonePePassScreenState createState() => _PhonePePassScreenState();
}

class _PhonePePassScreenState extends State<PhonePePassScreen> {
  String enteredPin = '';
  final String correctPin = '1234'; // Dummy PIN for simulation
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Debug: Print all pass data when screen loads
    _debugPrintPassData();
  }

  void _debugPrintPassData() {
    print('\n=== PHONEPE PASS SCREEN DEBUG INFO ===');
    print('📱 Screen initialized with pass data:');
    print('🆔 User ID: ${widget.passData['userId']}');
    print('👤 User Name: ${widget.passData['userName']}');
    print('📱 User Phone: ${widget.passData['userPhone']}');
    print('🎫 Pass Type: ${widget.passData['passType']}');
    print('⏰ Duration: ${widget.passData['duration']}');
    print('💰 Price: ₹${widget.passData['price']}');
    print('📄 Full Pass Data: ${widget.passData}');
    print('=====================================\n');
  }

  void _onPinEntered(String digit) {
    if (enteredPin.length < 4) {
      setState(() {
        enteredPin += digit;
      });
      
      if (enteredPin.length == 4) {
        _processPayment();
      }
    }
  }

  void _onPinDeleted() {
    if (enteredPin.isNotEmpty) {
      setState(() {
        enteredPin = enteredPin.substring(0, enteredPin.length - 1);
      });
    }
  }

  Future<void> _processPayment() async {
    setState(() {
      isProcessing = true;
    });

    print('\n=== PAYMENT PROCESSING STARTED ===');
    print('💳 Processing payment with PIN: ${enteredPin.replaceAll(RegExp(r'.'), '*')}');

    // Simulate payment processing delay
    await Future.delayed(const Duration(seconds: 1));

    if (enteredPin == correctPin) {
      try {
        // Generate unique payment ID
        String paymentId = 'PP${DateTime.now().millisecondsSinceEpoch}';
        
        // Prepare API request body with dynamic data
        Map<String, dynamic> requestBody = {
          "userId": widget.passData['userId'],
          "userName": widget.passData['userName'],
          "userPhone": widget.passData['userPhone'],
          "passType": widget.passData['passType'],
          "duration": widget.passData['duration'],
          "price": widget.passData['price'],
          "paymentId": paymentId,
          "paymentMethod": "PhonePe",
          "upiPin": enteredPin,
        };

        print('\n=== API REQUEST DEBUG ===');
print('🌐 API Endpoint: ${ApiConfig.baseUrl}/api/passes/create');
        print('📤 Request Body:');
        print('   👤 User ID: ${requestBody['userId']}');
        print('   🏷️  User Name: ${requestBody['userName']}');
        print('   📱 User Phone: ${requestBody['userPhone']}');
        print('   🎫 Pass Type: ${requestBody['passType']}');
        print('   ⏰ Duration: ${requestBody['duration']}');
        print('   💰 Price: ₹${requestBody['price']}');
        print('   💳 Payment ID: ${requestBody['paymentId']}');
        print('   💸 Payment Method: ${requestBody['paymentMethod']}');
        print('   🔐 UPI PIN: ${requestBody['upiPin'].toString().replaceAll(RegExp(r'.'), '*')}');
        print('📋 Full Request: ${json.encode(requestBody)}');
        print('========================\n');

        // Make API call
        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/api/passes/create'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode(requestBody),
        );

        print('\n=== API RESPONSE DEBUG ===');
        print('📡 Response Status Code: ${response.statusCode}');
        print('📥 Response Body: ${response.body}');
        print('=========================\n');

        if (response.statusCode == 200 || response.statusCode == 201) {
          // Parse response
          Map<String, dynamic> responseData = json.decode(response.body);
          
          print('\n=== PARSED RESPONSE DEBUG ===');
          print('✅ Success: ${responseData['success']}');
          print('💬 Message: ${responseData['message']}');
          if (responseData['passData'] != null) {
            print('🎫 Generated Pass Data:');
            print('   🆔 Pass ID: ${responseData['passData']['passId']}');
            print('   👤 User Name: ${responseData['passData']['userName']}');
            print('   📱 User Phone: ${responseData['passData']['userPhone']}');
            print('   🎫 Pass Type: ${responseData['passData']['passType']}');
            print('   ⏰ Duration: ${responseData['passData']['duration']}');
            print('   💰 Price: ₹${responseData['passData']['price']}');
            print('   📅 Valid From: ${responseData['passData']['validFrom']}');
            print('   📅 Valid Till: ${responseData['passData']['validTill']}');
            print('   ⚡ Status: ${responseData['passData']['status']}');
            print('   💳 Payment ID: ${responseData['passData']['paymentId']}');
          }
          print('============================\n');
          
          if (responseData['success'] == true) {
            // Payment successful
            print('🎉 PAYMENT SUCCESSFUL! Pass created successfully.');
            
            Get.snackbar(
              'Payment Successful',
              'Your bus pass has been purchased successfully!',
              backgroundColor: Colors.green,
              colorText: Colors.white,
              duration: const Duration(seconds: 3),
            );

            // Navigate to pass screen with API response data
            Get.off(() => PassScreen(passData: responseData['passData']));
          } else {
            throw Exception(responseData['message'] ?? 'Payment failed');
          }
        } else {
          throw Exception('Server error: ${response.statusCode}');
        }
      } catch (e) {
        // Handle API errors
        print('\n❌ PAYMENT ERROR OCCURRED:');
        print('🚨 Error: ${e.toString()}');
        print('📱 User ID: ${widget.passData['userId']}');
        print('💔 Failed to create pass for user: ${widget.passData['userName']}');
        print('======================\n');
        
        Get.snackbar(
          'Payment Failed',
          'Unable to process payment. Please try again.\nError: ${e.toString()}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        
        setState(() {
          enteredPin = '';
          isProcessing = false;
        });
      }
    } else {
      // Incorrect PIN
      print('\n❌ INCORRECT PIN ENTERED');
      print('🔐 Expected: ${correctPin.replaceAll(RegExp(r'.'), '*')}');
      print('🔐 Entered: ${enteredPin.replaceAll(RegExp(r'.'), '*')}');
      print('👤 User: ${widget.passData['userName']} (${widget.passData['userId']})');
      print('=======================\n');
      
      Get.snackbar(
        'Payment Failed',
        'Incorrect PIN. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      setState(() {
        enteredPin = '';
        isProcessing = false;
      });
    }
  }

  Widget _buildPinDot(int index) {
    return Container(
      width: 14,
      height: 14,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: enteredPin.length > index ? Colors.purple : Colors.grey[300],
        border: Border.all(color: Colors.purple, width: 1.5),
      ),
    );
  }

  Widget _buildNumberButton(String number) {
    return InkWell(
      onTap: isProcessing ? null : () => _onPinEntered(number),
      child: Container(
        width: 46,
        height: 46,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[300],
          border: Border.all(color: Colors.purple.shade300, width: 1),
        ),
        child: Center(
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return InkWell(
      onTap: isProcessing ? null : _onPinDeleted,
      child: Container(
        width: 46,
        height: 46,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[300],
          border: Border.all(color: Colors.purple.shade300, width: 1),
        ),
        child: const Center(
          child: Icon(Icons.backspace_outlined, size: 20, color: Colors.black87),
        ),
      ),
    );
  }

  Widget _buildNumberRow(List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((n) => _buildNumberButton(n)).toList(),
    );
  }

  Widget _buildLastRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        const SizedBox(width: 46),
        _buildNumberButton('0'),
        _buildDeleteButton(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple,
      appBar: AppBar(
        backgroundColor: Colors.purple,
        title: const Text('PhonePe', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.phone_android, size: 60, color: Colors.white),
                const SizedBox(height: 10),
                const Text(
                  'PhonePe',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Pay ₹${widget.passData['price'].toString()}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'For: ${widget.passData['passType']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Duration: ${widget.passData['duration']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'User: ${widget.passData['userName']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Enter your UPI PIN',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) => _buildPinDot(index)),
                    ),
                    const SizedBox(height: 20),
                    if (isProcessing)
                      Column(
                        children: [
                          const CircularProgressIndicator(color: Colors.purple),
                          const SizedBox(height: 10),
                          Text(
                            'Processing payment for ${widget.passData['userName']}...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildNumberRow(['1', '2', '3']),
                          _buildNumberRow(['4', '5', '6']),
                          _buildNumberRow(['7', '8', '9']),
                          _buildLastRow(),
                        ],
                      ),
                    const SizedBox(height: 10),
                    Text(
                      'Hint: Use PIN 1234 for successful payment',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}