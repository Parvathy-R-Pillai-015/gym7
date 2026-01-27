import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'workout_videos_screen.dart';
import 'chat_screen.dart';
import 'food_calorie_calculator_screen.dart';
import 'subscription_renewal_screen.dart';
import 'food_recipes_screen.dart';

class HomeScreen extends StatefulWidget {
  final int userId;
  final String userName;

  const HomeScreen({Key? key, required this.userId, required this.userName})
    : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _userProfile;
  String? _error;
  List<Map<String, dynamic>> _attendanceHistory = [];
  int _totalAttendance = 0;
  int _pendingAttendance = 0;
  int _totalAbsent = 0;
  bool _canRequestToday = true;
  Map<String, dynamic>? _dietPlan;
  bool _hasDietPlan = false;
  Map<String, dynamic>? _subscriptionStatus;
  bool _subscriptionLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadAttendance();
    _loadDietPlan();
    _loadSubscriptionStatus();
  }

  Future<void> _loadUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/profile/${widget.userId}/'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _userProfile = data['profile'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = 'Failed to load profile';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Failed to load profile';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAttendance() async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://127.0.0.1:8000/api/attendance/user/${widget.userId}/',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _attendanceHistory = List<Map<String, dynamic>>.from(
              data['attendances'],
            );
            _totalAttendance = data['total_accepted'];
            _pendingAttendance = data['total_pending'];
            _totalAbsent = data['total_absent'] ?? 0;

            // Check if already requested today
            final today = DateTime.now().toIso8601String().split('T')[0];
            _canRequestToday = !_attendanceHistory.any(
              (att) => att['date'] == today,
            );
          });
        }
      }
    } catch (e) {
      print('Error loading attendance: $e');
    }
  }

  Future<void> _loadDietPlan() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/diet/plan/user/${widget.userId}/'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['has_plan'] == true) {
          setState(() {
            _dietPlan = data['diet_plan'];
            _hasDietPlan = true;
          });
        }
      }
    } catch (e) {
      print('Error loading diet plan: $e');
    }
  }

  Future<void> _loadSubscriptionStatus() async {
    setState(() => _subscriptionLoading = true);
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/subscription/status/${widget.userId}/'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _subscriptionStatus = data['subscription'];
            _subscriptionLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading subscription status: $e');
      setState(() => _subscriptionLoading = false);
    }
  }

  Future<void> _requestAttendance() async {
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/attendance/request/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': widget.userId}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message']),
            backgroundColor: Colors.green,
          ),
        );
        _loadAttendance();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Failed to request attendance'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showAttendanceHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('My Attendance History'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              Card(
                color: const Color(0xFF7B4EFF).withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            '$_totalAttendance',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7B4EFF),
                            ),
                          ),
                          const Text('Accepted'),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            '$_pendingAttendance',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const Text('Pending'),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            '$_totalAbsent',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const Text('Absent'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _attendanceHistory.isEmpty
                    ? const Center(child: Text('No attendance records yet'))
                    : ListView.builder(
                        itemCount: _attendanceHistory.length,
                        itemBuilder: (context, index) {
                          final att = _attendanceHistory[index];
                          final status = att['status'];
                          return ListTile(
                            leading: Icon(
                              status == 'accepted'
                                  ? Icons.check_circle
                                  : status == 'pending'
                                  ? Icons.pending
                                  : status == 'absent'
                                  ? Icons.event_busy
                                  : Icons.cancel,
                              color: status == 'accepted'
                                  ? Colors.green
                                  : status == 'pending'
                                  ? Colors.orange
                                  : status == 'absent'
                                  ? Colors.red
                                  : Colors.grey,
                            ),
                            title: Text(att['date']),
                            subtitle: Text('Status: ${status.toUpperCase()}'),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showReviewDialog() {
    int selectedRating = 0;
    final TextEditingController reviewController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Rate Your Trainer'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Rating (1-5 Stars)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < selectedRating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 40,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          selectedRating = index + 1;
                        });
                      },
                    );
                  }),
                ),
                if (selectedRating > 0)
                  Center(
                    child: Text(
                      '$selectedRating Star${selectedRating > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Write Your Review',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: reviewController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Share your experience with the trainer...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Note: You can post one review per month',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedRating > 0
                  ? () async {
                      if (reviewController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please write a review'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      try {
                        final response = await http.post(
                          Uri.parse('http://127.0.0.1:8000/api/review/create/'),
                          headers: {'Content-Type': 'application/json'},
                          body: json.encode({
                            'user_id': widget.userId,
                            'rating': selectedRating,
                            'review_text': reviewController.text.trim(),
                          }),
                        );

                        final data = json.decode(response.body);

                        Navigator.pop(context);

                        if (response.statusCode == 201 && data['success'] == true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(data['message']),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(data['message'] ?? 'Failed to post review'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B9D),
                foregroundColor: Colors.white,
              ),
              child: const Text('Submit Review'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDietPlanDetails() {
    showDialog(
      context: context,
      builder: (context) => _DietPlanDetailsDialog(dietPlan: _dietPlan!),
    );
  }

  Widget _buildMealSection(String mealName, List<dynamic> items) {
    int totalCal = 0;
    for (var item in items) {
      totalCal += (item['calories'] as num).toInt();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  mealName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                Text(
                  '$totalCal cal',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 6, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${item['food']} - ${item['quantity']}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(
                        '${item['calories']} cal',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fitness Gym'),
        backgroundColor: const Color(0xFF7B4EFF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/user-profile',
                arguments: {
                  'userId': widget.userId,
                  'userName': widget.userName,
                },
              ).then((_) => _loadUserProfile());
            },
            tooltip: 'Edit Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/');
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF7B4EFF).withOpacity(0.1),
                    Colors.white,
                  ],
                ),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text(
                      'Welcome, ${widget.userName}!',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Your fitness journey starts here',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 20),
                    _buildProfileCard(),
                    const SizedBox(height: 20),
                    _buildSubscriptionCard(),
                    const SizedBox(height: 30),
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildActionCard(
                          'Chat with Trainer',
                          Icons.chat_bubble,
                          const Color(0xFF4CAF50),
                          () {
                            if (_userProfile != null && _userProfile!['assigned_trainer'] != null) {
                              final trainer = _userProfile!['assigned_trainer'];
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    userId: _userProfile!['user_id'],
                                    trainerId: trainer['id'],
                                    trainerName: trainer['name'] ?? 'Trainer',
                                    senderType: 'user',
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('No trainer assigned yet'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        ),
                        _buildActionCard(
                          'Food Calorie Calculator',
                          Icons.fastfood,
                          const Color(0xFF4ECDC4),
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FoodCalorieCalculatorScreen(
                                  userId: widget.userId,
                                  userName: widget.userName,
                                ),
                              ),
                            );
                          },
                        ),
                        _buildActionCard(
                          'Healthy Food Recipes',
                          Icons.restaurant,
                          const Color(0xFF4CAF50),
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FoodRecipesScreen(
                                  userId: widget.userId,
                                ),
                              ),
                            );
                          },
                        ),
                        _buildActionCard(
                          'Renew Subscription',
                          Icons.card_membership,
                          const Color(0xFF9C27B0),
                          () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SubscriptionRenewalScreen(
                                  userId: widget.userId,
                                  userName: widget.userName,
                                ),
                              ),
                            );
                            if (result == true) {
                              _loadSubscriptionStatus();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildProfileCard() {
    if (_userProfile == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B4EFF).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  size: 30,
                  color: Color(0xFF7B4EFF),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Profile',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Goal: ${_userProfile!['goal']?.toString().replaceAll('_', ' ').toUpperCase() ?? 'N/A'}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF7B4EFF).withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.phone, size: 20, color: Color(0xFF7B4EFF)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mobile Number',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _userProfile!['mobile_number']?.toString() ??
                          'Not Available',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Age',
                  '${_userProfile!['age']} yrs',
                  Icons.cake,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  'Gender',
                  _userProfile!['gender']?.toString().toUpperCase() ?? 'N/A',
                  Icons.person_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Current Weight',
                  '${_userProfile!['current_weight']} kg',
                  Icons.monitor_weight,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  'Target Weight',
                  '${_userProfile!['target_weight']} kg',
                  Icons.flag,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Height',
                  '${_userProfile!['current_height']} cm',
                  Icons.height,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  'Target',
                  '${_userProfile!['target_months']} months',
                  Icons.calendar_today,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Workout Time',
                  _userProfile!['workout_time'] == 'morning'
                      ? 'Morning'
                      : 'Evening',
                  Icons.access_time,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  'Diet',
                  _userProfile!['diet_preference']
                          ?.toString()
                          .replaceAll('_', ' ')
                          .toUpperCase() ??
                      'N/A',
                  Icons.restaurant,
                ),
              ),
            ],
          ),
          // Trainer Information
          if (_userProfile!['assigned_trainer'] != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple[100]!, Colors.purple[50]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.purple[300]!, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.person_pin,
                        color: Colors.purple[700],
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Your Assigned Trainer',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTrainerInfo(
                    'Name',
                    _userProfile!['assigned_trainer']['name'],
                  ),
                  _buildTrainerInfo(
                    'Experience',
                    '${_userProfile!['assigned_trainer']['experience']} years',
                  ),
                  _buildTrainerInfo(
                    'Specialization',
                    _userProfile!['assigned_trainer']['specialization'],
                  ),
                  _buildTrainerInfo(
                    'Certification',
                    _userProfile!['assigned_trainer']['certification'],
                  ),
                  _buildTrainerInfo(
                    'Mobile',
                    _userProfile!['assigned_trainer']['mobile'],
                  ),
                ],
              ),
            ),
          ],
          // Attendance Section
          const SizedBox(height: 20),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF7B4EFF).withOpacity(0.05),
                    Colors.white,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFF7B4EFF)),
                    const SizedBox(width: 8),
                    const Text(
                      'Attendance',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          '$_totalAttendance',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7B4EFF),
                          ),
                        ),
                        const Text('Accepted'),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          '$_pendingAttendance',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const Text('Pending'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _canRequestToday ? _requestAttendance : null,
                        icon: const Icon(Icons.add_task),
                        label: Text(
                          _canRequestToday
                              ? 'Request Today'
                              : 'Already Requested',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7B4EFF),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showAttendanceHistory,
                        icon: const Icon(Icons.history),
                        label: const Text('View History'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF7B4EFF),
                          side: const BorderSide(color: Color(0xFF7B4EFF)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ),
          const SizedBox(height: 20),
          // Diet Plan Section
          if (_hasDietPlan && _dietPlan != null)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.restaurant_menu, color: Colors.white, size: 28),
                        const SizedBox(width: 10),
                        const Text(
                          'My Diet Plan',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _dietPlan!['plan_name'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Target: ${_dietPlan!['target_calories']} cal/day',
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          Text(
                            'By: ${_dietPlan!['trainer_name']}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showDietPlanDetails(),
                      icon: const Icon(Icons.visibility),
                      label: const Text('View Full Diet Plan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF4CAF50),
                        minimumSize: const Size(double.infinity, 45),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
          // Workout Videos Section
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE91E63), Color(0xFFF06292)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.play_circle_filled, color: Colors.white, size: 28),
                      const SizedBox(width: 10),
                      const Text(
                        'Workout Videos',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Watch personalized workout videos tailored to your fitness goals',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WorkoutVideosScreen(userId: widget.userId),
                        ),
                      );
                    },
                    icon: const Icon(Icons.video_library),
                    label: const Text('Browse Videos'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFE91E63),
                      minimumSize: const Size(double.infinity, 45),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Review Section
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B9D), Color(0xFFFFA06B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 28),
                      const SizedBox(width: 10),
                      const Text(
                        'Rate Your Trainer',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showReviewDialog(),
                    icon: const Icon(Icons.rate_review),
                    label: const Text('Post Review'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFFF6B9D),
                      minimumSize: const Size(double.infinity, 45),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    if (_subscriptionLoading) {
      return Card(
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_subscriptionStatus == null) {
      return const SizedBox.shrink();
    }

    final isActive = _subscriptionStatus!['is_active'] ?? false;
    final isExpired = _subscriptionStatus!['is_expired'] ?? false;
    final expiringSoon = _subscriptionStatus!['expiring_soon'] ?? false;
    final remainingDays = _subscriptionStatus!['remaining_days'] ?? 0;
    final canRenew = _subscriptionStatus!['can_renew'] ?? false;

    Color cardColor;
    Color statusColor;
    String statusText;

    if (isActive && !expiringSoon) {
      cardColor = Colors.green.withOpacity(0.05);
      statusColor = Colors.green;
      statusText = 'Active';
    } else if (expiringSoon) {
      cardColor = Colors.orange.withOpacity(0.05);
      statusColor = Colors.orange;
      statusText = 'Expiring Soon';
    } else {
      cardColor = Colors.red.withOpacity(0.05);
      statusColor = Colors.red;
      statusText = isExpired ? 'Expired' : 'Inactive';
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.card_membership, color: statusColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Subscription Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? '$remainingDays days left' : 'Renew Now',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (isActive) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'End Date',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _subscriptionStatus!['subscription_end_date']
                                  ?.split('T')[0] ??
                              'N/A',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    if (canRenew || expiringSoon)
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  SubscriptionRenewalScreen(
                                userId: widget.userId,
                                userName: widget.userName,
                              ),
                            ),
                          );
                          if (result == true) {
                            _loadSubscriptionStatus();
                          }
                        },
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Renew'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: statusColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                      ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SubscriptionRenewalScreen(
                          userId: widget.userId,
                          userName: widget.userName,
                        ),
                      ),
                    );
                    if (result == true) {
                      _loadSubscriptionStatus();
                    }
                  },
                  icon: const Icon(Icons.card_membership),
                  label: const Text('Renew Subscription'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrainerInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.purple[900],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF7B4EFF)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
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
    );
  }

  Widget _buildWorkoutCard(String title, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: color),
          ),
          const SizedBox(height: 15),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 7-Day Diet Plan Dialog
