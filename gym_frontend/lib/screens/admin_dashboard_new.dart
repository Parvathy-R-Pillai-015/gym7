import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'trainer_management_tab.dart';
import 'admin_chat_tab.dart';
import 'add_recipe_screen.dart';
import 'edit_recipe_screen.dart';

class AdminDashboardNew extends StatefulWidget {
  const AdminDashboardNew({Key? key}) : super(key: key);

  @override
  State<AdminDashboardNew> createState() => _AdminDashboardNewState();
}

class _AdminDashboardNewState extends State<AdminDashboardNew> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _paidUsers = [];
  List<Map<String, dynamic>> _unpaidUsers = [];
  List<Map<String, dynamic>> _allReviews = [];
  List<Map<String, dynamic>> _allRecipes = [];
  List<Map<String, dynamic>> _filteredRecipes = [];
  Map<String, int> _recipeCounts = {'veg': 0, 'non_veg': 0, 'vegan': 0, 'other': 0};
  String _recipeSearchQuery = '';
  String _selectedFoodTypeFilter = 'all';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _loadAllData();
  }
  
  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
    });
    
    await Future.wait([
      _loadAllUsers(),
      _loadPaidUsers(),
      _loadUnpaidUsers(),
      _loadAllReviews(),
      _loadAllRecipes(),
    ]);
    
    setState(() {
      _isLoading = false;
    });
  }
  
  Future<void> _loadAllUsers() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/admin/users/all/'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _allUsers = List<Map<String, dynamic>>.from(data['users']);
          });
        }
      }
    } catch (e) {
      print('Error loading all users: $e');
    }
  }
  
  Future<void> _loadPaidUsers() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/admin/users/paid/'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _paidUsers = List<Map<String, dynamic>>.from(data['users']);
          });
        }
      }
    } catch (e) {
      print('Error loading paid users: $e');
    }
  }
  
  Future<void> _loadUnpaidUsers() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/admin/users/unpaid/'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _unpaidUsers = List<Map<String, dynamic>>.from(data['users']);
          });
        }
      }
    } catch (e) {
      print('Error loading unpaid users: $e');
    }
  }
  
  Future<void> _loadAllReviews() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/reviews/all/'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _allReviews = List<Map<String, dynamic>>.from(data['reviews']);
          });
        }
      }
    } catch (e) {
      print('Error loading reviews: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF7B4EFF),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All Users'),
            Tab(text: 'Paid Users'),
            Tab(text: 'Unpaid Users'),
            Tab(text: 'Trainers'),
            Tab(text: 'Reviews'),
            Tab(text: 'Recipes'),
            Tab(text: 'Chats'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAllData,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAllUsersTab(),
                _buildPaidUsersTab(),
                _buildUnpaidUsersTab(),
                const TrainerManagementTab(),
                _buildReviewsTab(),
                _buildRecipesTab(),
                const AdminChatTab(),
              ],
            ),
    );
  }
  
  Widget _buildAllUsersTab() {
    if (_allUsers.isEmpty) {
      return const Center(child: Text('No users found'));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _allUsers.length,
      itemBuilder: (context, index) {
        final user = _allUsers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: user['payment_status'] ? Colors.green : Colors.orange,
              child: Text(
                user['name'][0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(user['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['email']),
                if (user['mobile'] != null) Text('Mobile: ${user['mobile']}'),
                if (user['goal'] != null) 
                  Text('Goal: ${user['goal'].toString().replaceAll('_', ' ').toUpperCase()}'),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: user['payment_status'] ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user['payment_status'] ? 'PAID' : 'UNPAID',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
                if (user['payment_amount'] != null && user['payment_amount'] > 0)
                  Text('₹${user['payment_amount']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildPaidUsersTab() {
    if (_paidUsers.isEmpty) {
      return const Center(child: Text('No paid users found'));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _paidUsers.length,
      itemBuilder: (context, index) {
        final user = _paidUsers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green,
              child: Text(
                user['name'][0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(user['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${user['email']} • ₹${user['payment_amount']}'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Mobile', user['mobile']),
                    _buildDetailRow('Age', '${user['age']} years'),
                    _buildDetailRow('Gender', user['gender'].toString().toUpperCase()),
                    _buildDetailRow('Goal', user['goal'].toString().replaceAll('_', ' ').toUpperCase()),
                    _buildDetailRow('Current Weight', '${user['current_weight']} kg'),
                    _buildDetailRow('Target Weight', '${user['target_weight']} kg'),
                    _buildDetailRow('Duration', '${user['target_months']} months'),
                    _buildDetailRow('Workout Time', user['workout_time'] == 'morning' ? 'Morning' : 'Evening'),
                    _buildDetailRow('Diet', user['diet_preference'].toString().replaceAll('_', ' ').toUpperCase()),
                    _buildDetailRow('Food Allergies', user['food_allergies'] ?? 'None'),
                    _buildDetailRow('Health Conditions', user['health_conditions'] ?? 'None'),
                    _buildDetailRow('Payment Method', user['payment_method'] ?? 'Not Recorded'),
                    _buildDetailRow('Subscription Ends', _formatDate(user['subscription_end_date'])),
                    _buildDetailRow('Remaining Days', user['remaining_days']?.toString()),
                    _buildTrainerDetailRow(user['assigned_trainer']),
                    _buildDetailRow('Payment Date', _formatDateTime(user['payment_date'])),
                    const SizedBox(height: 12),
                    const Text(
                      'Renewal History',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    _buildRenewalsSection(user['renewals']),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildUnpaidUsersTab() {
    if (_unpaidUsers.isEmpty) {
      return const Center(child: Text('No unpaid users found'));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _unpaidUsers.length,
      itemBuilder: (context, index) {
        final user = _unpaidUsers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange,
              child: Text(
                user['name'][0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(user['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['email']),
                if (user['mobile'] != null) Text('Mobile: ${user['mobile']}'),
                if (user['goal'] != null)
                  Text('Goal: ${user['goal'].toString().replaceAll('_', ' ').toUpperCase()}'),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                if (user['payment_amount'] != null)
                  Text('₹${user['payment_amount']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRenewalsSection(List<dynamic>? renewals) {
    if (renewals == null || renewals.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text('No renewals recorded', style: TextStyle(color: Colors.grey[700])),
      );
    }
    return Column(
      children: renewals.map((r) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Row(
            children: [
              Expanded(child: Text('Date: ${r['renewed_at']}')),
              Expanded(child: Text('Months: ${r['months']}')),
              Expanded(child: Text('Amount: ₹${r['amount']}')),
              Expanded(child: Text('Method: ${r['payment_method']}')),
            ],
          ),
        );
      }).toList(),
    );
  }

  String? _formatDate(dynamic value) {
    if (value == null) return null;
    try {
      final parsed = DateTime.parse(value.toString());
      return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return value.toString();
    }
  }

  String? _formatDateTime(dynamic value) {
    if (value == null) return null;
    try {
      final parsed = DateTime.parse(value.toString());
      final date = '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
      final time = '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
      return '$date $time';
    } catch (_) {
      return value.toString();
    }
  }
  
  Widget _buildTrainerDetailRow(dynamic trainer) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 140,
                child: Text(
                  'Assigned Trainer:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  trainer != null ? trainer['name'] : 'Not Assigned',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (trainer != null) ...[
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.only(left: 140),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTrainerDetail('Email', trainer['email']),
                  _buildTrainerDetail('Mobile', trainer['mobile']),
                  _buildTrainerDetail('Gender', trainer['gender'].toString().toUpperCase()),
                  _buildTrainerDetail('Experience', '${trainer['experience']} years'),
                  _buildTrainerDetail('Specialization', trainer['specialization']),
                  _buildTrainerDetail('Certification', trainer['certification']),
                  if (trainer['goal_category'] != null)
                    _buildTrainerDetail('Assigned Category', 
                      trainer['goal_category'].toString().replaceAll('_', ' ').toUpperCase()),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildReviewsTab() {
    if (_allReviews.isEmpty) {
      return const Center(child: Text('No reviews yet'));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _allReviews.length,
      itemBuilder: (context, index) {
        final review = _allReviews[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person, size: 16, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text(
                                review['user_name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            review['user_email'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < review['rating'] ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 20,
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.fitness_center, size: 16, color: Color(0xFF7B4EFF)),
                      const SizedBox(width: 4),
                      const Text(
                        'Trainer: ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        review['trainer_name'],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7B4EFF),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  review['review_text'],
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    review['created_at'],
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildTrainerDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _loadAllRecipes() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/recipes/all/'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _allRecipes = List<Map<String, dynamic>>.from(data['recipes']);
            _filteredRecipes = _allRecipes;
            _updateRecipeCounts();
          });
        }
      }
    } catch (e) {
      print('Error loading recipes: $e');
    }
  }

  void _updateRecipeCounts() {
    _recipeCounts = {
      'veg': _allRecipes.where((r) => r['food_type'] == 'veg').length,
      'non_veg': _allRecipes.where((r) => r['food_type'] == 'non_veg').length,
      'vegan': _allRecipes.where((r) => r['food_type'] == 'vegan').length,
      'other': _allRecipes.where((r) => r['food_type'] == 'other').length,
    };
  }

  void _filterRecipes() {
    setState(() {
      _filteredRecipes = _allRecipes.where((recipe) {
        final matchesSearch = recipe['name']
            .toString()
            .toLowerCase()
            .contains(_recipeSearchQuery.toLowerCase());
        final matchesType = _selectedFoodTypeFilter == 'all' ||
            recipe['food_type'] == _selectedFoodTypeFilter;
        return matchesSearch && matchesType;
      }).toList();
    });
  }

  Future<void> _deleteRecipe(int recipeId, String recipeName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recipe?'),
        content: Text('Are you sure you want to delete "$recipeName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await http.delete(
          Uri.parse('http://127.0.0.1:8000/api/recipes/$recipeId/delete/'),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$recipeName deleted successfully')),
          );
          _loadAllRecipes();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting recipe: $e')),
        );
      }
    }
  }
  
  Widget _buildRecipesTab() {
    final foodTypeColors = {
      'veg': Colors.green,
      'non_veg': Colors.red,
      'vegan': Colors.orange,
      'other': Colors.blue,
    };

    return Column(
      children: [
        // Add Recipe Button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddRecipeScreen(),
                ),
              );
              if (result == true) {
                _loadAllRecipes();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add New Recipe'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B4EFF),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),

        // Recipe Count Cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCountCard('Veg', _recipeCounts['veg'] ?? 0, Colors.green),
                const SizedBox(width: 12),
                _buildCountCard(
                    'Non-Veg', _recipeCounts['non_veg'] ?? 0, Colors.red),
                const SizedBox(width: 12),
                _buildCountCard('Vegan', _recipeCounts['vegan'] ?? 0, Colors.orange),
                const SizedBox(width: 12),
                _buildCountCard('Other', _recipeCounts['other'] ?? 0, Colors.blue),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: TextField(
            onChanged: (value) {
              _recipeSearchQuery = value;
              _filterRecipes();
            },
            decoration: InputDecoration(
              hintText: 'Search recipes...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Food Type Filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Veg', 'veg'),
                const SizedBox(width: 8),
                _buildFilterChip('Non-Veg', 'non_veg'),
                const SizedBox(width: 8),
                _buildFilterChip('Vegan', 'vegan'),
                const SizedBox(width: 8),
                _buildFilterChip('Other', 'other'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Recipes List
        Expanded(
          child: _filteredRecipes.isEmpty
              ? Center(
                  child: Text(_allRecipes.isEmpty
                      ? 'No recipes added yet'
                      : 'No recipes match your search'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredRecipes.length,
                  itemBuilder: (context, index) {
                    final recipe = _filteredRecipes[index];
                    final foodType = recipe['food_type'] ?? 'unknown';
                    final color = foodTypeColors[foodType] ?? Colors.grey;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        title: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                              margin: const EdgeInsets.only(right: 12),
                            ),
                            Expanded(
                              child: Text(
                                recipe['name'] ?? 'Unnamed Recipe',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          foodType.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ingredients:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  recipe['ingredients'] ?? 'N/A',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Instructions:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  recipe['instructions'] ?? 'N/A',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Created: ${recipe['created_at']?.split('T')[0] ?? 'N/A'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Edit and Delete Buttons
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                EditRecipeScreen(
                                              recipeId: recipe['id'],
                                              initialName: recipe['name'],
                                              initialIngredients:
                                                  recipe['ingredients'],
                                              initialInstructions:
                                                  recipe['instructions'],
                                              initialFoodType: recipe['food_type'],
                                            ),
                                          ),
                                        );
                                        if (result == true) {
                                          _loadAllRecipes();
                                        }
                                      },
                                      icon: const Icon(Icons.edit, size: 16),
                                      label: const Text('Edit'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: () => _deleteRecipe(
                                        recipe['id'],
                                        recipe['name'],
                                      ),
                                      icon: const Icon(Icons.delete, size: 16),
                                      label: const Text('Delete'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCountCard(String label, int count, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: _selectedFoodTypeFilter == value,
      onSelected: (selected) {
        setState(() {
          _selectedFoodTypeFilter = value;
          _filterRecipes();
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: const Color(0xFF7B4EFF),
      labelStyle: TextStyle(
        color: _selectedFoodTypeFilter == value ? Colors.white : Colors.black,
      ),
    );
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
