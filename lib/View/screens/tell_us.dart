import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:pmpml_app/config/api_config.dart';

class TellUsScreen extends StatefulWidget {
  final String? userEmail;
  final String? userPhone;
  final String? userName;
  final String? userId;

  const TellUsScreen({
    Key? key,
    this.userEmail,
    this.userPhone,
    this.userName,
    this.userId,
  }) : super(key: key);

  @override
  _TellUsScreenState createState() => _TellUsScreenState();
}

class _TellUsScreenState extends State<TellUsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Form controllers
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _busNumberController = TextEditingController();
  final TextEditingController _routeController = TextEditingController();
  final TextEditingController _driverNameController = TextEditingController();
  
  // Form keys
  final GlobalKey<FormState> _feedbackFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _complaintFormKey = GlobalKey<FormState>();
  
  // State variables
  String _selectedFeedbackCategory = 'Service Quality';
  String _selectedComplaintCategory = 'Bus Service';
  String _selectedPriority = 'Medium';
  int _rating = 5;
  bool _isSubmitting = false;
  
  // Categories
  final List<String> _feedbackCategories = [
    'Service Quality',
    'App Experience',
    'Driver Behavior',
    'Bus Condition',
    'Route Suggestion',
    'General Feedback'
  ];
  
  final List<String> _complaintCategories = [
    'Bus Service',
    'Driver Issues',
    'App Problems',
    'Payment Issues',
    'Route Problems',
    'Safety Concerns'
  ];
  
  final List<String> _priorityLevels = ['Low', 'Medium', 'High', 'Urgent'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    _busNumberController.dispose();
    _routeController.dispose();
    _driverNameController.dispose();
    super.dispose();
  }

  // Enhanced feedback submission with validation
  Future<void> _submitFeedback() async {
    if (!_feedbackFormKey.currentState!.validate()) {
      return;
    }

    if (_messageController.text.trim().length < 10) {
      _showSnackbar('Error', 'Please provide more detailed feedback (minimum 10 characters)', Colors.red);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final feedbackData = {
        'type': 'feedback',
        'userId': widget.userId ?? 'anonymous',
        'userName': widget.userName ?? 'Anonymous User',
        'userEmail': widget.userEmail ?? '',
        'userPhone': widget.userPhone ?? '',
        'category': _selectedFeedbackCategory,
        'subject': _subjectController.text.trim(),
        'message': _messageController.text.trim(),
        'rating': _rating,
        'busNumber': _busNumberController.text.trim(),
        'route': _routeController.text.trim(),
        'driverName': _driverNameController.text.trim(),
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'submitted',
        'platform': 'mobile_app'
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/feedback/submit'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(feedbackData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _clearForm();
        _showSuccessDialog('Feedback Submitted!', 
          'Thank you for your valuable feedback. We appreciate your input and will use it to improve our services.');
      } else {
        throw Exception('Failed to submit feedback: ${response.statusCode}');
      }
    } catch (e) {
      print('Error submitting feedback: $e');
      _showSnackbar('Error', 'Failed to submit feedback. Please try again.', Colors.red);
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  // Enhanced complaint submission with priority handling
  Future<void> _submitComplaint() async {
    if (!_complaintFormKey.currentState!.validate()) {
      return;
    }

    if (_messageController.text.trim().length < 20) {
      _showSnackbar('Error', 'Please provide detailed complaint description (minimum 20 characters)', Colors.red);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final complaintData = {
        'type': 'complaint',
        'userId': widget.userId ?? 'anonymous',
        'userName': widget.userName ?? 'Anonymous User',
        'userEmail': widget.userEmail ?? '',
        'userPhone': widget.userPhone ?? '',
        'category': _selectedComplaintCategory,
        'priority': _selectedPriority,
        'subject': _subjectController.text.trim(),
        'message': _messageController.text.trim(),
        'busNumber': _busNumberController.text.trim(),
        'route': _routeController.text.trim(),
        'driverName': _driverNameController.text.trim(),
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'pending',
        'ticketId': _generateTicketId(),
        'platform': 'mobile_app'
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/complaints/submit'),

        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(complaintData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _clearForm();
        _showSuccessDialog('Complaint Registered!', 
          'Your complaint has been registered with ticket ID: ${complaintData['ticketId']}. We will address it based on the priority level.');
      } else {
        throw Exception('Failed to submit complaint: ${response.statusCode}');
      }
    } catch (e) {
      print('Error submitting complaint: $e');
      _showSnackbar('Error', 'Failed to submit complaint. Please try again.', Colors.red);
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  // Generate unique ticket ID for complaints
  String _generateTicketId() {
    final now = DateTime.now();
    final timestamp = DateFormat('yyyyMMddHHmm').format(now);
    final random = (DateTime.now().millisecondsSinceEpoch % 1000).toString().padLeft(3, '0');
    return 'PMPML$timestamp$random';
  }

  // Clear form fields
  void _clearForm() {
    _subjectController.clear();
    _messageController.clear();
    _busNumberController.clear();
    _routeController.clear();
    _driverNameController.clear();
    setState(() {
      _rating = 5;
      _selectedFeedbackCategory = 'Service Quality';
      _selectedComplaintCategory = 'Bus Service';
      _selectedPriority = 'Medium';
    });
  }

  // Show success dialog
void _showSuccessDialog(String title, String message) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 30),
            SizedBox(width: 10),
            Expanded( // Wrap with Expanded to avoid overflow
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 18, // Adjusted title font size
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(fontSize: 14), // Reduced font size here
          textAlign: TextAlign.left,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Get.back(); // Return to previous screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'OK',
              style: TextStyle(color: Colors.white, fontSize: 14), // Optional: match smaller size
            ),
          ),
        ],
      );
    },
  );
}


  // Show snackbar
  void _showSnackbar(String title, String message, Color color) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: color,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(125), // Increased height to accommodate title positioning
        child: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.pink],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Column(
            children: [
              SizedBox(height: 35), // Added 35px spacing from top
              Text(
                'Tell Us',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Your voice matters to us',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          centerTitle: true,
          leading: Padding(
            padding: EdgeInsets.only(top: 15), // Align back button with title
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Get.back(),
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            tabs: const [
              Tab(
                icon: Icon(Icons.feedback_outlined),
                text: 'Feedback',
              ),
              Tab(
                icon: Icon(Icons.report_problem_outlined),
                text: 'Complaint',
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFeedbackTab(),
          _buildComplaintTab(),
        ],
      ),
    );
  }

  Widget _buildFeedbackTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _feedbackFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 5,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.feedback, color: Colors.white, size: 30),
                      SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Share Your Experience',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Help us improve our services',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),

              // Rating Section
              _buildSectionCard(
                'Rate Your Experience',
                Icons.star_rate,
                Colors.orange,
                Column(
                  children: [
                    Text(
                      'How would you rate your overall experience?',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _rating = index + 1;
                            });
                          },
                          child: Icon(
                            index < _rating ? Icons.star : Icons.star_border,
                            color: Colors.orange,
                            size: 35,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _getRatingText(_rating),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getRatingColor(_rating),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              // Category Selection
              _buildSectionCard(
                'Feedback Category',
                Icons.category,
                Colors.blue,
                DropdownButtonFormField<String>(
                  value: _selectedFeedbackCategory,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  items: _feedbackCategories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedFeedbackCategory = newValue!;
                    });
                  },
                ),
              ),

              const SizedBox(height: 15),

              // Subject Field
              _buildSectionCard(
                'Subject',
                Icons.subject,
                Colors.purple,
                TextFormField(
                  controller: _subjectController,
                  decoration: InputDecoration(
                    hintText: 'Brief summary of your feedback',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a subject';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 15),

              // Message Field
              _buildSectionCard(
                'Your Message',
                Icons.message,
                Colors.teal,
                TextFormField(
                  controller: _messageController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Share your detailed feedback here...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 80),
                      child: Icon(Icons.edit),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your feedback';
                    }
                    if (value.trim().length < 10) {
                      return 'Please provide more detailed feedback';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 15),

              // Optional Fields
              _buildOptionalFieldsSection(),

              const SizedBox(height: 25),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitFeedback,
                  icon: _isSubmitting 
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Icon(Icons.send, color: Colors.white),
                  label: Text(
                    _isSubmitting ? 'Submitting...' : 'Submit Feedback',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    elevation: 5,
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComplaintTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade50, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Form(
          key: _complaintFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 5,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: LinearGradient(
                      colors: [Colors.red.shade400, Colors.red.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.report_problem, color: Colors.white, size: 30),
                      SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Register Your Complaint',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'We take your concerns seriously',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Priority Section - Separate card to avoid overflow
              _buildSectionCard(
                'Priority Level',
                Icons.priority_high,
                Colors.orange,
                DropdownButtonFormField<String>(
                  value: _selectedPriority,
                  isExpanded: true, // Prevents overflow
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _priorityLevels.map((String priority) {
                    return DropdownMenuItem<String>(
                      value: priority,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getPriorityColor(priority),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 8),
                          Flexible(child: Text(priority, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedPriority = newValue!;
                    });
                  },
                ),
              ),

              const SizedBox(height: 15),

              // Category Section - Separate card to avoid overflow
              _buildSectionCard(
                'Complaint Category',
                Icons.category,
                Colors.blue,
                DropdownButtonFormField<String>(
                  value: _selectedComplaintCategory,
                  isExpanded: true, // Prevents overflow
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _complaintCategories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedComplaintCategory = newValue!;
                    });
                  },
                ),
              ),

              const SizedBox(height: 15),

              // Subject Field
              _buildSectionCard(
                'Subject',
                Icons.subject,
                Colors.purple,
                TextFormField(
                  controller: _subjectController,
                  decoration: InputDecoration(
                    hintText: 'Brief summary of your complaint',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    prefixIcon: Icon(Icons.title),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a subject';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 15),

              // Message Field
              _buildSectionCard(
                'Complaint Details',
                Icons.description,
                Colors.red,
                TextFormField(
                  controller: _messageController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: 'Describe your complaint in detail...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 100),
                      child: Icon(Icons.edit),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please describe your complaint';
                    }
                    if (value.trim().length < 20) {
                      return 'Please provide detailed complaint description';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 15),

              // Optional Fields
              _buildOptionalFieldsSection(),

              const SizedBox(height: 25),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitComplaint,
                  icon: _isSubmitting 
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Icon(Icons.send, color: Colors.white),
                  label: Text(
                    _isSubmitting ? 'Submitting...' : 'Submit Complaint',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    elevation: 5,
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionalFieldsSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: ExpansionTile(
        leading: Icon(Icons.info_outline, color: Colors.blue),
        title: Text(
          'Additional Information (Optional)',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextFormField(
                  controller: _busNumberController,
                  decoration: InputDecoration(
                    labelText: 'Bus Number',
                    hintText: 'e.g., MH-12-AB-1234',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: Icon(Icons.directions_bus),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _routeController,
                  decoration: InputDecoration(
                    labelText: 'Route',
                    hintText: 'e.g., Katraj to Swargate',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: Icon(Icons.route),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _driverNameController,
                  decoration: InputDecoration(
                    labelText: 'Driver/Conductor Name',
                    hintText: 'If applicable',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: Icon(Icons.person),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, Color color, Widget child) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1: return 'Very Poor';
      case 2: return 'Poor';
      case 3: return 'Average';
      case 4: return 'Good';
      case 5: return 'Excellent';
      default: return 'Rate Us';
    }
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 1: return Colors.red;
      case 2: return Colors.orange;
      case 3: return Colors.yellow.shade700;
      case 4: return Colors.lightGreen;
      case 5: return Colors.green;
      default: return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Low': return Colors.green;
      case 'Medium': return Colors.orange;
      case 'High': return Colors.red;
      case 'Urgent': return Colors.red.shade700;
      default: return Colors.grey;
    }
  }
}