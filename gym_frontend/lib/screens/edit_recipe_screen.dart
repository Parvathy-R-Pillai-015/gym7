import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditRecipeScreen extends StatefulWidget {
  final int recipeId;
  final String initialName;
  final String initialIngredients;
  final String initialInstructions;
  final String initialFoodType;

  const EditRecipeScreen({
    Key? key,
    required this.recipeId,
    required this.initialName,
    required this.initialIngredients,
    required this.initialInstructions,
    required this.initialFoodType,
  }) : super(key: key);

  @override
  _EditRecipeScreenState createState() => _EditRecipeScreenState();
}

class _EditRecipeScreenState extends State<EditRecipeScreen> {
  late TextEditingController _nameController;
  late TextEditingController _ingredientsController;
  late TextEditingController _instructionsController;
  late String _selectedFoodType;
  bool _isLoading = false;

  final List<String> foodTypes = ['veg', 'non_veg', 'vegan', 'other'];
  final Map<String, String> foodTypeLabels = {
    'veg': 'Vegetarian',
    'non_veg': 'Non-Vegetarian',
    'vegan': 'Vegan',
    'other': 'Other'
  };

  final Map<String, Color> foodTypeColors = {
    'veg': Colors.green,
    'non_veg': Colors.red,
    'vegan': Colors.orange,
    'other': Colors.blue,
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _ingredientsController =
        TextEditingController(text: widget.initialIngredients);
    _instructionsController =
        TextEditingController(text: widget.initialInstructions);
    _selectedFoodType = widget.initialFoodType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ingredientsController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _updateRecipe() async {
    if (_nameController.text.isEmpty ||
        _ingredientsController.text.isEmpty ||
        _instructionsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.put(
        Uri.parse(
            'http://127.0.0.1:8000/api/recipes/${widget.recipeId}/update/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': _nameController.text,
          'ingredients': _ingredientsController.text,
          'instructions': _instructionsController.text,
          'food_type': _selectedFoodType,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recipe updated successfully!')),
        );
        Navigator.pop(context, true);
      } else {
        final error = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${error['message']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Recipe'),
        backgroundColor: Colors.deepOrange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Name
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Recipe Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.restaurant),
              ),
            ),
            const SizedBox(height: 16),

            // Food Type Dropdown
            DropdownButtonFormField<String>(
              value: _selectedFoodType,
              decoration: InputDecoration(
                labelText: 'Food Type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.category),
              ),
              items: foodTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: foodTypeColors[type],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(foodTypeLabels[type]!),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedFoodType = value!);
              },
            ),
            const SizedBox(height: 16),

            // Ingredients
            TextField(
              controller: _ingredientsController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Ingredients',
                hintText: 'List ingredients separated by commas',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.shopping_basket),
              ),
            ),
            const SizedBox(height: 16),

            // Instructions
            TextField(
              controller: _instructionsController,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: 'Instructions',
                hintText: 'Step-by-step cooking instructions',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 24),

            // Update Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateRecipe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Update Recipe',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
