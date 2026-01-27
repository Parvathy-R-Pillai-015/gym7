from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.utils import timezone
import json
from .models import FoodRecipe, UserLogin, UserProfile


@csrf_exempt
def add_recipe(request):
    """Admin endpoint to add food recipes"""
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            
            name = data.get('name')
            ingredients = data.get('ingredients')
            instructions = data.get('instructions')
            food_type = data.get('food_type')  # veg, non_veg, vegan, other
            admin_id = data.get('admin_id')  # Optional: who created it
            
            if not all([name, ingredients, instructions, food_type]):
                return JsonResponse({
                    'success': False,
                    'message': 'name, ingredients, instructions, and food_type are required'
                }, status=400)
            
            if food_type not in ['veg', 'non_veg', 'vegan', 'other']:
                return JsonResponse({
                    'success': False,
                    'message': 'Invalid food_type. Must be veg, non_veg, vegan, or other'
                }, status=400)
            
            created_by = None
            if admin_id:
                try:
                    created_by = UserLogin.objects.get(id=admin_id)
                except UserLogin.DoesNotExist:
                    pass
            
            recipe = FoodRecipe.objects.create(
                name=name,
                ingredients=ingredients,
                instructions=instructions,
                food_type=food_type,
                created_by=created_by
            )
            
            return JsonResponse({
                'success': True,
                'message': 'Recipe added successfully',
                'recipe': {
                    'id': recipe.id,
                    'name': recipe.name,
                    'food_type': recipe.food_type,
                    'created_at': timezone.localtime(recipe.created_at).strftime('%Y-%m-%d')
                }
            }, status=201)
            
        except Exception as e:
            return JsonResponse({
                'success': False,
                'message': str(e)
            }, status=500)
    
    return JsonResponse({
        'success': False,
        'message': 'Only POST method is allowed'
    }, status=405)


@csrf_exempt
def get_recipes(request, user_id):
    """Get recipes filtered by user's diet preference"""
    if request.method == 'GET':
        try:
            user = UserLogin.objects.get(id=user_id)
            profile = UserProfile.objects.get(user=user)
            
            diet_preference = profile.diet_preference  # veg, non_veg, vegan, others
            
            # Filter recipes based on EXACT diet preference match
            # Vegetarian user -> only Veg recipes
            # Non-Veg user -> only Non-Veg recipes
            # Vegan user -> only Vegan recipes
            # Others user -> only Other recipes
            
            if diet_preference == 'vegetarian':
                recipes = FoodRecipe.objects.filter(food_type='veg').order_by('-created_at')
            elif diet_preference == 'non_veg':
                recipes = FoodRecipe.objects.filter(food_type='non_veg').order_by('-created_at')
            elif diet_preference == 'vegan':
                recipes = FoodRecipe.objects.filter(food_type='vegan').order_by('-created_at')
            elif diet_preference == 'others':
                recipes = FoodRecipe.objects.filter(food_type='other').order_by('-created_at')
            else:
                recipes = FoodRecipe.objects.all().order_by('-created_at')
            
            recipe_list = [
                {
                    'id': r.id,
                    'name': r.name,
                    'ingredients': r.ingredients,
                    'instructions': r.instructions,
                    'food_type': r.food_type,
                    'created_at': timezone.localtime(r.created_at).strftime('%Y-%m-%d')
                }
                for r in recipes
            ]
            
            return JsonResponse({
                'success': True,
                'user_diet': diet_preference,
                'recipes': recipe_list,
                'total': len(recipe_list)
            }, status=200)
            
        except UserLogin.DoesNotExist:
            return JsonResponse({
                'success': False,
                'message': 'User not found'
            }, status=404)
        except UserProfile.DoesNotExist:
            return JsonResponse({
                'success': False,
                'message': 'User profile not found'
            }, status=404)
        except Exception as e:
            return JsonResponse({
                'success': False,
                'message': str(e)
            }, status=500)
    
    return JsonResponse({
        'success': False,
        'message': 'Only GET method is allowed'
    }, status=405)


