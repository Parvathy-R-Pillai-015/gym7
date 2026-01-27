"""
URL configuration for gym_backend project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/4.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path
from django.conf import settings
from django.conf.urls.static import static
from users import views, admin_views, food_views, trainer_food_views, subscription_views, recipe_views

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/users/create/', views.create_user, name='create_user'),
    path('api/users/login/', views.login_user, name='login_user'),
    path('api/trainers/create/', views.create_trainer, name='create_trainer'),
    path('api/profile/create/', views.create_profile, name='create_profile'),
    path('api/profile/<int:user_id>/', views.get_profile, name='get_profile'),
    path('api/payment/update/', views.update_payment_status, name='update_payment_status'),
    
    # Trainer APIs
    path('api/trainer/<int:trainer_id>/users/', views.get_trainer_users, name='get_trainer_users'),
    path('api/trainer/<int:trainer_id>/attendance/pending/', views.get_pending_attendance_requests, name='get_pending_attendance_requests'),
    path('api/trainers/<int:trainer_id>/', views.get_trainer_details, name='get_trainer_details'),
    
    # Attendance APIs
    path('api/attendance/request/', views.request_attendance, name='request_attendance'),
    path('api/attendance/accept/', views.accept_attendance, name='accept_attendance'),
    path('api/attendance/user/<int:user_id>/', views.get_user_attendance, name='get_user_attendance'),
    
    # Review APIs
    path('api/review/create/', views.create_review, name='create_review'),
    path('api/reviews/trainer/<int:trainer_id>/', views.get_trainer_reviews, name='get_trainer_reviews'),
    path('api/reviews/all/', views.get_all_reviews, name='get_all_reviews'),
    
    # Diet Plan APIs
    path('api/diet/foods/', views.get_food_items, name='get_food_items'),
    path('api/diet/templates/', views.get_diet_templates, name='get_diet_templates'),
    path('api/diet/calculate/<int:user_id>/', views.calculate_target_calories, name='calculate_target_calories'),
    path('api/diet/plan/create/', views.create_user_diet_plan, name='create_user_diet_plan'),
    path('api/diet/plan/user/<int:user_id>/', views.get_user_diet_plan, name='get_user_diet_plan'),
    path('api/diet/plans/trainer/<int:trainer_id>/', views.get_trainer_diet_plans, name='get_trainer_diet_plans'),
    
    # Video APIs
    path('api/videos/upload/', views.upload_video, name='upload_video'),
    path('api/videos/trainer/<int:trainer_id>/', views.list_trainer_videos, name='list_trainer_videos'),
    path('api/videos/user/<int:user_id>/', views.get_user_videos, name='get_user_videos'),
    path('api/videos/<int:video_id>/delete/', views.delete_video, name='delete_video'),
    path('api/videos/recommend/', views.recommend_video_to_user, name='recommend_video_to_user'),
    
    # Chat APIs
    path('api/chat/send/', views.send_chat_message, name='send_chat_message'),
    path('api/chat/messages/<int:user_id>/<int:trainer_id>/', views.get_chat_messages, name='get_chat_messages'),
    path('api/chat/trainer/<int:trainer_id>/', views.get_trainer_chats, name='get_trainer_chats'),
    path('api/chat/admin/all/', views.get_all_chats_admin, name='get_all_chats_admin'),
    
    # Food Calorie Tracker APIs
    path('api/food/search/', food_views.search_foods, name='search_foods'),
    path('api/food/categories/', food_views.get_food_categories, name='get_food_categories'),
    path('api/food/entry/add/', food_views.add_food_entry, name='add_food_entry'),
    path('api/food/entries/daily/', food_views.get_daily_food_entries, name='get_daily_food_entries'),
    path('api/food/entries/history/', food_views.get_food_history, name='get_food_history'),
    path('api/food/entry/delete/', food_views.delete_food_entry, name='delete_food_entry'),
    
    # Trainer Food Calorie Tracker APIs
    path('api/trainer/food/users/calories/', trainer_food_views.trainer_get_assigned_users_calories, name='trainer_get_assigned_users_calories'),
    path('api/trainer/food/user/daily/', trainer_food_views.trainer_get_user_daily_calories, name='trainer_get_user_daily_calories'),
    path('api/trainer/food/user/history/', trainer_food_views.trainer_get_user_calorie_history, name='trainer_get_user_calorie_history'),
    
    # Subscription APIs
    path('api/subscription/status/<int:user_id>/', subscription_views.get_subscription_status, name='get_subscription_status'),
    path('api/subscription/renew/', subscription_views.renew_subscription, name='renew_subscription'),
    
    # Admin APIs
    path('api/admin/users/all/', admin_views.get_all_users, name='get_all_users'),
    path('api/admin/users/paid/', admin_views.get_paid_users, name='get_paid_users'),
    path('api/admin/users/unpaid/', admin_views.get_unpaid_users, name='get_unpaid_users'),
    
    # Recipe APIs
    path('api/recipes/add/', recipe_views.add_recipe, name='add_recipe'),
    path('api/recipes/user/<int:user_id>/', recipe_views.get_recipes, name='get_recipes'),
    path('api/recipes/all/', recipe_views.get_all_recipes, name='get_all_recipes'),
    path('api/recipes/count/', recipe_views.get_recipe_count, name='get_recipe_count'),
    path('api/recipes/<int:recipe_id>/update/', recipe_views.update_recipe, name='update_recipe'),
    path('api/recipes/<int:recipe_id>/delete/', recipe_views.delete_recipe, name='delete_recipe'),
    
    # Trainer management - specific paths before generic patterns
    path('api/admin/trainers/create/', admin_views.create_trainer, name='admin_create_trainer'),
    path('api/admin/trainers/assign/', admin_views.assign_trainer_to_goal, name='assign_trainer_to_goal'),
    path('api/admin/trainers/remove/', admin_views.remove_trainer_from_goal, name='remove_trainer_from_goal'),
    path('api/admin/trainers/', admin_views.get_all_trainers, name='get_all_trainers'),
    path('api/admin/trainers/<str:goal>/', admin_views.get_trainers_by_goal, name='get_trainers_by_goal'),
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

