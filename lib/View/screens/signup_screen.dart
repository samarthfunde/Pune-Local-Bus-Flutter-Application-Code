


import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer';

import 'package:pmpml_app/constant/constant_ui.dart';
import '../../Controller/otpScreen.dart';
import '../../Controller/phoneAuth.dart';
import 'package:pmpml_app/config/api_config.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final adharController = TextEditingController();

  bool isLoading = false;

  // Generate static OTP based on phone number
  String generateStaticOTP(String phoneNumber) {
    String digits = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 6) {
      return digits.substring(digits.length - 6);
    } else {
      return digits.padLeft(6, '0');
    }
  }

  Future<void> signupUser() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        phoneController.text.isEmpty ||
        passwordController.text.isEmpty ||
        adharController.text.isEmpty) {
      Get.snackbar(
        "error".tr,
        "fill_all_fields".tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        borderRadius: 10,
        margin: const EdgeInsets.all(10),
      );
      return;
    }

    // Validate Adhar number (should be exactly 4 digits)
    if (adharController.text.trim().length != 4 || 
        !RegExp(r'^\d{4}$').hasMatch(adharController.text.trim())) {
      Get.snackbar(
        "error".tr,
        "invalid_adhar".tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        borderRadius: 10,
        margin: const EdgeInsets.all(10),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/users/register',
    );


    final body = jsonEncode({
      "name": nameController.text.trim(),
      "email": emailController.text.trim(),
      "phone": phoneController.text.trim(),
      "password": passwordController.text,
      "adharNumber": adharController.text.trim(),
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        // Log the registered user data
        log('=== USER REGISTERED SUCCESSFULLY ===');
        log('User Data: ${responseData['user']}');
        log('====================================');

        Get.snackbar(
          "success".tr,
          responseData['message'] ?? "user_registered".tr,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          borderRadius: 10,
          margin: const EdgeInsets.all(10),
          duration: const Duration(seconds: 3),
        );

        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          // Generate static OTP for the registered phone number
          String staticOTP = generateStaticOTP(phoneController.text.trim());
          
          // Navigate directly to OTP screen after successful registration
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OTPScreen(
                phoneNumber: responseData['user']['phone'],
                staticOTP: staticOTP,
                userData: responseData['user'],
              ),
            ),
          );
        }
      } else {
        final errorData = jsonDecode(response.body);
        Get.snackbar(
          "error".tr,
          errorData['message'] ?? "registration_failed".tr,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          borderRadius: 10,
          margin: const EdgeInsets.all(10),
        );
      }
    } catch (e) {
      log("Error during signup: $e");
      Get.snackbar(
        "error".tr,
        "something_wrong".tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        borderRadius: 10,
        margin: const EdgeInsets.all(10),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    adharController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: GradientBackground(
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      "signup".tr,
                      style: titleTextStyle,
                    ),
                  ),
                  const SizedBox(height: 40),

                  TextField(
                    controller: nameController,
                    decoration: inputDecorationStyle.copyWith(
                      hintText: "name".tr,
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: inputDecorationStyle.copyWith(
                      hintText: "email".tr,
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: inputDecorationStyle.copyWith(
                      hintText: "phone".tr,
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: inputDecorationStyle.copyWith(
                      hintText: "password".tr,
                    ),
                  ),
                  const SizedBox(height: 30),

                  TextField(
                    controller: adharController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: false,
                    decoration: inputDecorationStyle.copyWith(
                      hintText: "adhar_hint".tr,
                      counterText: "",
                      helperText: "adhar_helper".tr,
                      helperStyle: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: signupUser,
                            style: primaryButtonStyle,
                            child: Center(child: Text("signup".tr)),
                          ),
                        ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "already_account".tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        child: Text(
                          "login".tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 19,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}