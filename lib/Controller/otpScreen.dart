import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pmpml_app/constant/constant_ui.dart';
import '../../View/screens/home_screen.dart';

class OTPScreen extends StatefulWidget {
  const OTPScreen({
    super.key, 
    required this.phoneNumber,
    required this.staticOTP,
    required this.userData,
  });
  
  final String phoneNumber;
  final String staticOTP;
  final Map<String, dynamic> userData;

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final otpController = TextEditingController();
  bool isLoading = false;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    // Display the static OTP for demonstration purposes
    log('Generated Static OTP for ${widget.phoneNumber}: ${widget.staticOTP}');
    
    // Show the OTP in a snackbar for demo purposes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.snackbar(
        "Your OTP",
        "Your OTP is: ${widget.staticOTP}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.pinkAccent,
        colorText: Colors.white,
        duration: const Duration(seconds: 10),
      );
    });
  }

  // Helper method to safely get string value from userData
  String _getStringValue(String key, [String defaultValue = '']) {
    try {
      return widget.userData[key]?.toString() ?? defaultValue;
    } catch (e) {
      log('Error getting value for key $key: $e');
      return defaultValue;
    }
  }

  Future<void> verifyOTP() async {
    String enteredOTP = otpController.text.trim();
    
    if (enteredOTP.isEmpty) {
      setState(() {
        errorMessage = "Please enter OTP";
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    try {
      // Verify the entered OTP with static OTP
      if (enteredOTP == widget.staticOTP) {
        // OTP verified successfully
        
        // Print user data in debug console with null safety
        log('=== USER LOGIN SUCCESS ===');
        log('User ID: ${_getStringValue('_id')}');
        log('Name: ${_getStringValue('name')}');
        log('Email: ${_getStringValue('email')}');
        log('Phone: ${_getStringValue('phone')}');
        log('Adhar Number: ${_getStringValue('adharNumber')}');
        log('Is Verified: ${_getStringValue('isVerified')}');
        log('Created At: ${_getStringValue('createdAt')}');
        log('========================');

        Get.snackbar(
          "success".tr,
          "OTP verified successfully!",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          borderRadius: 10,
          margin: const EdgeInsets.all(10),
          duration: const Duration(seconds: 3),
        );

        // Navigate to HomeScreen with user data using safe string extraction
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              userName: _getStringValue('name'),
              userEmail: _getStringValue('email'),
              userPhone: _getStringValue('phone'),
              userId: _getStringValue('_id'),
              adharNumber: _getStringValue('adharNumber'),
            ),
          ),
        );
      } else {
        // Invalid OTP
        setState(() {
          errorMessage = "Invalid OTP. Please try again.";
        });

        Get.snackbar(
          "error".tr,
          "Invalid OTP. Please check and try again.",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          borderRadius: 10,
          margin: const EdgeInsets.all(10),
          duration: const Duration(seconds: 3),
          icon: const Icon(Icons.error, color: Colors.white),
        );
      }
    } catch (e) {
      log('OTP verification error: $e');
      setState(() {
        errorMessage = "Something went wrong. Please try again.";
      });

      Get.snackbar(
        "error".tr,
        "Something went wrong. Please try again.",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        borderRadius: 10,
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.error, color: Colors.white),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Enter OTP sent to ${widget.phoneNumber}",
                textAlign: TextAlign.center,
                style: titleTextStyle,
              ),
              const SizedBox(height: 20),
              
              // Display static OTP for demo purposes
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Your OTP",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.staticOTP,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // OTP Input Field
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: const TextStyle(
                  fontSize: 20,
                  letterSpacing: 3,
                  color: Colors.white,
                ),
                decoration: inputDecorationStyle.copyWith(
                  hintText: "enter_otp".tr,
                  counterText: "", // Hide character counter
                ),
              ),
              const SizedBox(height: 20),

              // Error Message Display
              if (errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Text(
                    errorMessage,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 20),

              // Verify Button
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: verifyOTP,
                      style: primaryButtonStyle,
                      child: Text("verify".tr),
                    ),
              const SizedBox(height: 20),
              
              // Back button
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  "Back to Login",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}