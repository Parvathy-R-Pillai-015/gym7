import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FoodRecipesScreen extends StatefulWidget {
  final int userId;

  const FoodRecipesScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<FoodRecipesScreen> createState() => _FoodRecipesScreenState();
}

class _FoodRecipesScreenState extends State<FoodRecipesScreen> {
  List<Map<String, dynamic>> _recipes = [];
  bool _isLoading = true;
  String _userDiet = '';

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/recipes/user/${widget.userId}/'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _recipes = List<Map<String, dynamic>>.from(data['recipes']);
            _userDiet = data['user_diet'] ?? 'unknown';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading recipes: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Healthy Food Recipes'),
        backgroundColor: const Color(0xFF7B4EFF),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recipes.isEmpty
              ? Center(
                  child: Text(
                    'No recipes available for your diet preference',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _recipes.length,
                  itemBuilder: (context, index) {
                    final recipe = _recipes[index];
                    return RecipeCard(recipe: recipe);
                  },
                ),
    );
  }
}

class RecipeCard extends StatefulWidget {
  final Map<String, dynamic> recipe;

  const RecipeCard({Key? key, required this.recipe}) : super(key: key);

  @override
  State<RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends State<RecipeCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final foodType = recipe['food_type'] as String;
    
    Color foodTypeColor;
    String foodTypeLabel;
    
    switch (foodType) {
      case 'veg':
        foodTypeColor = Colors.green;
        foodTypeLabel = 'Vegetarian';
        break;
      case 'non_veg':
        foodTypeColor = Colors.red;
        foodTypeLabel = 'Non-Vegetarian';
        break;
      case 'vegan':
        foodTypeColor = Colors.orange;
        foodTypeLabel = 'Vegan';
        break;
      default:
        foodTypeColor = Colors.blue;
        foodTypeLabel = 'Other';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with recipe name and food type
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  foodTypeColor.withOpacity(0.15),
                  foodTypeColor.withOpacity(0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        recipe['name'] ?? 'Unnamed Recipe',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: foodTypeColor.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: foodTypeColor,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        foodTypeLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: foodTypeColor.withOpacity(0.8),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Created: ${recipe['created_at']?.split('T')[0] ?? 'N/A'}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Expand/Collapse button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  setState(() => _isExpanded = !_isExpanded);
                },
                icon: Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: const Color(0xFF7B4EFF),
                  size: 24,
                ),
                label: Text(
                  _isExpanded ? 'Hide Details' : 'View Details',
                  style: const TextStyle(
                    color: Color(0xFF7B4EFF),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          // Expandable content
          if (_isExpanded) ...[
            Divider(height: 1, color: Colors.grey[300], thickness: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ingredients
                  Row(
                    children: [
                      Icon(
                        Icons.shopping_basket,
                        color: foodTypeColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Ingredients',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: foodTypeColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: foodTypeColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      recipe['ingredients'] ?? 'No ingredients listed',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                        height: 1.7,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Instructions
                  Row(
                    children: [
                      Icon(
                        Icons.description,
                        color: foodTypeColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Instructions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: foodTypeColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: foodTypeColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      recipe['instructions'] ?? 'No instructions provided',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                        height: 1.7,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