@csrf_exempt
def get_all_recipes(request):
    """Get all recipes (for admin or public listing)"""
    if request.method == 'GET':
        try:
            food_type = request.GET.get('food_type')  # Optional filter
            
            if food_type:
                recipes = FoodRecipe.objects.filter(food_type=food_type).order_by('-created_at')
            else:
                recipes = FoodRecipe.objects.all().order_by('-created_at')
            
            recipe_list = [
                {
                    'id': r.id,
                    'name': r.name,
                    'ingredients': r.ingredients,
                    'instructions': r.instructions,
                    'food_type': r.food_type,
                    'created_at': timezone.localtime(r.created_at).strftime('%Y-%m-%d')
                }
                for r in recipes
            ]
            
            return JsonResponse({
                'success': True,
                'recipes': recipe_list,
                'total': len(recipe_list)
            }, status=200)
            
        except Exception as e:
            return JsonResponse({
                'success': False,
                'message': str(e)
            }, status=500)
    
    return JsonResponse({
        'success': False,
        'message': 'Only GET method is allowed'
    }, status=405)


@csrf_exempt
def update_recipe(request, recipe_id):
    """Update an existing recipe"""
    if request.method == 'PUT':
        try:
            recipe = FoodRecipe.objects.get(id=recipe_id)
            data = json.loads(request.body)
            
            # Update fields if provided
            if 'name' in data:
                recipe.name = data['name']
            if 'ingredients' in data:
                recipe.ingredients = data['ingredients']
            if 'instructions' in data:
                recipe.instructions = data['instructions']
            if 'food_type' in data:
                if data['food_type'] not in ['veg', 'non_veg', 'vegan', 'other']:
                    return JsonResponse({
                        'success': False,
                        'message': 'Invalid food_type. Must be veg, non_veg, vegan, or other'
                    }, status=400)
                recipe.food_type = data['food_type']
            
            recipe.save()
            
            return JsonResponse({
                'success': True,
                'message': 'Recipe updated successfully',
                'recipe': {
                    'id': recipe.id,
                    'name': recipe.name,
                    'ingredients': recipe.ingredients,
                    'instructions': recipe.instructions,
                    'food_type': recipe.food_type,
                    'created_at': timezone.localtime(recipe.created_at).strftime('%Y-%m-%d')
                }
            }, status=200)
            
        except FoodRecipe.DoesNotExist:
            return JsonResponse({
                'success': False,
                'message': 'Recipe not found'
            }, status=404)
        except Exception as e:
            return JsonResponse({
                'success': False,
                'message': str(e)
            }, status=500)
    
    return JsonResponse({
        'success': False,
        'message': 'Only PUT method is allowed'
    }, status=405)


@csrf_exempt
def delete_recipe(request, recipe_id):
    """Delete a recipe"""
    if request.method == 'DELETE':
        try:
            recipe = FoodRecipe.objects.get(id=recipe_id)
            recipe_name = recipe.name
            recipe.delete()
            
            return JsonResponse({
                'success': True,
                'message': f'Recipe "{recipe_name}" deleted successfully'
            }, status=200)
            
        except FoodRecipe.DoesNotExist:
            return JsonResponse({
                'success': False,
                'message': 'Recipe not found'
            }, status=404)
        except Exception as e:
            return JsonResponse({
                'success': False,
                'message': str(e)
            }, status=500)
    
    return JsonResponse({
        'success': False,
        'message': 'Only DELETE method is allowed'
    }, status=405)


@csrf_exempt
def get_recipe_count(request):
    """Get count of recipes by food type"""
    if request.method == 'GET':
        try:
            counts = {
                'veg': FoodRecipe.objects.filter(food_type='veg').count(),
                'non_veg': FoodRecipe.objects.filter(food_type='non_veg').count(),
                'vegan': FoodRecipe.objects.filter(food_type='vegan').count(),
                'other': FoodRecipe.objects.filter(food_type='other').count(),
            }
            total = sum(counts.values())
            
            return JsonResponse({
                'success': True,
                'counts': counts,
                'total': total
            }, status=200)
            
        except Exception as e:
            return JsonResponse({
                'success': False,
                'message': str(e)
            }, status=500)
    
    return JsonResponse({
        'success': False,
        'message': 'Only GET method is allowed'
    }, status=405)
