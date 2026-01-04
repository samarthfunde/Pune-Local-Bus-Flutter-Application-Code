import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pmpml_app/constant/constant_ui.dart';
import 'phonepe_screen.dart';
import 'ticket_screen.dart';

class BookTicketScreen extends StatefulWidget {
  final dynamic fromPlace;
  final dynamic toPlace;
  final double baseFare;
  final double discountAmount;
  final double totalFare;
  final double discountPercentage;
  final double totalDistance;
  final String userEmail;
  final String userPhone;
  final bool isWomenBooking;
  final bool isPregnantDiscount;
  final bool isHandicapDiscount;
  final String? userName;        // Made nullable
  final String? userId;          // Made nullable
  final String? userAdharNumber; // Made nullable
  final String? userCreationDate;// Made nullable

  const BookTicketScreen({
    Key? key,
    required this.fromPlace,
    required this.toPlace,
    required this.baseFare,
    required this.discountAmount,
    required this.totalFare,
    required this.discountPercentage,
    required this.totalDistance,
    required this.userEmail,
    required this.userPhone,
    required this.isWomenBooking,
    required this.isPregnantDiscount,
    required this.isHandicapDiscount,
    this.userName,              // Optional parameter
    this.userId,                // Optional parameter
    this.userAdharNumber,       // Optional parameter
    this.userCreationDate,      // Optional parameter
  }) : super(key: key);

