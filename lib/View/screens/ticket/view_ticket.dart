import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:pmpml_app/config/api_config.dart';


import 'ticket_screen.dart';

class ViewTicketScreen extends StatefulWidget {
  final String userId;
  
  const ViewTicketScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _ViewTicketScreenState createState() => _ViewTicketScreenState();
}

class _ViewTicketScreenState extends State<ViewTicketScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> activeTickets = [];
  List<Map<String, dynamic>> expiredTickets = [];
  bool isLoading = true;
  String errorMessage = '';

  // API Configuration
  String get activeTicketsUrl =>
    '${ApiConfig.baseUrl}/api/tickets/user/${widget.userId}/active';

  String get allTicketsUrl =>
    '${ApiConfig.baseUrl}/api/tickets/user/${widget.userId}';
    
    


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchUserTickets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  Future<void> _fetchUserTickets() async {
    print('Starting _fetchUserTickets for userId: ${widget.userId}');
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Fetch active tickets
      await _fetchActiveTickets();
      
      // Fetch all tickets to get expired ones
      await _fetchAllTickets();
      
      print('Final results - Active tickets: ${activeTickets.length}, Expired tickets: ${expiredTickets.length}');
      
      setState(() {
        isLoading = false;
      });
      
    } catch (e) {
      print('General Error in _fetchUserTickets: $e');
      setState(() {
        errorMessage = 'Unexpected error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> _fetchActiveTickets() async {
    try {
      print('Fetching active tickets from: $activeTicketsUrl');
      
      final response = await http.get(
        Uri.parse(activeTicketsUrl),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      print('Active Tickets API Response Status: ${response.statusCode}');
      print('Active Tickets API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = jsonDecode(response.body);
        print('Parsed response data: $responseData');
        
        if (responseData['success'] == true) {
          List<dynamic> tickets = responseData['tickets'] ?? [];
          print('Number of tickets received: ${tickets.length}');
          
          // Clear existing active tickets
          activeTickets.clear();
          
          // Process active tickets
          for (var ticket in tickets) {
            print('Processing ticket: $ticket');
            Map<String, dynamic> processedTicket = _processActiveTicketData(ticket);
            print('Processed ticket: $processedTicket');
            activeTickets.add(processedTicket);
          }
          
          print('Active tickets after processing: ${activeTickets.length}');
          
        } else {
          throw Exception('Failed to fetch active tickets: ${responseData['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Server error for active tickets: HTTP ${response.statusCode}');
      }
    } on SocketException catch (e) {
      print('Socket Exception in _fetchActiveTickets: $e');
      throw Exception('Network error: Cannot connect to server.\nPlease check if the server is running.');
    } on TimeoutException catch (e) {
      print('Timeout Exception in _fetchActiveTickets: $e');
      throw Exception('Request timeout. Please try again.');
    } catch (e) {
      print('Unexpected error in _fetchActiveTickets: $e');
      throw e;
    }
  }

  Future<void> _fetchAllTickets() async {
    try {
      print('Fetching all tickets from: $allTicketsUrl');
      
      final response = await http.get(
        Uri.parse(allTicketsUrl),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      print('All Tickets API Response Status: ${response.statusCode}');
      print('All Tickets API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true) {
          List<dynamic> tickets = responseData['tickets'] ?? [];
          
          // Clear existing expired tickets
          expiredTickets.clear();
          
          // Process and categorize tickets to find expired ones
          for (var ticket in tickets) {
            Map<String, dynamic> processedTicket = _processTicketData(ticket);
            
            // Check if ticket is expired
            bool isExpired = _isTicketExpired(processedTicket);
            
            if (isExpired) {
              expiredTickets.add(processedTicket);
            }
          }
          
        } else {
          // If all tickets API fails, it's not critical since we have active tickets
          print('Failed to fetch all tickets: ${responseData['message'] ?? 'Unknown error'}');
        }
      } else {
        // If all tickets API fails, it's not critical since we have active tickets
        print('Server error for all tickets: HTTP ${response.statusCode}');
      }
    } on SocketException catch (e) {
      print('Socket Exception in _fetchAllTickets: $e');
      // Not critical, we can still show active tickets
    } on TimeoutException catch (e) {
      print('Timeout Exception in _fetchAllTickets: $e');
      // Not critical, we can still show active tickets
    } catch (e) {
      print('Error in _fetchAllTickets: $e');
      // Not critical, we can still show active tickets
    }
  }

  Map<String, dynamic> _processActiveTicketData(Map<String, dynamic> ticket) {
    print('Processing active ticket data: $ticket');
    
    var processedTicket = {
      'ticketId': _safeString(ticket['ticketId']),
      'fromPlace': {
        'name': _safeString(ticket['from'])
      },
      'toPlace': {
        'name': _safeString(ticket['to'])
      },
      'totalDistance': _safeDouble(ticket['distance']),
      'totalFare': _safeDouble(ticket['fare']),
      'paymentId': _safeString(ticket['paymentId']),
      'paymentMethod': _safeString(ticket['paymentMethod']),
      'status': _safeString(ticket['status']),
      'bookingDate': _safeString(ticket['bookingDate']),
      'validUntil': _safeString(ticket['validUntil']),
      'remainingTime': _safeInt(ticket['remainingTime']),
      'userId': widget.userId,
    };
    
    print('Processed active ticket: $processedTicket');
    return processedTicket;
  }

  Map<String, dynamic> _processTicketData(Map<String, dynamic> ticket) {
    return {
      'ticketId': _safeString(ticket['ticketId']),
      'fromPlace': {
        'name': _safeString(ticket['from'])
      },
      'toPlace': {
        'name': _safeString(ticket['to'])
      },
      'totalDistance': _safeDouble(ticket['distance']),
      'totalFare': _safeDouble(ticket['fare']),
      'paymentId': _safeString(ticket['paymentId']),
      'paymentMethod': _safeString(ticket['paymentMethod']),
      'status': _safeString(ticket['status']),
      'bookingDate': _safeString(ticket['bookingDate']),
      'validUntil': _safeString(ticket['validUntil']),
      'userId': widget.userId,
    };
  }

  bool _isTicketExpired(Map<String, dynamic> ticket) {
    try {
      String status = _safeString(ticket['status']).toLowerCase();
      if (status == 'expired') return true;
      
      String validUntilStr = _safeString(ticket['validUntil']);
      if (validUntilStr.isEmpty) return false;
      
      DateTime validUntil = DateTime.parse(validUntilStr);
      return DateTime.now().isAfter(validUntil);
    } catch (e) {
      print('Error checking ticket expiry: $e');
      return false;
    }
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'N/A';
    try {
      final DateTime date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  String _formatRemainingTime(int remainingMinutes) {
    if (remainingMinutes <= 0) return 'Expired';
    
    if (remainingMinutes < 60) {
      return '$remainingMinutes min remaining';
    } else {
      int hours = remainingMinutes ~/ 60;
      int minutes = remainingMinutes % 60;
      return '${hours}h ${minutes}m remaining';
    }
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket, bool isExpired) {
    print('Building ticket card for: ${ticket['ticketId']}');
    int remainingTime = _safeInt(ticket['remainingTime']);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigate to full ticket view
          Get.to(() => TicketScreen(ticketData: ticket));
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: isExpired 
                ? [Colors.red.shade50, Colors.red.shade100]
                : [Colors.green.shade50, Colors.green.shade100],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Ticket ID: ${_safeString(ticket['ticketId'])}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isExpired ? Colors.red : Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isExpired ? 'EXPIRED' : 'ACTIVE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'From: ${_getPlaceName(ticket['fromPlace'])}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'To: ${_getPlaceName(ticket['toPlace'])}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${_safeDouble(ticket['totalFare']).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${_safeDouble(ticket['totalDistance']).toStringAsFixed(1)} km',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Booked: ${_formatDate(_safeString(ticket['bookingDate']))}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    _safeString(ticket['paymentMethod']),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              if (!isExpired) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Valid until: ${_formatDate(_safeString(ticket['validUntil']))}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                    ),
                    if (remainingTime > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: remainingTime <= 5 ? Colors.orange : Colors.blue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatRemainingTime(remainingTime),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getPlaceName(dynamic place) {
    if (place == null) return 'N/A';
    if (place is Map<String, dynamic>) {
      return _safeString(place['name'], 'N/A');
    }
    return _safeString(place, 'N/A');
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Debug info
          Text(
            'Debug: Active tickets count: ${activeTickets.length}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketList(List<Map<String, dynamic>> tickets, bool isExpired) {
    print('Building ticket list - isExpired: $isExpired, tickets count: ${tickets.length}');
    
    if (tickets.isEmpty) {
      return _buildEmptyState(
        isExpired 
          ? 'No expired tickets found'
          : 'No active tickets found',
        isExpired ? Icons.history : Icons.receipt_long,
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchUserTickets,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: tickets.length,
        itemBuilder: (context, index) {
          print('Building item at index $index');
          return _buildTicketCard(tickets[index], isExpired);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('Building ViewTicketScreen - isLoading: $isLoading, activeTickets: ${activeTickets.length}, expiredTickets: ${expiredTickets.length}');
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'My Tickets',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchUserTickets,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long, size: 18),
                  const SizedBox(width: 8),
                  Text('Active (${activeTickets.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, size: 18),
                  const SizedBox(width: 8),
                  Text('History (${expiredTickets.length})'),
                ],
              ),
            ),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading your tickets...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 80,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          errorMessage,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.red[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _fetchUserTickets,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTicketList(activeTickets, false),
                    _buildTicketList(expiredTickets, true),
                  ],
                ),
    );
  }
}