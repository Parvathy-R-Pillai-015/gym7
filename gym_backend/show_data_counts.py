import os, django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'gym_backend.settings')
django.setup()

from users.models import UserLogin, UserProfile, Attendance, Review, UserDietPlan, WorkoutVideo, ChatMessage, FoodEntry, FoodRecipe, Trainer

print('=' * 60)
print('MySQL DATABASE: db_gym - DATA COUNTS')
print('=' * 60)
print()

# User related
user_count = UserLogin.objects.count()
profile_count = UserProfile.objects.count()
trainers = UserLogin.objects.filter(role='trainer').count()
regular_users = UserLogin.objects.filter(role='user').count()
print(f'👤 Users (UserLogin): {user_count}')
print(f'   - Trainers: {trainers}')
print(f'   - Regular Users: {regular_users}')
print(f'📋 User Profiles: {profile_count}')
print()

# Payment Status
paid_users = UserProfile.objects.filter(payment_status=True).count()
unpaid_users = UserProfile.objects.filter(payment_status=False).count()
print(f'💳 Payment Status:')
print(f'   - Paid Users: {paid_users}')
print(f'   - Unpaid Users: {unpaid_users}')
print()

# Attendance
attendance_count = Attendance.objects.count()
pending_attendance = Attendance.objects.filter(status='pending').count()
accepted_attendance = Attendance.objects.filter(status='accepted').count()
print(f'📅 Total Attendance Records: {attendance_count}')
print(f'   - Pending: {pending_attendance}')
print(f'   - Accepted: {accepted_attendance}')
print()

# Diet Plans
diet_plan_count = UserDietPlan.objects.count()
print(f'🍽️  User Diet Plans: {diet_plan_count}')
print()

# Food Entries
food_entry_count = FoodEntry.objects.count()
print(f'🍕 Food Calorie Entries: {food_entry_count}')
print()

# Recipes
recipe_count = FoodRecipe.objects.count()
veg_recipes = FoodRecipe.objects.filter(food_type='veg').count()
nonveg_recipes = FoodRecipe.objects.filter(food_type='non_veg').count()
vegan_recipes = FoodRecipe.objects.filter(food_type='vegan').count()
other_recipes = FoodRecipe.objects.filter(food_type='other').count()
print(f'🍳 Food Recipes: {recipe_count}')
print(f'   - Vegetarian: {veg_recipes}')
print(f'   - Non-Vegetarian: {nonveg_recipes}')
print(f'   - Vegan: {vegan_recipes}')
print(f'   - Other: {other_recipes}')
print()

# Videos
video_count = WorkoutVideo.objects.count()
print(f'🎥 Workout Videos: {video_count}')
print()

# Reviews
review_count = Review.objects.count()
print(f'⭐ Reviews: {review_count}')
print()

# Chat Messages
chat_count = ChatMessage.objects.count()
print(f'💬 Chat Messages: {chat_count}')
print()

print('=' * 60)
total = user_count + profile_count + attendance_count + diet_plan_count + food_entry_count + recipe_count + video_count + review_count + chat_count
print(f'✅ TOTAL RECORDS IN MySQL db_gym: {total}')
print('=' * 60)