class _DietPlanDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> dietPlan;

  const _DietPlanDetailsDialog({required this.dietPlan});

  @override
  State<_DietPlanDetailsDialog> createState() => _DietPlanDetailsDialogState();
}

class _DietPlanDetailsDialogState extends State<_DietPlanDetailsDialog> {
  String _selectedDay = 'monday';
  final List<String> _days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
  final Map<String, String> _dayNames = {
    'monday': 'Monday',
    'tuesday': 'Tuesday',
    'wednesday': 'Wednesday',
    'thursday': 'Thursday',
    'friday': 'Friday',
    'saturday': 'Saturday',
    'sunday': 'Sunday',
  };

  @override
  void initState() {
    super.initState();
    // Set today's day as default
    final now = DateTime.now();
    final weekday = now.weekday; // 1=Monday, 7=Sunday
    _selectedDay = weekday == 7 ? 'sunday' : _days[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final mealsData = widget.dietPlan['meals_data'] as Map<String, dynamic>;
    final is7DayPlan = mealsData.containsKey('monday');
    final currentDayMeals = is7DayPlan ? mealsData[_selectedDay] as Map<String, dynamic>? : mealsData;

    // Calculate the actual date for the selected day
    String displayDate = widget.dietPlan['start_date'];
    if (is7DayPlan) {
      try {
        final startDate = DateTime.parse(widget.dietPlan['start_date']);
        final dayIndex = _days.indexOf(_selectedDay);
        final selectedDate = startDate.add(Duration(days: dayIndex));
        displayDate = '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}';
      } catch (e) {
        displayDate = widget.dietPlan['start_date'];
      }
    }

    return AlertDialog(
      title: Text(widget.dietPlan['plan_name']),
      content: SizedBox(
        width: 600,
        height: 600,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Target: ${widget.dietPlan['target_calories']} cal/day',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text('Date: $displayDate'),
                  Text('Trainer: ${widget.dietPlan['trainer_name']}'),
                ],
              ),
            ),
            if (is7DayPlan) ...[
              const SizedBox(height: 16),
              const Text(
                'Select Day:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _days.map((day) {
                  final isSelected = day == _selectedDay;
                  return ChoiceChip(
                    label: Text(_dayNames[day]!.substring(0, 3)),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedDay = day;
                        });
                      }
                    },
                    selectedColor: Colors.green,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Text(
                _dayNames[_selectedDay]! + '\'s Plan',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (currentDayMeals != null) ...[
                      _buildMealSection('Breakfast', currentDayMeals['breakfast']),
                      _buildMealSection('Lunch', currentDayMeals['lunch']),
                      _buildMealSection('Dinner', currentDayMeals['dinner']),
                      _buildMealSection('Snacks', currentDayMeals['snacks']),
                    ],
                    if (widget.dietPlan['notes'] != null && 
                        widget.dietPlan['notes'].toString().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Trainer Notes:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(widget.dietPlan['notes']),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildMealSection(String mealName, dynamic items) {
    if (items == null) return const SizedBox.shrink();
    
    final itemList = items is List ? items : [];
    if (itemList.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mealName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 8),
            ...itemList.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 6, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${item['food']} - ${item['quantity']}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
