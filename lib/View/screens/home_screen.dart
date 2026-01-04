import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:pmpml_app/View/screens/tell_us.dart';
import 'package:pmpml_app/View/screens/ticket/view_pass.dart';
import 'package:pmpml_app/View/screens/view_routes.dart';
import 'dart:convert';
import '../../Controller/MapScreen.dart';
import 'package:pmpml_app/constant/constant_ui.dart';
import 'help_screen.dart';
import 'place_suggestion.dart';
import 'scanner_screen.dart';
import 'ticket/book_ticket.dart';
import 'ticket/bus_pass.dart';
import 'ticket/view_ticket.dart';
import 'ui.dart';

class HomeScreen extends StatefulWidget {
  final String userEmail;
  final String userPhone;
  final String? userName;
  final String? userId;        // Added parameter
  final String? adharNumber;

  const HomeScreen({
    Key? key, 
    required this.userEmail, 
    required this.userPhone,
    this.userName,
    this.userId,              // Added parameter
    this.adharNumber,
  }) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _fromPlace;
  Map<String, dynamic>? _toPlace;
  
  // Route information variables
  double _totalDistance = 0.0;
  double _routeFare = 0.0;
  Map<String, dynamic>? _routeData;
  
  bool _bookingForWomen = false;
  bool _pregnantWomenDiscount = false;
  bool _handicapWomenDiscount = false;
  int _currentIndex = 0;
  final RxString _errorMessage = ''.obs;

  // User data from API
  Map<String, dynamic>? _userData;
  bool _isLoadingUserData = false;
  bool _userDataFound = false;

  // Keys to access PlaceSuggestionField methods
  final GlobalKey<PlaceSuggestionFieldState> _fromFieldKey = GlobalKey<PlaceSuggestionFieldState>();
  final GlobalKey<PlaceSuggestionFieldState> _toFieldKey = GlobalKey<PlaceSuggestionFieldState>();

  // GlobalKey for Scaffold to control drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Updated helper methods to prioritize widget parameters over API data
  String _getUserName() {
    // First check widget parameters (from OTP screen)
    if (widget.userName != null && widget.userName!.isNotEmpty) {
      return widget.userName!;
    }
    // Then check API data
    if (_userDataFound && _userData?['name'] != null && _userData!['name'].toString().isNotEmpty) {
      return _userData!['name'].toString();
    }
    return 'User Name';
  }

  String _getUserEmail() {
    // First check widget parameters (from OTP screen)
    if (widget.userEmail.isNotEmpty) {
      return widget.userEmail;
    }
    // Then check API data
    if (_userDataFound && _userData?['email'] != null && _userData!['email'].toString().isNotEmpty) {
      return _userData!['email'].toString();
    }
    return 'No email provided';
  }

  String _getUserPhone() {
    // Widget parameter takes priority
    if (widget.userPhone.isNotEmpty) {
      return widget.userPhone;
    }
    // Then check API data
    if (_userDataFound && _userData?['phone'] != null && _userData!['phone'].toString().isNotEmpty) {
      return _userData!['phone'].toString();
    }
    return 'No phone provided';
  }

  String? _getUserAdharNumber() {
    // First check widget parameters (from OTP screen)
    if (widget.adharNumber != null && widget.adharNumber!.isNotEmpty) {
      return widget.adharNumber!;
    }
    // Then check API data
    if (_userDataFound && _userData?['adharNumber'] != null && _userData!['adharNumber'].toString().isNotEmpty) {
      return _userData!['adharNumber'].toString();
    }
    return null;
  }

  String _getUserId() {
    // First check widget parameters (from OTP screen)
    if (widget.userId != null && widget.userId!.isNotEmpty) {
      return widget.userId!;
    }
    // Then check API data
    if (_userDataFound && _userData?['_id'] != null) {
      return _userData!['_id'].toString();
    }
    return 'N/A';
  }

