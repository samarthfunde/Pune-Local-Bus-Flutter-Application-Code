import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

class PassScreen extends StatefulWidget {
  final Map<String, dynamic> passData;

  const PassScreen({Key? key, required this.passData}) : super(key: key);

  @override
  _PassScreenState createState() => _PassScreenState();
}

class _PassScreenState extends State<PassScreen> with TickerProviderStateMixin {
  late Timer _timer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String remainingTime = '';
  bool isExpired = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
    _startTimer();
  }

  void _startTimer() {
    _updateRemainingTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateRemainingTime();
    });
  }

  void _updateRemainingTime() {
    DateTime now = DateTime.now();
    DateTime validTill;

    // Check if it's a day pass (you can modify this condition based on your pass type logic)
    bool isDayPass = widget.passData['passType']?.toLowerCase().contains('day') ?? false ||
                     widget.passData['duration'] == 'day' ||
                     widget.passData['validity'] == '1 day';

    if (isDayPass) {
      // For day pass: valid till 11:59:59 PM of the booking day
      DateTime bookingDate;
      
      // If you have booking time, use it. Otherwise use current date
      if (widget.passData['bookingTime'] != null) {
        bookingDate = DateTime.parse(widget.passData['bookingTime']);
      } else if (widget.passData['validFrom'] != null) {
        bookingDate = DateTime.parse(widget.passData['validFrom']);
      } else {
        // Use current date if no booking time is available
        bookingDate = now;
      }
      
      // Set valid till to 11:59:59 PM of the booking day
      validTill = DateTime(bookingDate.year, bookingDate.month, bookingDate.day, 23, 59, 59);
    } else {
      // For other passes: use the existing logic
      DateTime dateOnly = DateTime.parse(widget.passData['validTill']);
      validTill = DateTime(dateOnly.year, dateOnly.month, dateOnly.day, 23, 59, 59);
    }

    if (now.isAfter(validTill)) {
      setState(() {
        isExpired = true;
        remainingTime = 'EXPIRED';
      });
      _timer.cancel();
    } else {
      Duration difference = validTill.difference(now);
      setState(() {
        remainingTime = _formatDuration(difference);
      });
    }
  }

  String _formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);
    int seconds = duration.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Color _getPassColor() {
    switch (widget.passData['passType']) {
      case 'PMC Pass':
        return Colors.blue;
      case 'PCMC Pass':
        return Colors.green;
      case 'Student Monthly Pass':
        return Colors.orange;
      case 'General Monthly Pass':
        return Colors.purple;
      case 'Senior Citizen Pass':
        return Colors.teal;
      case 'Women Special Pass':
        return Colors.pink;
      case 'Day Pass':
      case 'One Day Pass':
        return Colors.amber;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _getPassIcon() {
    switch (widget.passData['passType']) {
      case 'Student Monthly Pass':
        return Icons.school;
      case 'Senior Citizen Pass':
        return Icons.elderly;
      case 'Women Special Pass':
        return Icons.woman;
      case 'Day Pass':
      case 'One Day Pass':
        return Icons.today;
      default:
        return Icons.directions_bus;
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color passColor = _getPassColor();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: passColor,
        title: const Text(
          'My Bus Pass',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [passColor, passColor.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: passColor.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PMPML',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Bus Pass',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getPassIcon(),
                              size: 30,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Pass Details
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow("Name", widget.passData['userName']),
                          _buildDetailRow("Phone", widget.passData['userPhone']),
                          _buildDetailRow("Pass Type", widget.passData['passType']),
                          _buildDetailRow("Valid Till", _getValidTillText()),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Time Remaining:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              isExpired
                                  ? Row(
                                      children: const [
                                        Icon(Icons.cancel, color: Colors.red, size: 18),
                                        SizedBox(width: 6),
                                        Text(
                                          'Invalid',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      remainingTime,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
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
              const SizedBox(height: 20),
              Text(
                _getPassDescription(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getValidTillText() {
    bool isDayPass = widget.passData['passType']?.toLowerCase().contains('day') ?? false ||
                     widget.passData['duration'] == 'day' ||
                     widget.passData['validity'] == '1 day';

    if (isDayPass) {
      DateTime bookingDate;
      if (widget.passData['bookingTime'] != null) {
        bookingDate = DateTime.parse(widget.passData['bookingTime']);
      } else if (widget.passData['validFrom'] != null) {
        bookingDate = DateTime.parse(widget.passData['validFrom']);
      } else {
        bookingDate = DateTime.now();
      }
      
      return '${bookingDate.day.toString().padLeft(2, '0')}/${bookingDate.month.toString().padLeft(2, '0')}/${bookingDate.year} 11:59 PM';
    } else {
      return widget.passData['validTill'];
    }
  }

  String _getPassDescription() {
    bool isDayPass = widget.passData['passType']?.toLowerCase().contains('day') ?? false ||
                     widget.passData['duration'] == 'day' ||
                     widget.passData['validity'] == '1 day';

    if (isDayPass) {
      return 'This day pass is valid until 11:59 PM today for travel in PMPML buses only.\nShow this screen to conductor.';
    } else {
      return 'This pass is valid for travel in PMPML buses only.\nShow this screen to conductor.';
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}