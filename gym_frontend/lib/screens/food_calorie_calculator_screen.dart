import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class FoodCalorieCalculatorScreen extends StatefulWidget {
  final int userId;
  final String userName;

  const FoodCalorieCalculatorScreen({
    Key? key,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  State<FoodCalorieCalculatorScreen> createState() =>
      _FoodCalorieCalculatorScreenState();
}

class _FoodCalorieCalculatorScreenState
    extends State<FoodCalorieCalculatorScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _dailyEntries = [];
  Map<String, dynamic>? _dailySummary;
  bool _isLoading = false;
  String _selectedMealType = 'breakfast';
  List<Map<String, dynamic>> _foodSearchResults = [];
  bool _isSearching = false;
  TextEditingController _foodSearchController = TextEditingController();
  TextEditingController _quantityController = TextEditingController();
  int? _selectedFoodId;
  String _selectedFoodName = '';
  String _selectedQuantityUnit = 'g';
  List<String> _quantityUnits = ['g', 'ml', 'piece', 'cup', 'bowl'];
  bool _showHistory = false;
  List<Map<String, dynamic>> _historyData = [];

  Map<String, dynamic>? _selectedFoodItem;
  double _userCalorieTarget = 0;
  TextEditingController _customCalorieController = TextEditingController();
  bool _isCustomFood = false;

  @override
  void initState() {
    super.initState();
    _loadDailyEntries();
  }

  Future<void> _loadDailyEntries() async {
    setState(() => _isLoading = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final response = await http.get(
        Uri.parse(
          'http://127.0.0.1:8000/api/food/entries/daily/?user_id=${widget.userId}&date=$dateStr',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _dailyEntries = List<Map<String, dynamic>>.from(data['entries'] ?? []);
            _dailySummary = data['daily_summary'];
            _userCalorieTarget =
                (_dailySummary?['calorie_target'] ?? 0).toDouble();
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading entries: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchFoods(String query) async {
    if (query.isEmpty) {
      setState(() => _foodSearchResults = []);
      return;
    }

    setState(() => _isSearching = true);
    try {
      final response = await http.get(
        Uri.parse(
          'http://127.0.0.1:8000/api/food/search/?query=$query&limit=20',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final results = List<Map<String, dynamic>>.from(data['foods'] ?? []);
          setState(() {
            _foodSearchResults = results;
            // Auto-enable custom mode if no results found; reset when results exist
            _isCustomFood = results.isEmpty && query.isNotEmpty;
          });
        }
      }
    } catch (e) {
      print('Error searching foods: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _addFoodEntry() async {
    // Validate input
    if (_quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter quantity')),
      );
      return;
    }

    final quantity = double.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity')),
      );
      return;
    }

    // For custom food, need food name
    if (_isCustomFood) {
      if (_foodSearchController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter food name')),
        );
        return;
      }
    } else {
      // For database food, need selected food
      if (_selectedFoodId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a food item')),
        );
        return;
      }
    }

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      
      // Build request body
      Map<String, dynamic> requestBody = {
        'user_id': widget.userId,
        'quantity': quantity,
        'quantity_unit': _selectedQuantityUnit,
        'meal_type': _selectedMealType,
        'entry_date': dateStr,
      };

      // Add food_item_id for database foods or custom food details
      if (_isCustomFood) {
        requestBody['food_name'] = _foodSearchController.text;
        requestBody['custom_calories'] = 200.0; // Default 200 calories for custom foods
      } else {
        requestBody['food_item_id'] = _selectedFoodId;
      }

      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/food/entry/add/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isCustomFood
                    ? 'Custom food added (200 cal default). Calories calculated automatically.'
                    : 'Food entry added successfully',
              ),
            ),
          );
          _quantityController.clear();
          _customCalorieController.clear();
          _foodSearchController.clear();
          _selectedFoodId = null;
          _selectedFoodName = '';
          _foodSearchResults = [];
          _isCustomFood = false;
          _loadDailyEntries();
        }
      } else {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to add entry')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding entry: $e')),
      );
    }
  }

  Future<void> _deleteFoodEntry(int entryId) async {
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/food/entry/delete/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.userId,
          'entry_id': entryId,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry deleted')),
        );
        _loadDailyEntries();
      }
    } catch (e) {
      print('Error deleting entry: $e');
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(
          'http://127.0.0.1:8000/api/food/entries/history/?user_id=${widget.userId}&days=30',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _historyData =
                List<Map<String, dynamic>>.from(data['daily_history'] ?? []);
          });
        }
      }
    } catch (e) {
      print('Error loading history: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Food Calorie Calculator'),
          backgroundColor: const Color(0xFF7B4EFF),
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Today'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: _isLoading && _dailyEntries.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  // TODAY TAB
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildDateSelector(),
                        _buildDailySummary(),
                        _buildAddFoodSection(),
                        _buildDailyEntriesList(),
                      ],
                    ),
                  ),
                  // HISTORY TAB
                  _buildHistoryTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF7B4EFF).withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                _loadDailyEntries();
              });
            },
          ),
          GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() {
                  _selectedDate = date;
                  _loadDailyEntries();
                });
              }
            },
            child: Text(
              DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _selectedDate.isBefore(DateTime.now())
                ? () {
                    setState(() {
                      _selectedDate =
                          _selectedDate.add(const Duration(days: 1));
                      _loadDailyEntries();
                    });
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDailySummary() {
    if (_dailySummary == null) return const SizedBox.shrink();

    final totalCalories = _dailySummary?['total_calories'] ?? 0;
    final target = _dailySummary?['calorie_target'] ?? 0;
    final remaining = _dailySummary?['remaining_calories'] ?? 0;
    final percentage = target > 0 ? (totalCalories / target) * 100 : 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7B4EFF),
            const Color(0xFFBB86FC),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          const Text(
            'Daily Calorie Summary',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryBox('Total', '${totalCalories.toStringAsFixed(0)} cal'),
              _buildSummaryBox('Target', '${target.toStringAsFixed(0)} cal'),
              _buildSummaryBox(
                'Remaining',
                '${remaining.toStringAsFixed(0)} cal',
              ),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage > 100 ? 1 : percentage / 100,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                percentage > 100 ? Colors.red : Colors.green,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${percentage.toStringAsFixed(1)}% of daily target',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBox(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAddFoodSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Food Entry',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          // Meal Type Selection
          DropdownButton<String>(
            value: _selectedMealType,
            isExpanded: true,
            items: ['breakfast', 'lunch', 'dinner', 'snacks', 'fruits', 'nuts', 'milks']
                .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e.replaceFirst(e[0], e[0].toUpperCase())),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() => _selectedMealType = value ?? 'breakfast');
            },
          ),
          const SizedBox(height: 15),
          // Food Search
          TextField(
            controller: _foodSearchController,
            decoration: InputDecoration(
              hintText: 'Search food items...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: _searchFoods,
          ),
          if (_foodSearchResults.isNotEmpty)
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: _foodSearchResults.length,
                itemBuilder: (context, index) {
                  final food = _foodSearchResults[index];
                  return ListTile(
                    title: Text(food['name']),
                    subtitle: Text(
                      '${food['calories_per_100g']} cal/100g',
                    ),
                    onTap: () {
                      setState(() {
                        _selectedFoodId = food['id'];
                        _selectedFoodName = food['name'];
                        _selectedFoodItem = food;
                        _isCustomFood = false;
                        _foodSearchController.clear();
                        _foodSearchResults = [];
                      });
                    },
                  );
                },
              ),
            ),
          if (_selectedFoodName.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF7B4EFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedFoodName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _selectedFoodId = null;
                        _selectedFoodName = '';
                        _selectedFoodItem = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          const SizedBox(height: 15),
          // Quantity Input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Quantity',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButton<String>(
                  value: _selectedQuantityUnit,
                  underline: const SizedBox(),
                  items: _quantityUnits
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedQuantityUnit = value ?? 'g');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          // Add Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B4EFF),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _addFoodEntry,
              child: const Text(
                'Add Food Entry',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyEntriesList() {
    if (_dailyEntries.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.restaurant,
                size: 50,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 10),
              Text(
                'No food entries for this day',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today\'s Entries',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _dailyEntries.length,
            itemBuilder: (context, index) {
              final entry = _dailyEntries[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7B4EFF).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.fastfood,
                      color: Color(0xFF7B4EFF),
                    ),
                  ),
                  title: Text(entry['food_name']),
                  subtitle: Text(
                    '${entry['quantity']}${entry['quantity_unit']} • ${entry['meal_type']}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${entry['calculated_calories'].toStringAsFixed(0)} cal',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7B4EFF),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteFoodEntry(entry['id']),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return FutureBuilder(
      future: _historyData.isEmpty ? _loadHistory() : Future.value(null),
      builder: (context, snapshot) {
        if (_historyData.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Statistics (Last 30 Days)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Add statistics display here if available
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daily History',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _historyData.length,
                      itemBuilder: (context, index) {
                        final day = _historyData[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ExpansionTile(
                            title: Text(day['date']),
                            subtitle: Text(
                              '${day['total_calories'].toStringAsFixed(0)} calories',
                            ),
                            children: [
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: day['entries'].length,
                                itemBuilder: (context, entryIndex) {
                                  final entry = day['entries'][entryIndex];
                                  return ListTile(
                                    title: Text(entry['food_name']),
                                    subtitle: Text(
                                      '${entry['quantity']}${entry['quantity_unit']} • ${entry['meal_type']}',
                                    ),
                                    trailing: Text(
                                      '${entry['calories'].toStringAsFixed(0)} cal',
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _foodSearchController.dispose();
    _quantityController.dispose();
    super.dispose();
  }
}
