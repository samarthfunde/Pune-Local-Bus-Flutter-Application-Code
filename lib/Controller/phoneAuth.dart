import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:pmpml_app/Controller/otpScreen.dart';
import 'package:pmpml_app/constant/constant_ui.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pmpml_app/config/api_config.dart';



class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final phoneController = TextEditingController();
  PhoneNumber number = PhoneNumber(isoCode: 'IN');
  bool isLoading = false;

  // Generate static OTP based on phone number
  String generateStaticOTP(String phoneNumber) {
    // Remove all non-digits from phone number
    String digits = phoneNumber.replaceAll(RegExp(r'\D'), '');
    
    // Take last 6 digits as OTP, if less than 6 digits, pad with zeros
    if (digits.length >= 6) {
      return digits.substring(digits.length - 6);
    } else {
      return digits.padLeft(6, '0');
    }
  }

  Future<void> validatePhoneAndLogin() async {
    String phoneNumber = number.phoneNumber ?? '';
    
    // Basic phone number validation
    if (phoneNumber.length < 10) {
      Get.snackbar(
        "invalid_number".tr,
        "enter_valid_number".tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Call backend to validate phone number
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/api/users/phone-login',
        );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phoneNumber}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        // User found, generate static OTP
        String staticOTP = generateStaticOTP(phoneNumber);
        
        // Safely extract user data with null checks
        Map<String, dynamic> userData = {};
        if (responseData['user'] != null && responseData['user'] is Map<String, dynamic>) {
          userData = responseData['user'];
        } else {
          // If user data is not available, create a minimal user object
          userData = {
            '_id': '',
            'name': '',
            'email': '',
            'phone': phoneNumber,
            'adharNumber': '',
            'isVerified': false,
            'createdAt': '',
          };
        }
        
        Get.snackbar(
          "success".tr,
          "otp_sent".tr,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Navigate to OTP screen with user data and static OTP
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPScreen(
              phoneNumber: phoneNumber,
              staticOTP: staticOTP,
              userData: userData,
            ),
          ),
        );
      } else {
        // User not found
        Get.snackbar(
          "error".tr,
          responseData['message'] ?? 'Phone number not registered',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      log('Login error: $e');
      Get.snackbar(
        "error".tr,
        "Something went wrong. Please try again.",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "phone_authentication".tr,
                  style: titleTextStyle,
                ),
                const SizedBox(height: 40),

                // Phone number input
                InternationalPhoneNumberInput(
                  onInputChanged: (PhoneNumber phone) {
                    setState(() {
                      number = phone;
                    });
                  },
                  selectorConfig: const SelectorConfig(
                    selectorType: PhoneInputSelectorType.DROPDOWN,
                    setSelectorButtonAsPrefixIcon: true,
                  ),
                  initialValue: number,
                  textFieldController: phoneController,
                  inputDecoration: inputDecorationStyle.copyWith(
                    hintText: "enter_phone".tr,
                  ),
                ),
                const SizedBox(height: 20),

                // Sign-in button
                isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: validatePhoneAndLogin,
                        style: primaryButtonStyle,
                        child: Text("sign_in".tr),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}