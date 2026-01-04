import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

class TicketScreen extends StatefulWidget {
  final Map<String, dynamic> ticketData;

  const TicketScreen({Key? key, required this.ticketData}) : super(key: key);

  @override
  _TicketScreenState createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  late DateTime _validUntil;
  bool _isExpired = false;
  Duration _remainingTime = Duration.zero;
  late AnimationController _logoAnimationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _calculateValidityTime();
    _startTimer();
    _initLogoAnimation();
  }

  void _initLogoAnimation() {
    _logoAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.3,
      end: 1.5,
    ).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _logoAnimationController.repeat(reverse: true);
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

  void _calculateValidityTime() {
    try {
      String bookingDateStr = _safeString(widget.ticketData['bookingDate']);
      DateTime bookingDate;
      
      if (bookingDateStr.isEmpty) {
        // If no booking date provided, use current time
        bookingDate = DateTime.now();
      } else {
        bookingDate = DateTime.parse(bookingDateStr);
      }
      
      double totalDistance = _safeDouble(widget.ticketData['totalDistance']);
      int validityMinutes = (totalDistance * 4).round();
      
      // Ensure minimum validity of 30 minutes
      if (validityMinutes < 30) {
        validityMinutes = 30;
      }
      
      _validUntil = bookingDate.add(Duration(minutes: validityMinutes));
      DateTime now = DateTime.now();
      
      if (now.isAfter(_validUntil)) {
        _isExpired = true;
        _remainingTime = Duration.zero;
      } else {
        _remainingTime = _validUntil.difference(now);
      }
    } catch (e) {
      print('Error calculating validity time: $e');
      // Fallback: set validity to 1 hour from now
      _validUntil = DateTime.now().add(const Duration(hours: 1));
      _remainingTime = _validUntil.difference(DateTime.now());
      _isExpired = false;
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        DateTime now = DateTime.now();
        if (now.isAfter(_validUntil)) {
          _isExpired = true;
          _remainingTime = Duration.zero;
          timer.cancel();
        } else {
          _remainingTime = _validUntil.difference(now);
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _logoAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Padding(
          padding: EdgeInsets.only(left: 52.0),
          child: Text("Your Ticket",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Colors.blue, Colors.pink]),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isExpired ? Colors.red : Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    _isExpired ? Icons.cancel : Icons.check_circle,
                    color: Colors.white,
                    size: 40,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isExpired ? 'Ticket Expired!' : 'Booking Confirmed!',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Ticket ID: ${_safeString(widget.ticketData['ticketId'], 'N/A')}',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  if (!_isExpired && _remainingTime.inSeconds > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Expires in: ${_formatDuration(_remainingTime)}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: _isExpired
                              ? [Colors.red, Colors.redAccent]
                              : [Colors.blue, Colors.purple]),
                          borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16)),
                        ),
                        child: const Column(
                          children: [
                            Text('PMPML BUS TICKET',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold)),
                            Text('Pune Mahanagar Parivahan Mahamandal Limited',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Column(
                          children: [
                            _buildTicketRow('From', _getPlaceName(widget.ticketData['fromPlace'])),
                            const SizedBox(height: 6),
                            _buildTicketRow('To', _getPlaceName(widget.ticketData['toPlace'])),
                            const SizedBox(height: 6),
                            _buildTicketRow('Distance',
                                '${_safeDouble(widget.ticketData['totalDistance']).toStringAsFixed(1)} km'),
                            const Divider(height: 16),
                            _buildTicketRow('Ticket ID', _safeString(widget.ticketData['ticketId'], 'N/A')),
                            const SizedBox(height: 6),
                            _buildTicketRow('Fare',
                                '₹${_safeDouble(widget.ticketData['totalFare']).toStringAsFixed(2)}'),
                            const SizedBox(height: 6),
                            _buildTicketRow('Payment Method',
                                _safeString(widget.ticketData['paymentMethod'], 'N/A')),
                            const SizedBox(height: 6),
                            _buildTicketRow('Payment ID',
                                _safeString(widget.ticketData['paymentId'], 'N/A')),
                            const SizedBox(height: 6),
                            _buildTicketRow('Booking Date',
                                _formatDate(_safeString(widget.ticketData['bookingDate']))),
                            const SizedBox(height: 6),
                            _buildTicketRow('Valid up to',
                                _formatDate(_validUntil.toIso8601String()),
                                isValidUntil: true),
                            const SizedBox(height: 6),
                            _buildTicketRow('Status',
                                _isExpired
                                    ? 'EXPIRED'
                                    : _safeString(widget.ticketData['status'], 'Confirmed'),
                                isStatus: true),
                            const Divider(height: 16),
                            AnimatedBuilder(
                              animation: _scaleAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _scaleAnimation.value,
                                  child: SizedBox(
                                    height: 120,
                                    width: 120,
                                    child: Opacity(
                                      opacity: _isExpired ? 0.3 : 1.0,
                                      child: Image.asset(
                                        'lib/assets/image/pmpml logo.png',
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.directions_bus,
                                              size: 60,
                                              color: Colors.grey,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _isExpired ? Colors.red[50] : Colors.amber[50],
                border: Border.all(
                    color: _isExpired ? Colors.red : Colors.amber),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isExpired ? 'Expired Ticket:' : 'Important Notes:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: _isExpired ? Colors.red : Colors.black),
                  ),
                  const SizedBox(height: 6),
                  if (_isExpired) ...[
                    const Text('• This ticket has expired and is no longer valid'),
                    const Text('• Please book a new ticket for your journey'),
                    const Text('• Expired tickets cannot be used for travel'),
                  ] else ...[
                    const Text('• This ticket is valid for single journey only'),
                    const Text('• Please show this ticket to the conductor'),
                    const Text('• Keep this ticket until the end of your journey'),
                    const Text('• No refund available for this ticket'),
                    Text('• Ticket expires in ${_formatDuration(_remainingTime)}'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  // Helper function to safely get place names
  String _getPlaceName(dynamic place) {
    if (place == null) return 'N/A';
    if (place is Map<String, dynamic>) {
      return _safeString(place['name'], 'N/A');
    }
    return _safeString(place, 'N/A');
  }

  Widget _buildTicketRow(String label, String value,
      {bool isStatus = false, bool isValidUntil = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isStatus && value == 'EXPIRED'
                  ? Colors.red
                  : isStatus && value == 'Confirmed'
                      ? Colors.green
                      : isValidUntil && _isExpired
                          ? Colors.red
                          : Colors.black87,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'N/A';
    try {
      final DateTime date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      print('Error formatting date: $e');
      return dateString.isNotEmpty ? dateString : 'N/A';
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    } else {
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
  }
}