  bool _getUserVerificationStatus() {
    // Check API data for verification status
    if (_userDataFound && _userData?['isVerified'] != null) {
      return _userData!['isVerified'] as bool;
    }
    // If user data came from OTP verification, they should be considered verified
    if (widget.userId != null && widget.userId!.isNotEmpty) {
      return true;
    }
    return false;
  }

  // Updated method to check if user data is available from widget parameters
  bool _hasUserDataFromLogin() {
    return widget.userName != null && 
           widget.userName!.isNotEmpty && 
           widget.userId != null && 
           widget.userId!.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    print('DEBUG: HomeScreen initialized with:');
    print('  - Phone: ${widget.userPhone}');
    print('  - Email: ${widget.userEmail}');
    print('  - Name: ${widget.userName}');
    print('  - User ID: ${widget.userId}');
    print('  - Adhar: ${widget.adharNumber}');
    
    // Only fetch user data from API if we don't have complete data from login
    if (!_hasUserDataFromLogin()) {
      print('DEBUG: Fetching user data from API...');
      _fetchUserDataByPhone();
    } else {
      print('DEBUG: Using user data from login');
      setState(() {
        _userDataFound = true;
        _isLoadingUserData = false;
      });
    }
  }

  // Updated method to fetch user data by phone number
  Future<void> _fetchUserDataByPhone() async {
    if (widget.userPhone.isEmpty) {
      print('DEBUG: No phone number provided');
      return;
    }
    
    setState(() {
      _isLoadingUserData = true;
      _userDataFound = false;
      _userData = null;
    });

    try {
      // Clean phone number - remove country code if present
      String cleanPhone = widget.userPhone.trim();
      print('DEBUG: Original phone before cleaning: "$cleanPhone"');
      
      // Remove +91 prefix if present
      if (cleanPhone.startsWith('+91')) {
        cleanPhone = cleanPhone.substring(3);
      } else if (cleanPhone.startsWith('91') && cleanPhone.length > 10) {
        cleanPhone = cleanPhone.substring(2);
      }
      
      // Remove any remaining spaces or special characters
      cleanPhone = cleanPhone.replaceAll(RegExp(r'[^\d]'), '');
      
      print('DEBUG: Cleaned phone: "$cleanPhone"');
      
      final url = 'http://.1.102:5000/api/users/phone/$cleanPhone';
      print('DEBUG: Making request to: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('DEBUG: Response status code: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        print('DEBUG: Parsed response data: $responseData');
        
        if (responseData['success'] == true && responseData['user'] != null) {
          setState(() {
            _userData = responseData['user'];
            _userDataFound = true;
            _isLoadingUserData = false;
          });
          
          print('DEBUG: User data set successfully');
          print('DEBUG: User name: ${_userData!['name']}');
          print('DEBUG: User email: ${_userData!['email']}');
          print('DEBUG: User phone: ${_userData!['phone']}');
          
          // Show success message
          Get.snackbar(
            'Success',
            'Account information loaded successfully',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
            borderRadius: 8,
            duration: const Duration(seconds: 2),
          );
        } else {
          print('DEBUG: User not found in response or success is false');
          setState(() {
            _userDataFound = false;
            _isLoadingUserData = false;
          });
        }
      } else if (response.statusCode == 404) {
        print('DEBUG: User not found (404)');
        setState(() {
          _userDataFound = false;
          _isLoadingUserData = false;
        });
      } else {
        print('DEBUG: Failed with status code: ${response.statusCode}');
        throw Exception('Failed to load user data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Error fetching user data: $e');
      setState(() {
        _isLoadingUserData = false;
        _userDataFound = false;
        _userData = null;
      });
      
      // Show error message to user
      Get.snackbar(
        'Error',
        'Failed to load user account information: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
        duration: const Duration(seconds: 3),
      );
    }
  }

  // Helper method to format creation date
  String _getFormattedCreationDate() {
    if (_userDataFound && _userData?['createdAt'] != null) {
      try {
        DateTime createdAt = DateTime.parse(_userData!['createdAt']);
        List<String> months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        return '${months[createdAt.month - 1]} ${createdAt.year}';
      } catch (e) {
        print('Error parsing date: $e');
      }
    }
    return _getCurrentDate();
  }

  // Enhanced method to calculate route information
  void _calculateRouteInfo() {
    if (_fromPlace != null && _toPlace != null) {
      String fromName = _fromPlace!['name'] ?? '';
      String toName = _toPlace!['name'] ?? '';
      
      // Get route info from PlaceSuggestionField
      if (_fromFieldKey.currentState != null) {
        Map<String, dynamic> routeInfo = _fromFieldKey.currentState!.getRouteInfo(fromName, toName);
        
        setState(() {
          _totalDistance = routeInfo['distance'] ?? 0.0;
          _routeFare = routeInfo['fare'] ?? 0.0;
          _routeData = routeInfo['route'];
        });
        
        print('Route calculated: Distance: $_totalDistance km, Fare: ₹$_routeFare');
      }
    }
  }

  // Method to calculate discount
  double _calculateDiscount() {
    double discount = 0.0;
    if (_bookingForWomen) {
      if (_pregnantWomenDiscount) discount += 0.1; // 10% discount
      if (_handicapWomenDiscount) discount += 0.1; // 10% discount
    }
    return discount;
  }

  // Enhanced method to calculate total fare with route-based pricing
  Map<String, double> _calculateFare() {
    // Use route fare if available, otherwise use default base fare
    double baseFare = _routeFare > 0 ? _routeFare : 15.0;
    double discountPercentage = _calculateDiscount();
    double discountAmount = baseFare * discountPercentage;
    double finalFare = baseFare - discountAmount;
    
    return {
      'baseFare': baseFare,
      'discountAmount': discountAmount,
      'finalFare': finalFare,
      'discountPercentage': discountPercentage * 100,
    };
  }

  // Callback method for when places are selected
  void _onPlaceSelected(Map<String, dynamic> place, bool isFromPlace) {
    setState(() {
      if (isFromPlace) {
        _fromPlace = place;
      } else {
        _toPlace = place;
      }
      _errorMessage.value = '';
    });
    
    // Calculate route info when both places are selected
    if (_fromPlace != null && _toPlace != null) {
      // Add a small delay to ensure the widget state is updated
      Future.delayed(const Duration(milliseconds: 100), () {
        _calculateRouteInfo();
      });
    }
  }

  // Callback method for when route is calculated
  void _onRouteCalculated(double distance, double fare) {
    setState(() {
      _totalDistance = distance;
      _routeFare = fare;
    });
    print('Route callback: Distance: $distance km, Fare: ₹$fare');
  }

  // Method to handle bottom navigation tap
  void _onBottomNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    switch (index) {
      case 0: // Home
        break;
      case 1: // Bookings
       Get.to(() => TellUsScreen(
        userEmail: _getUserEmail(),
        userPhone: _getUserPhone(),
        userName: _getUserName(),
        userId: _getUserId(),
      ));
        break;
      case 2: // Help
      Get.to(() => HelpScreen());
        break;
      case 3: // My Account - Open drawer
        _scaffoldKey.currentState?.openDrawer();
        // Refresh user data when opening account section
        if (!_hasUserDataFromLogin()) {
          _fetchUserDataByPhone();
        }
        break;
    }
  }

