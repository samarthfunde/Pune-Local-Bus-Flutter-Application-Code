import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pmpml_app/config/api_config.dart';


class ViewPassScreen extends StatefulWidget {
  final String userId;
  final String? userName;
  final String? userPhone;

  const ViewPassScreen({
    Key? key,
    required this.userId,
    this.userName,
    this.userPhone,
  }) : super(key: key);

  @override
  _ViewPassScreenState createState() => _ViewPassScreenState();
}

class _ViewPassScreenState extends State<ViewPassScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<Map<String, dynamic>> _activePasses = [];
  List<Map<String, dynamic>> _expiredPasses = [];
  
  bool _isLoadingActive = false;
  bool _isLoadingExpired = false;
  
  String _activeError = '';
  String _expiredError = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Debug print to check userId
    print('=== ViewPassScreen Debug Info ===');
    print('Received userId: "${widget.userId}"');
    print('UserId type: ${widget.userId.runtimeType}');
    print('UserId length: ${widget.userId.length}');
    print('================================');
    
    // Fetch data when screen loads
    _fetchActivePasses();
    _fetchExpiredPasses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Enhanced fetch active passes with better error handling
  Future<void> _fetchActivePasses() async {
    print('=== Fetching Active Passes ===');
    print('Starting to fetch active passes for userId: "${widget.userId}"');
    
    setState(() {
      _isLoadingActive = true;
      _activeError = '';
    });

    try {
      // Ensure userId is properly encoded
      final encodedUserId = Uri.encodeComponent(widget.userId.trim());
      final url =
        '${ApiConfig.baseUrl}/api/passes/user/$encodedUserId/active';

      
      print('Constructed URL: $url');
      print('Raw userId: "${widget.userId}"');
      print('Encoded userId: "$encodedUserId"');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      print('Response Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body Length: ${response.body.length}');
      print('Full Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        print('Parsed Response Data: $responseData');
        print('Success field: ${responseData['success']}');
        print('Message: ${responseData['message']}');
        print('Passes field exists: ${responseData.containsKey('passes')}');
        
        if (responseData['success'] == true) {
          List<dynamic> passesData = responseData['passes'] ?? [];
          print('Passes data type: ${passesData.runtimeType}');
          print('Number of passes received: ${passesData.length}');
          print('Raw passes data: $passesData');
          
          if (passesData.isNotEmpty) {
            print('First pass structure: ${passesData[0]}');
            print('First pass keys: ${passesData[0].keys.toList()}');
          }
          
          setState(() {
            _activePasses = passesData.map((pass) {
              // Enhanced type checking and conversion
              Map<String, dynamic> passMap = {};
              if (pass is Map) {
                pass.forEach((key, value) {
                  passMap[key.toString()] = value;
                });
                print('Converted pass: $passMap');
              } else {
                print('WARNING: Pass is not a Map: $pass (${pass.runtimeType})');
              }
              return passMap;
            }).toList();
            _isLoadingActive = false;
          });
          
          print('Final active passes count: ${_activePasses.length}');
          if (_activePasses.isNotEmpty) {
            print('First processed pass: ${_activePasses[0]}');
          }
        } else {
          final errorMessage = responseData['message'] ?? 'Failed to load active passes';
          print('API returned success: false, message: $errorMessage');
          setState(() {
            _activeError = errorMessage;
            _isLoadingActive = false;
          });
        }
      } else {
        final errorMessage = 'HTTP Error ${response.statusCode}: ${response.reasonPhrase}';
        print('HTTP Error: $errorMessage');
        print('Response body: ${response.body}');
        setState(() {
          _activeError = errorMessage;
          _isLoadingActive = false;
        });
      }
    } catch (e, stackTrace) {
      print('Exception occurred while fetching active passes:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _activeError = 'Network error: ${e.toString()}';
        _isLoadingActive = false;
      });
    }
    print('=== End Fetching Active Passes ===');
  }

  // Enhanced fetch expired passes
  Future<void> _fetchExpiredPasses() async {
    print('=== Fetching Expired Passes ===');
    setState(() {
      _isLoadingExpired = true;
      _expiredError = '';
    });

    try {
      final encodedUserId = Uri.encodeComponent(widget.userId.trim());
      final url =
      '${ApiConfig.baseUrl}/api/passes/user/$encodedUserId/expired';
      
      print('Expired passes URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      print('Expired passes response status: ${response.statusCode}');
      print('Expired passes response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true) {
          List<dynamic> passesData = responseData['passes'] ?? [];
          setState(() {
            _expiredPasses = passesData.map((pass) {
              Map<String, dynamic> passMap = {};
              if (pass is Map) {
                pass.forEach((key, value) {
                  passMap[key.toString()] = value;
                });
              }
              return passMap;
            }).toList();
            _isLoadingExpired = false;
          });
          print('Expired passes loaded: ${_expiredPasses.length}');
        } else {
          setState(() {
            _expiredError = responseData['message'] ?? 'Failed to load expired passes';
            _isLoadingExpired = false;
          });
        }
      } else {
        setState(() {
          _expiredError = 'Failed to load expired passes. Status: ${response.statusCode}';
          _isLoadingExpired = false;
        });
      }
    } catch (e) {
      print('Error fetching expired passes: $e');
      setState(() {
        _expiredError = 'Network error: ${e.toString()}';
        _isLoadingExpired = false;
      });
    }
    print('=== End Fetching Expired Passes ===');
  }

  // Refresh data
  Future<void> _refreshData() async {
    print('=== Refreshing All Data ===');
    await Future.wait([
      _fetchActivePasses(),
      _fetchExpiredPasses(),
    ]);
  }

  // Format date - improved to handle different date formats
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    
    try {
      DateTime date;
      if (dateString.contains('T')) {
        // ISO format: 2025-06-08T19:36:58.954Z
        date = DateTime.parse(dateString);
      } else {
        // Simple date format: 2025-06-10
        date = DateTime.parse(dateString);
      }
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      print('Date parsing error: $e for date: $dateString');
      return dateString;
    }
  }

  // Format date with time
  String _formatDateTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    
    try {
      DateTime date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      print('DateTime parsing error: $e for date: $dateString');
      return dateString;
    }
  }

  // Get status color
  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Get pass type color
  Color _getPassTypeColor(String? passType) {
    if (passType == null) return Colors.orange;
    
    switch (passType.toLowerCase()) {
      case 'pmc pass':
        return Colors.blue;
      case 'pcmc pass':
        return Colors.purple;
      default:
        return Colors.orange;
    }
  }

  // Build pass card with enhanced debugging
  Widget _buildPassCard(Map<String, dynamic> pass, bool isActive) {
    print('=== Building Pass Card ===');
    print('Pass data: $pass');
    print('Pass keys: ${pass.keys.toList()}');
    print('Is active: $isActive');
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: isActive 
                ? [Colors.green.shade50, Colors.green.shade100]
                : [Colors.grey.shade50, Colors.grey.shade100],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Pass ID and Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      pass['passId']?.toString() ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(pass['status']?.toString()),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        pass['status']?.toString() ?? 'Unknown',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // User Info
                if (pass['userName'] != null || pass['userPhone'] != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${pass['userName'] ?? ''} - ${pass['userPhone'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),

                // Pass Type and Duration
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getPassTypeColor(pass['passType']?.toString()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        pass['passType']?.toString() ?? 'Unknown',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        pass['duration']?.toString() ?? 'Unknown',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Price and Remaining Time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.currency_rupee, size: 18, color: Colors.green),
                        Text(
                          '${pass['price']?.toString() ?? '0'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    if (isActive && pass['remainingTime'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer, size: 14, color: Colors.orange.shade700),
                            const SizedBox(width: 4),
                            Text(
                              pass['remainingTime'].toString(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Validity Period
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Valid From',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(pass['validFrom']?.toString()),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Valid Till',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(pass['validTill']?.toString()),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Payment Info
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment Method',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                pass['paymentMethod']?.toString() ?? 'N/A',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Payment ID',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                pass['paymentId']?.toString() ?? 'N/A',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Purchase Date: ',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            _formatDateTime(pass['purchaseTime']?.toString()),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build empty state
  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Pull down to refresh',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // Build error state
  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: TextStyle(
              fontSize: 18,
              color: Colors.red.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Build loading state
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading passes...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Passes',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            Text(
              'ID: ${widget.userId.substring(0, 8)}...',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              text: 'Active (${_activePasses.length})',
              icon: const Icon(Icons.check_circle),
            ),
            Tab(
              text: 'History (${_expiredPasses.length})',
              icon: const Icon(Icons.history),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Active Passes Tab
          RefreshIndicator(
            onRefresh: _fetchActivePasses,
            child: _isLoadingActive
                ? _buildLoadingState()
                : _activeError.isNotEmpty
                    ? _buildErrorState(_activeError)
                    : _activePasses.isEmpty
                        ? _buildEmptyState(
                            'No active passes found\nPurchase a pass to see it here',
                            Icons.card_membership,
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _activePasses.length,
                            itemBuilder: (context, index) {
                              return _buildPassCard(_activePasses[index], true);
                            },
                          ),
          ),
          // Expired Passes Tab
          RefreshIndicator(
            onRefresh: _fetchExpiredPasses,
            child: _isLoadingExpired
                ? _buildLoadingState()
                : _expiredError.isNotEmpty
                    ? _buildErrorState(_expiredError)
                    : _expiredPasses.isEmpty
                        ? _buildEmptyState(
                            'No expired passes found\nYour pass history will appear here',
                            Icons.history,
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _expiredPasses.length,
                            itemBuilder: (context, index) {
                              return _buildPassCard(_expiredPasses[index], false);
                            },
                          ),
          ),
        ],
      ),
    );
  }
}