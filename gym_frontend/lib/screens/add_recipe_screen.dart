import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({Key? key}) : super(key: key);

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ingredientsController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  String _selectedFoodType = 'veg';
  bool _isAdding = false;

  final List<Map<String, String>> _foodTypes = [
    {'value': 'veg', 'label': 'Vegetarian'},
    {'value': 'non_veg', 'label': 'Non-Vegetarian'},
    {'value': 'vegan', 'label': 'Vegan'},
    {'value': 'other', 'label': 'Other'},
  ];

  Future<void> _addRecipe() async {
    if (_nameController.text.isEmpty ||
        _ingredientsController.text.isEmpty ||
        _instructionsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isAdding = true);

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/recipes/add/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': _nameController.text,
          'ingredients': _ingredientsController.text,
          'instructions': _instructionsController.text,
          'food_type': _selectedFoodType,
        }),
      );

      setState(() => _isAdding = false);

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Recipe "${data['recipe']['name']}" added successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _nameController.clear();
          _ingredientsController.clear();
          _instructionsController.clear();
          setState(() => _selectedFoodType = 'veg');
        }
      } else {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Failed to add recipe'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isAdding = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Food Recipe'),
        backgroundColor: const Color(0xFF7B4EFF),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
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
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add New Recipe',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Create a healthy recipe for users',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // Recipe Name
            const Text(
              'Recipe Name',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g., Quinoa Buddha Bowl',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.restaurant),
              ),
            ),
            const SizedBox(height: 20),
            // Food Type
            const Text(
              'Food Type',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedFoodType,
              items: _foodTypes
                  .map((type) => DropdownMenuItem(
                        value: type['value'],
                        child: Text(type['label']!),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedFoodType = value ?? 'veg');
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.category),
              ),
            ),
            const SizedBox(height: 20),
            // Ingredients
            const Text(
              'Ingredients',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ingredientsController,
              minLines: 4,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: 'List ingredients (one per line or comma-separated)\ne.g.:\n- 1 cup quinoa\n- 2 cups water\n- Salt to taste',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.list),
              ),
            ),
            const SizedBox(height: 20),
            // Instructions
            const Text(
              'Instructions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _instructionsController,
              minLines: 4,
              maxLines: 10,
              decoration: InputDecoration(
                hintText: 'Step-by-step instructions\ne.g.:\n1. Rinse quinoa under cold water\n2. Cook in boiling water for 15 minutes\n3. Let cool and serve',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 30),
            // Add Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isAdding ? null : _addRecipe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B4EFF),
                  disabledBackgroundColor: Colors.grey[400],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isAdding
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Add Recipe',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ingredientsController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }
}