  // Helper method to get current date
  String _getCurrentDate() {
    DateTime now = DateTime.now();
    List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[now.month - 1]} ${now.year}';
  }

  // Method to show logout confirmation dialog
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate back to login screen or initial screen
                Get.offAll(() => UIScreen(), arguments: {'initialPage': 0});
                Get.snackbar(
                  'Success',
                  'Logged out successfully',
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                  margin: const EdgeInsets.all(16),
                  borderRadius: 8,
                  duration: const Duration(seconds: 2),
                );
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // Helper method to build info cards in drawer
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      // Add the drawer
      drawer: _buildUserAccountDrawer(),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          automaticallyImplyLeading: false,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.pink],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: AppBar(
              centerTitle: true,
              backgroundColor: Colors.transparent.withOpacity(0.20),
              elevation: 50,
              title: const Text(
                'PMPML',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Get.offAll(() => UIScreen(), arguments: {'initialPage': 2});
                },
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: GradientBackground(
          child: Padding(
            padding: const EdgeInsets.only(bottom:16, right:16, left: 16),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Debug info card (remove this in production)
                if (_isLoadingUserData) ...[
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(width: 16),
                          Text('Loading user data for: ${widget.userPhone}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],


                // Error Message Display
                Obx(() {
                  if (_errorMessage.value.isNotEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.red,
                      child: Text(
                        _errorMessage.value,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),

                // From & To Input Fields
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  child: Column(
                    children: [
                      PlaceSuggestionField(
                        key: _fromFieldKey,
                        hint: 'From',
                        icon: Icons.directions_bus,
                        onPlaceSelected: (place) => _onPlaceSelected(place, true),
                        onRouteCalculated: _onRouteCalculated,
                      ),
                      const Divider(height: 1, thickness: 1),
                      PlaceSuggestionField(
                        key: _toFieldKey,
                        hint: 'To',
                        icon: Icons.location_on,
                        onPlaceSelected: (place) => _onPlaceSelected(place, false),
                        onRouteCalculated: _onRouteCalculated,
                      ),
                    ],
                  ),
                ),

                // Add Route Information Card (if you want to show distance and fare)
if (_fromPlace != null && _toPlace != null && _totalDistance > 0) ...[
  const SizedBox(height: 16),
  Container(
    margin: const EdgeInsets.symmetric(horizontal: 4),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      gradient: LinearGradient(
        colors: [Colors.blue.shade50, Colors.blue.shade100],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.all(color: Colors.blue.shade200),
      boxShadow: [
        BoxShadow(
          color: Colors.blue.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Column(
          children: [
            Icon(Icons.straighten, color: Colors.blue.shade700),
            const SizedBox(height: 4),
            Text(
              '${_totalDistance.toStringAsFixed(1)} km',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            Text(
              'Distance',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade600,
              ),
            ),
          ],
        ),
        Container(
          width: 1,
          height: 40,
          color: Colors.blue.shade300,
        ),
        Column(
          children: [
            Icon(Icons.currency_rupee, color: Colors.green.shade700),
            const SizedBox(height: 4),
            Text(
              '₹${_routeFare.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            Text(
              'Fare',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade600,
              ),
            ),
          ],
        ),
      ],
    ),
  ),
],
                const SizedBox(height: 16),

                // Booking for Women Toggle
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        child: Row(
                          children: [
                            const Icon(Icons.woman, color: Colors.pinkAccent),
                            const SizedBox(width: 10),
                            const Text('Booking for women', style: TextStyle(fontSize: 16)),
                            const Spacer(),
                            Switch(
                              value: _bookingForWomen,
                              onChanged: (value) {
                                setState(() {
                                  _bookingForWomen = value;
                                  if (!value) {
                                    _pregnantWomenDiscount = false;
                                    _handicapWomenDiscount = false;
                                  }
                                });
                              },
                              activeColor: Colors.pinkAccent,
                            ),
                          ],
                        ),
                      ),
                      
                      // Additional discount options
                      if (_bookingForWomen) ...[
                        const Divider(height: 1, thickness: 1),
                        // Pregnant Women Discount
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.pink.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.pregnant_woman, color: Colors.pinkAccent, size: 20),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Discount for Pregnant Women', 
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)
                                    ),
                                    Text('10% discount on fare', 
                                      style: TextStyle(fontSize: 12, color: Colors.grey)
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _pregnantWomenDiscount,
                                onChanged: (value) {
                                  setState(() {
                                    _pregnantWomenDiscount = value;
                                  });
                                },
                                activeColor: Colors.pinkAccent,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ],
                          ),
                        ),
                        
                        // Handicap Women Discount
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.accessible, color: Colors.blue, size: 20),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Discount for Handicap Women', 
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)
                                    ),
                                    Text('10% discount on fare', 
                                      style: TextStyle(fontSize: 12, color: Colors.grey)
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _handicapWomenDiscount,
                                onChanged: (value) {
                                  setState(() {
                                    _handicapWomenDiscount = value;
                                  });
                                },
                                activeColor: Colors.blue,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Fare Preview Card
                if (_bookingForWomen && (_pregnantWomenDiscount || _handicapWomenDiscount)) ...[
                  const SizedBox(height: 16),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.discount, color: Colors.green),
                              const SizedBox(width: 8),
                              const Text(
                                'Fare Preview',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Base Fare:', style: TextStyle(fontSize: 14)),
                              Text('₹${_calculateFare()['baseFare']!.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Discount (${_calculateFare()['discountPercentage']!.toStringAsFixed(0)}%):', 
                                style: TextStyle(fontSize: 14, color: Colors.green.shade700)),
                              Text('-₹${_calculateFare()['discountAmount']!.toStringAsFixed(2)}',
                                style: TextStyle(fontSize: 14, color: Colors.green.shade700)),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Final Fare:', 
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text('₹${_calculateFare()['finalFare']!.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),

            

                // Search Button
                ElevatedButton.icon(
                  onPressed: () {
                    if (_fromPlace != null && _toPlace != null) {
                      Get.to(() => MapScreen(
                            fromPlace: _fromPlace,
                            toPlace: _toPlace,
                          ));
                    } else {
                      Get.snackbar(
                        'Error',
                        'Please select both origin and destination locations',
                        snackPosition: SnackPosition.TOP,
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                        margin: const EdgeInsets.all(16),
                        borderRadius: 8,
                        duration: const Duration(seconds: 3),
                      );
                    }
                  },
                  icon: const Icon(Icons.search, color: Colors.white),
                  label: const Text('Search buses', style: TextStyle(fontSize: 18, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 16),

                // 2x3 Grid for Ticket and Bus Options
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.6,
                  children: [
                    // Update your Book Ticket navigation in HomeScreen
_buildCard('Book Ticket', Icons.confirmation_number, Colors.red, () {
  if (_fromPlace != null && _toPlace != null) {
    Map<String, double> fareDetails = _calculateFare();
    
Get.to(() => BookTicketScreen(
  fromPlace: _fromPlace,
  toPlace: _toPlace,
  baseFare: fareDetails['baseFare']!,
  discountAmount: fareDetails['discountAmount']!,
  totalFare: fareDetails['finalFare']!,
  discountPercentage: fareDetails['discountPercentage']!,
  totalDistance: _totalDistance,
  userEmail: _getUserEmail(),
  userPhone: _getUserPhone(),
  isWomenBooking: _bookingForWomen,
  isPregnantDiscount: _pregnantWomenDiscount,
  isHandicapDiscount: _handicapWomenDiscount,
  // Handle nullable values with null coalescing operator
  userName: widget.userName ?? 'Guest User',
  userId: _getUserId() ?? 'N/A',
  userAdharNumber: _getUserAdharNumber() ?? 'Not Provided',
  userCreationDate: _getFormattedCreationDate() ?? 'N/A',
));
  } else {
    Get.snackbar(
      'Error',
      'Please select both origin and destination locations',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      duration: const Duration(seconds: 3),
    );
  }
}),
     _buildCard('View Ticket', Icons.receipt_long, Colors.blue, () {
  // Navigate to ViewTicket screen with required userId parameter
  Get.to(() => ViewTicketScreen(
    userId: _getUserId(), // Pass the required userId parameter
  ));
}),
   // Update your Bus Pass navigation in HomeScreen (around line 700)
_buildCard('Bus Pass', Icons.card_membership, Colors.green, () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => BusPassScreen(
        userEmail: _getUserEmail(),
        userPhone: _getUserPhone(),
        userName: _getUserName(),
        userId: _getUserId(),  // Add this line - was missing!
      ),
    ),
  );
}),

                    _buildCard('View Pass', Icons.credit_card, Colors.teal, () {
  // Navigate to ViewPass screen with required parameters
  Get.to(() => ViewPassScreen(
    userId: _getUserId(), // Required userId parameter
    userName: _getUserName(), // Optional userName parameter
    userPhone: _getUserPhone(), // Optional userPhone parameter
  ));
}),
                    _buildCard('Scan Upcoming Bus', Icons.qr_code_scanner, Colors.purple, () {
                      Get.to(() => ScannerScreen());
                    }),
                    _buildCard('City Routes', Icons.map, Colors.orange, () {
                          Get.to(() => ViewRoutesScreen());
                    }),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.black54,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Tell Us',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.help),
            label: 'Help',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }

 Widget _buildUserAccountDrawer() {
  return Drawer(
    child: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.pink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // User Header Section - Fixed height
          Container(
            padding: const EdgeInsets.only(top: 40, bottom: 20, left: 20, right: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                
                // User Avatar
                Center(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.3),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.account_circle,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // User Name and ID Section
                Center(
                  child: Column(
                    children: [
                      Text(
                        widget.userName ?? 'User Name',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'User ID: ${_getUserId()}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                // PMPML Member text
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'PMPML Member',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Scrollable Content Section
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: _isLoadingUserData 
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading account information...'),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Account Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Email Card
                        _buildInfoCard(
                          icon: Icons.email,
                          title: 'Email Address',
                          value: _getUserEmail(), // Use getter method
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 12),

                        // Phone Card
                        _buildInfoCard(
                          icon: Icons.phone,
                          title: 'Phone Number',
                          value: _getUserPhone(), // Use getter method
                          color: Colors.green,
                        ),
                        const SizedBox(height: 12),

                        // Adhar Card
                        if (_getUserAdharNumber() != null) ...[
                          _buildInfoCard(
                            icon: Icons.credit_card,
                            title: 'Adhar (Last 4 digits)',
                            value: '****${_getUserAdharNumber()}', // Use getter method
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Member Since Card
                        _buildInfoCard(
                          icon: Icons.calendar_today,
                          title: 'Member Since',
                          value: _getFormattedCreationDate(), // Use method for formatted date
                          color: Colors.purple,
                        ),
                        
                        const SizedBox(height: 30), // Add some space before buttons
                        
                        // Action Buttons
                        Column(
                          children: [
                            // Edit Profile Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Handle edit profile action
                                  Navigator.pop(context);
                                  Get.snackbar(
                                    'Info',
                                    'Edit profile feature coming soon!',
                                    snackPosition: SnackPosition.TOP,
                                    backgroundColor: Colors.blue,
                                    colorText: Colors.white,
                                    margin: const EdgeInsets.all(16),
                                    borderRadius: 8,
                                    duration: const Duration(seconds: 2),
                                  );
                                },
                                icon: const Icon(Icons.edit, color: Colors.white),
                                label: const Text('Edit Profile', 
                                  style: TextStyle(fontSize: 16, color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            
                            // Logout Button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  // Handle logout action
                                  _showLogoutDialog(context);
                                },
                                icon: const Icon(Icons.logout, color: Colors.red),
                                label: const Text('Logout', 
                                  style: TextStyle(fontSize: 16, color: Colors.red)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        // Add bottom padding to ensure content doesn't get cut off
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
            ),
          ),
        ],
      ),
    ),
  );
}

  
  Widget _buildCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 35, color: color),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateButton(String label, bool isSelected) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.red : Colors.grey.shade300,
        foregroundColor: isSelected ? Colors.white : Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(label),
    );
  }
}