  @override
  _BookTicketScreenState createState() => _BookTicketScreenState();
}
class _BookTicketScreenState extends State<BookTicketScreen> {
  late Razorpay _razorpay;
  String selectedPaymentMethod = '';

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void launchRazorPay() {
    int amountToPay = (widget.totalFare * 100).toInt();

    var options = {
      'key': 'rzp_test_pRURPm8n0kvUjR',
      'amount': "$amountToPay",
      'name': 'PMPML Bus Ticket',
      'description': 'From ${widget.fromPlace?['name']} to ${widget.toPlace?['name']}',
      'prefill': {
        'contact': widget.userPhone,
        'email': widget.userEmail,
      },
      'theme': {'color': '#3399cc'},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      Get.snackbar('Error', 'Payment failed to start',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  void navigateToPhonePe() {
    Map<String, dynamic> ticketData = {
      'fromPlace': widget.fromPlace,
      'toPlace': widget.toPlace,
      'baseFare': widget.baseFare,
      'discountAmount': widget.discountAmount,
      'totalFare': widget.totalFare,
      'discountPercentage': widget.discountPercentage,
      'totalDistance': widget.totalDistance,
      'userEmail': widget.userEmail,
      'userPhone': widget.userPhone,
      'ticketId': 'PMPML${DateTime.now().millisecondsSinceEpoch}',
      'bookingDate': DateTime.now().toIso8601String(),
      'isWomenBooking': widget.isWomenBooking,
      'isPregnantDiscount': widget.isPregnantDiscount,
      'isHandicapDiscount': widget.isHandicapDiscount,
      // Add user information to ticket data
      'userName': widget.userName ?? 'User Name',
      'userId': widget.userId ?? 'N/A',
      'userAdharNumber': widget.userAdharNumber,
      'userCreationDate': widget.userCreationDate,
    };

    Get.to(() => PhonePeScreen(ticketData: ticketData));
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    Get.snackbar('Payment Success', 'Ticket booked!',
        backgroundColor: Colors.green, colorText: Colors.white);
    
    _generateTicket(response.paymentId);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Get.snackbar('Payment Failed', 'Please try again',
        backgroundColor: Colors.red, colorText: Colors.white);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Get.snackbar('Wallet Selected', '${response.walletName}',
        backgroundColor: Colors.blue, colorText: Colors.white);
  }

  void _generateTicket(String? paymentId) {
    Map<String, dynamic> ticketData = {
      'ticketId': 'PMPML${DateTime.now().millisecondsSinceEpoch}',
      'fromPlace': widget.fromPlace,
      'toPlace': widget.toPlace,
      'baseFare': widget.baseFare,
      'discountAmount': widget.discountAmount,
      'totalFare': widget.totalFare,
      'discountPercentage': widget.discountPercentage,
      'totalDistance': widget.totalDistance,
      'userEmail': widget.userEmail,
      'userPhone': widget.userPhone,
      'paymentId': paymentId ?? 'N/A',
      'paymentMethod': selectedPaymentMethod == 'razorpay' ? 'Razorpay' : 'PhonePe',
      'bookingDate': DateTime.now().toIso8601String(),
      'status': 'Confirmed',
      'isWomenBooking': widget.isWomenBooking,
      'isPregnantDiscount': widget.isPregnantDiscount,
      'isHandicapDiscount': widget.isHandicapDiscount,
      // Add user information to ticket data
      'userName': widget.userName ?? 'User Name',
      'userId': widget.userId ?? 'N/A',
      'userAdharNumber': widget.userAdharNumber,
      'userCreationDate': widget.userCreationDate,
    };

    Get.off(() => TicketScreen(ticketData: ticketData));
  }

  Widget _buildPaymentOption(String title, IconData icon, Color color, String method) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          method == 'phonepe' ? 'Fast & Secure UPI Payment' : 'Credit/Debit Card, NetBanking',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: Radio<String>(
          value: method,
          groupValue: selectedPaymentMethod,
          activeColor: color,
          onChanged: (value) {
            setState(() => selectedPaymentMethod = value!);
          },
        ),
        onTap: () {
          setState(() => selectedPaymentMethod = method);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(left: 32.0),
          child: Text(
            "Book User Ticket",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.pink],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        elevation: 0,
      ),
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info Card - NEW ADDITION
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [Colors.purple.withOpacity(0.1), Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Passenger Information',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.userName ?? 'User Name',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                if (widget.userId != null)
                                  Text(
                                    'User ID: ${widget.userId}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                Text(
                                  widget.userEmail,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  widget.userPhone,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Journey Details Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [Colors.blue.withOpacity(0.1), Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.directions_bus,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Journey Details',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'From',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            widget.fromPlace?['name'] ?? 'N/A',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          const Text(
                                            'To',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            widget.toPlace?['name'] ?? 'N/A',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                            textAlign: TextAlign.end,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.straighten,
                                        color: Colors.blue,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Distance: ${widget.totalDistance.toStringAsFixed(1)} km',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Fare Details Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [Colors.green.withOpacity(0.1), Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.attach_money,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Fare Details',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  'Single Journey Ticket',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Base Fare:',
                                style: TextStyle(fontSize: 14, color: Colors.black87),
                              ),
                              Text(
                                '₹${widget.baseFare.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 14, color: Colors.black87),
                              ),
                            ],
                          ),
                          if (widget.discountAmount > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Discount (${widget.discountPercentage.toStringAsFixed(0)}%):',
                                  style: const TextStyle(fontSize: 14, color: Colors.red),
                                ),
                                Text(
                                  '-₹${widget.discountAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 14, color: Colors.red),
                                ),
                              ],
                            ),
                          ],
                          const Divider(thickness: 1),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Amount:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                '₹${widget.totalFare.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Center(
                child: Text(
                  'Select Payment Method',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              _buildPaymentOption(
                'PhonePe',
                Icons.phone_android,
                Colors.purple,
                'phonepe',
              ),
              _buildPaymentOption(
                'Razorpay',
                Icons.credit_card,
                Colors.blue,
                'razorpay',
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Terms & Conditions',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Ticket is valid for single journey only\n• Show this ticket to conductor during journey\n• No refund available after booking\n• Keep ticket safe until journey completion',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: selectedPaymentMethod.isEmpty
                      ? LinearGradient(colors: [Colors.grey, Colors.grey])
                      : const LinearGradient(
                          colors: [Colors.red, Colors.redAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  boxShadow: selectedPaymentMethod.isEmpty
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                ),
                child: ElevatedButton.icon(
                  onPressed: selectedPaymentMethod.isEmpty
                      ? null
                      : () {
                          if (selectedPaymentMethod == 'phonepe') {
                            navigateToPhonePe();
                          } else {
                            launchRazorPay();
                          }
                        },
                  icon: const Icon(
                    Icons.payment,
                    color: Colors.white,
                    size: 24,
                  ),
                  label: Text(
                    selectedPaymentMethod.isEmpty
                        ? 'Select Payment Method'
                        : 'Book Ticket',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.security, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Secure payment powered by Razorpay & PhonePe',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
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
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }
}