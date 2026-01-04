import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:pmpml_app/config/api_config.dart';


import 'ticket_screen.dart';

class PhonePeScreen extends StatefulWidget {
  final Map<String, dynamic> ticketData;

  const PhonePeScreen({Key? key, required this.ticketData}) : super(key: key);

  @override
  _PhonePeScreenState createState() => _PhonePeScreenState();
}

class _PhonePeScreenState extends State<PhonePeScreen> {
  String enteredPin = '';
  final String correctPin = '1234';
  bool isProcessing = false;

  // Your specific API URL
static const String apiUrl =
    '${ApiConfig.baseUrl}/api/tickets/create';

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

  // Helper function to safely extract string values
  String _safeString(dynamic value, [String defaultValue = '']) {
    if (value == null) return defaultValue;
    return value.toString();
  }

  // Helper function to safely extract numeric values
  double _safeDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  // Helper function to safely extract integer values
  int _safeInt(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  Future<void> _processPayment() async {
    setState(() {
      isProcessing = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    if (enteredPin == correctPin) {
      // Generate payment ID
      String paymentId = 'PP${DateTime.now().millisecondsSinceEpoch}';
      
      // Safely extract values from ticketData
      String fromPlace = '';
      String toPlace = '';
      
      // Handle nested objects for place names
      if (widget.ticketData['fromPlace'] is Map) {
        fromPlace = _safeString(widget.ticketData['fromPlace']['name'], 'Unknown');
      } else {
        fromPlace = _safeString(widget.ticketData['fromPlace'], 'Unknown');
      }
      
      if (widget.ticketData['toPlace'] is Map) {
        toPlace = _safeString(widget.ticketData['toPlace']['name'], 'Unknown');
      } else {
        toPlace = _safeString(widget.ticketData['toPlace'], 'Unknown');
      }
      
      // Prepare ticket data for backend according to your API format
      Map<String, dynamic> ticketPayload = {
        'userId': _safeString(widget.ticketData['userId'], "665f6c9f1a2b5b3fd4860a12"),
        'fromPlace': fromPlace,
        'toPlace': toPlace,
        'totalDistance': _safeDouble(widget.ticketData['totalDistance']),
        'totalFare': _safeInt(widget.ticketData['totalFare']),
        'paymentId': paymentId,
        'paymentMethod': 'PhonePe',
      };

      try {
        print('Sending API request to: $apiUrl');
        print('Request payload: ${jsonEncode(ticketPayload)}');

        // Call your specific API
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(ticketPayload),
        ).timeout(const Duration(seconds: 30));

        print('API Response Status: ${response.statusCode}');
        print('API Response Body: ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          Map<String, dynamic> responseData = jsonDecode(response.body);
          
          if (responseData['success'] == true) {
            Map<String, dynamic> createdTicket = responseData['ticket'];
            
            Get.snackbar(
              'Payment Successful',
              'Your ticket has been booked successfully!',
              backgroundColor: Colors.green,
              colorText: Colors.white,
              duration: const Duration(seconds: 3),
            );

            // Create properly structured ticket data with safe type conversion
            Map<String, dynamic> finalTicketData = {
              'ticketId': _safeString(createdTicket['ticketId']),
              'fromPlace': {
                'name': _safeString(createdTicket['from'])
              },
              'toPlace': {
                'name': _safeString(createdTicket['to'])
              },
              'totalDistance': _safeDouble(createdTicket['distance']),
              'totalFare': _safeDouble(createdTicket['fare']),
              'paymentId': _safeString(createdTicket['paymentId']),
              'paymentMethod': _safeString(createdTicket['paymentMethod']),
              'status': _safeString(createdTicket['status']),
              'bookingDate': _safeString(createdTicket['bookingDate']),
              'validUntil': _safeString(createdTicket['validUntil']),
              'userId': _safeString(widget.ticketData['userId'], "665f6c9f1a2b5b3fd4860a12"),
            };

            // Reset processing state before navigation
            setState(() {
              isProcessing = false;
            });

            // Navigate to ticket screen
            Get.off(() => TicketScreen(ticketData: finalTicketData));
          } else {
            _showError('Failed to create ticket: ${responseData['message'] ?? 'Unknown error'}');
          }
        } else {
          try {
            Map<String, dynamic> errorData = jsonDecode(response.body);
            _showError('Booking failed: ${errorData['message'] ?? 'Server error'}');
          } catch (e) {
            _showError('Booking failed: HTTP ${response.statusCode}');
          }
        }
      } on SocketException catch (e) {
        print('Socket Exception: $e');
        _showError('Network error: Cannot connect to server.\n'
            'Please check if the server is running at $apiUrl');
      } on HttpException catch (e) {
        print('HTTP Exception: $e');
        _showError('HTTP error: ${e.message}');
      } on FormatException catch (e) {
        print('Format Exception: $e');
        _showError('Invalid response format from server.');
      } on TimeoutException catch (e) {
        print('Timeout Exception: $e');
        _showError('Request timeout. Please try again.');
      } catch (e) {
        print('General Error: $e');
        _showError('Unexpected error: ${e.toString()}');
      }
    } else {
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

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 6),
    );
    setState(() {
      enteredPin = '';
      isProcessing = false;
    });
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
                        'Pay ₹${_safeDouble(widget.ticketData['totalFare']).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'To: PMPML Bus Ticket',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
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
                      const CircularProgressIndicator(color: Colors.purple)
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