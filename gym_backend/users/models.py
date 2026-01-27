from django.db import models
from django.contrib.auth.hashers import make_password, check_password

# Create your models here.

class UserLogin(models.Model):
    """
    UserLogin model to store user registration data
    """
    name = models.CharField(max_length=255, verbose_name="Name")
    emailid = models.EmailField(unique=True, max_length=255, verbose_name="Email ID")
    password = models.CharField(max_length=255, verbose_name="Password")
    role = models.CharField(max_length=50, default='user', verbose_name="Role")
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="Created At")
    updated_at = models.DateTimeField(auto_now=True, verbose_name="Updated At")
    is_active = models.BooleanField(default=True, verbose_name="Is Active")
    
    class Meta:
        db_table = 'userlogin'
        verbose_name = 'User Login'
        verbose_name_plural = 'User Logins'
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.name} ({self.emailid})"
    
    def save(self, *args, **kwargs):
        # Hash password before saving if it's not already hashed
        if self.password and not self.password.startswith('pbkdf2_'):
            self.password = make_password(self.password)
        super().save(*args, **kwargs)
    
    def check_password(self, raw_password):
        """Check if the provided password matches the stored hashed password"""
        return check_password(raw_password, self.password)


class Trainer(models.Model):
    """
    Trainer model to store trainer-specific information
    """
    GOAL_CATEGORY_CHOICES = [
        ('weight_gain', 'Weight Gain'),
        ('weight_loss', 'Weight Loss'),
        ('muscle_gain', 'Muscle Gain'),
        ('others', 'Others'),
    ]
    
    user = models.OneToOneField(UserLogin, on_delete=models.CASCADE, related_name='trainer_profile')
    mobile = models.CharField(max_length=10, verbose_name="Mobile Number")
    gender = models.CharField(max_length=10, verbose_name="Gender")
    experience = models.IntegerField(verbose_name="Years of Experience")
    specialization = models.CharField(max_length=100, verbose_name="Specialization")
    certification = models.CharField(max_length=255, blank=True, null=True, verbose_name="Certification")
    goal_category = models.CharField(max_length=20, choices=GOAL_CATEGORY_CHOICES, blank=True, null=True, verbose_name="Assigned Goal Category")
    joining_period = models.CharField(max_length=50, verbose_name="Joining Period")
    is_active = models.BooleanField(default=True, verbose_name="Is Active")
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="Created At")
    
    class Meta:
        db_table = 'trainer'
        verbose_name = 'Trainer'
        verbose_name_plural = 'Trainers'
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.user.name} - {self.specialization}"


class UserProfile(models.Model):
    """
    UserProfile model to store user's fitness goals and personal information
    """
    GOAL_CHOICES = [
        ('weight_gain', 'Weight Gain'),
        ('weight_loss', 'Weight Loss'),
        ('muscle_gain', 'Muscle Gain'),
        ('others', 'Others'),
    ]
    
    MONTH_CHOICES = [
        (1, '1 Month'),
        (2, '2 Months'),
        (3, '3 Months'),
        (6, '6 Months'),
        (8, '8 Months'),
        (12, '1 Year'),
    ]
    
    WORKOUT_TIME_CHOICES = [
        ('morning', '4 AM to 11 AM'),
        ('evening', '4 PM to 11 PM'),
    ]
    
    DIET_CHOICES = [
        ('vegetarian', 'Vegetarian'),
        ('non_veg', 'Non-Vegetarian'),
        ('vegan', 'Vegan'),
        ('others', 'Others'),
    ]
    
    GENDER_CHOICES = [
        ('male', 'Male'),
        ('female', 'Female'),
        ('other', 'Other'),
    ]
    
    user = models.OneToOneField(UserLogin, on_delete=models.CASCADE, related_name='profile')
    mobile_number = models.CharField(max_length=10, verbose_name="Mobile Number", default='0000000000')
    age = models.IntegerField(verbose_name="Age")
    gender = models.CharField(max_length=10, choices=GENDER_CHOICES, verbose_name="Gender")
    current_weight = models.FloatField(verbose_name="Current Weight (kg)")
    current_height = models.FloatField(verbose_name="Current Height (cm)")
    goal = models.CharField(max_length=20, choices=GOAL_CHOICES, verbose_name="Goal")
    target_weight = models.FloatField(verbose_name="Target Weight (kg)")
    target_months = models.IntegerField(choices=MONTH_CHOICES, verbose_name="Target Months")
    workout_time = models.CharField(max_length=10, choices=WORKOUT_TIME_CHOICES, verbose_name="Workout Time")
    diet_preference = models.CharField(max_length=20, choices=DIET_CHOICES, verbose_name="Diet Preference")
    food_allergies = models.TextField(blank=True, null=True, verbose_name="Food Allergies")
    health_conditions = models.TextField(blank=True, null=True, verbose_name="Health Conditions")
    payment_status = models.BooleanField(default=False, verbose_name="Payment Status")
    payment_amount = models.IntegerField(default=0, verbose_name="Payment Amount")
    payment_method = models.CharField(max_length=20, blank=True, null=True, verbose_name="Payment Method")
    payment_date = models.DateTimeField(null=True, blank=True, verbose_name="Last Payment Date")
    subscription_start_date = models.DateTimeField(null=True, blank=True, verbose_name="Subscription Start Date")
    subscription_end_date = models.DateTimeField(null=True, blank=True, verbose_name="Subscription End Date")
    assigned_trainer = models.ForeignKey('Trainer', on_delete=models.SET_NULL, null=True, blank=True, related_name='assigned_users', verbose_name="Assigned Trainer")
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="Created At")
    updated_at = models.DateTimeField(auto_now=True, verbose_name="Updated At")
    
    class Meta:
        db_table = 'user_profile'
        verbose_name = 'User Profile'
        verbose_name_plural = 'User Profiles'
    
    def __str__(self):
        return f"Profile: {self.user.name}"
    
    def calculate_payment_amount(self):
        """Calculate payment amount based on target months"""
        payment_map = {
            1: 399,
            2: 499,
            3: 699,
            6: 1199,
            8: 1599,
            12: 2199,
        }
        return payment_map.get(self.target_months, 0)
    
    def get_remaining_days(self):
        """Calculate remaining days from subscription end date"""
        from django.utils import timezone
        if self.subscription_end_date:
            remaining = (self.subscription_end_date - timezone.now()).days
            return max(0, remaining)
        return 0
    
    def is_subscription_active(self):
        """Check if subscription is currently active"""
        from django.utils import timezone
        if self.subscription_end_date:
            return self.subscription_end_date > timezone.now()
        return False
    
    def calculate_target_calories(self):
        """
        Calculate personalized daily calorie target based on:
        - Current weight and target weight
        - Target timeline (months)
        - Safe weight change limits
        
        Returns: dict with target_calories and warnings
        """
        # Base Metabolic Rate (BMR) - calories needed at rest
        bmr = self.current_weight * 24
        
        # Calculate weight change needed
        weight_change = self.target_weight - self.current_weight
        
        # Calculate weeks available
        weeks = self.target_months * 4
        
        # Calculate weekly weight change rate
        weekly_change = weight_change / weeks if weeks > 0 else 0
        
        # Safety limits (medical recommendations)
        # Weight loss: max 0.5-1kg per week
        # Weight gain: max 0.5-1kg per week
        # Muscle gain: max 0.5kg per week
        max_safe_loss = -1.0  # kg per week
        min_safe_loss = -0.5  # kg per week
        max_safe_gain = 1.0   # kg per week
        min_safe_gain = 0.5   # kg per week
        
        warnings = []
        adjusted_weekly_change = weekly_change
        
        # Check if goals are realistic
        if weight_change < 0:  # Weight loss
            if weekly_change < max_safe_loss:
                warnings.append(f"Goal too aggressive! Losing {abs(weekly_change):.2f}kg/week is unsafe. Adjusted to 1kg/week max.")
                adjusted_weekly_change = max_safe_loss
            elif weekly_change > min_safe_loss:
                warnings.append(f"Very slow progress: {abs(weekly_change):.2f}kg/week. Consider shorter timeline.")
        elif weight_change > 0:  # Weight gain
            if weekly_change > max_safe_gain:
                warnings.append(f"Goal too aggressive! Gaining {weekly_change:.2f}kg/week is unhealthy. Adjusted to 1kg/week max.")
                adjusted_weekly_change = max_safe_gain
            elif weekly_change < min_safe_gain and self.goal == 'muscle_gain':
                warnings.append(f"Very slow progress for muscle gain: {weekly_change:.2f}kg/week.")
        
        # 1 kg of body weight = approximately 7700 calories
        # Daily calorie adjustment = (weekly_change × 7700) / 7
        daily_adjustment = (adjusted_weekly_change * 7700) / 7
        
        # Calculate target calories
        target_calories = bmr + daily_adjustment
        
        # Absolute minimum safe calories (prevent starvation)
        min_safe_calories = 1200 if self.gender == 'female' else 1500
        max_safe_calories = 4000  # Upper limit for safety
        
        if target_calories < min_safe_calories:
            warnings.append(f"Calculated {target_calories:.0f} cal/day is below safe minimum. Set to {min_safe_calories} cal/day.")
            target_calories = min_safe_calories
        elif target_calories > max_safe_calories:
            warnings.append(f"Calculated {target_calories:.0f} cal/day exceeds safe maximum. Set to {max_safe_calories} cal/day.")
            target_calories = max_safe_calories
        
        return {
            'target_calories': round(target_calories),
            'bmr': round(bmr),
            'weekly_change': round(adjusted_weekly_change, 2),
            'daily_adjustment': round(daily_adjustment),
            'warnings': warnings,
            'is_safe': len(warnings) == 0
        }


class Attendance(models.Model):
    """
    Attendance model to track user attendance requests and trainer approvals
    """
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('accepted', 'Accepted'),
        ('rejected', 'Rejected'),
    ]
    
    user = models.ForeignKey(UserLogin, on_delete=models.CASCADE, related_name='attendances', verbose_name="User")
    trainer = models.ForeignKey(Trainer, on_delete=models.CASCADE, related_name='user_attendances', verbose_name="Trainer")
    date = models.DateField(verbose_name="Attendance Date")
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='pending', verbose_name="Status")
    request_date = models.DateTimeField(auto_now_add=True, verbose_name="Request Date")
    accepted_date = models.DateTimeField(blank=True, null=True, verbose_name="Accepted Date")
    
    class Meta:
        db_table = 'attendance'
        verbose_name = 'Attendance'
        verbose_name_plural = 'Attendances'


class SubscriptionRenewal(models.Model):
    """Tracks subscription renewals for auditing"""
    user = models.ForeignKey(UserLogin, on_delete=models.CASCADE, related_name='subscription_renewals')
    months = models.IntegerField(verbose_name="Renewal Months")
    amount = models.IntegerField(verbose_name="Renewal Amount")
    payment_method = models.CharField(max_length=20, blank=True, null=True, verbose_name="Payment Method")
    renewed_at = models.DateTimeField(auto_now_add=True, verbose_name="Renewed At")

    class Meta:
        db_table = 'subscription_renewal'
        verbose_name = 'Subscription Renewal'
        verbose_name_plural = 'Subscription Renewals'
        ordering = ['-renewed_at']
    
    def __str__(self):
        return f"{self.user.name} - {self.months}m ₹{self.amount} on {self.renewed_at.strftime('%Y-%m-%d')}"


class FoodRecipe(models.Model):
    """Store healthy food recipes for users"""
    FOOD_TYPE_CHOICES = [
        ('veg', 'Vegetarian'),
        ('non_veg', 'Non-Vegetarian'),
        ('vegan', 'Vegan'),
        ('other', 'Other'),
    ]
    
    name = models.CharField(max_length=255, verbose_name="Recipe Name")
    ingredients = models.TextField(verbose_name="Ingredients (comma-separated or newline-separated)")
    instructions = models.TextField(verbose_name="Instructions")
    food_type = models.CharField(max_length=20, choices=FOOD_TYPE_CHOICES, verbose_name="Food Type")
    created_by = models.ForeignKey(UserLogin, on_delete=models.SET_NULL, null=True, blank=True, related_name='created_recipes', verbose_name="Created By")
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="Created At")
    
    class Meta:
        db_table = 'food_recipe'
        verbose_name = 'Food Recipe'
        verbose_name_plural = 'Food Recipes'
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.name} ({self.get_food_type_display()})"


class Review(models.Model):
    """
    Review model for users to rate and review their trainers
    """
    user = models.ForeignKey(UserLogin, on_delete=models.CASCADE, related_name='reviews', verbose_name="User")
    trainer = models.ForeignKey(Trainer, on_delete=models.CASCADE, related_name='trainer_reviews', verbose_name="Trainer")
    rating = models.IntegerField(choices=[(1, '1 Star'), (2, '2 Stars'), (3, '3 Stars'), (4, '4 Stars'), (5, '5 Stars')], verbose_name="Rating")
    review_text = models.TextField(verbose_name="Review")
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="Created At")
    updated_at = models.DateTimeField(auto_now=True, verbose_name="Updated At")
    
    class Meta:
        db_table = 'review'
        verbose_name = 'Review'
        verbose_name_plural = 'Reviews'
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.user.name} - {self.trainer.user.name} ({self.rating} stars)"


class FoodItem(models.Model):
    """
    Food items with nutritional information
    """
    FOOD_CATEGORIES = [
        ('dairy', 'Dairy'),
        ('seafood', 'Seafood'),
        ('nuts', 'Nuts'),
        ('eggs', 'Eggs'),
        ('grains', 'Grains'),
        ('vegetables', 'Vegetables'),
        ('fruits', 'Fruits'),
        ('meat', 'Meat'),
        ('legumes', 'Legumes'),
        ('other', 'Other'),
    ]
    
    DIET_TYPES = [
        ('vegan', 'Vegan'),           # No animal products at all
        ('vegetarian', 'Vegetarian'), # No meat/seafood, but eggs/dairy OK
        ('non_veg', 'Non-Vegetarian'), # All foods
    ]
    
    name = models.CharField(max_length=100, verbose_name="Food Name")
    food_category = models.CharField(max_length=20, choices=FOOD_CATEGORIES, verbose_name="Category")
    diet_type = models.CharField(max_length=20, choices=DIET_TYPES, default='vegan', verbose_name="Diet Type")
    calories = models.DecimalField(max_digits=6, decimal_places=2, verbose_name="Calories (per 100g)")
    protein = models.DecimalField(max_digits=5, decimal_places=2, verbose_name="Protein (g)")
    carbs = models.DecimalField(max_digits=5, decimal_places=2, verbose_name="Carbohydrates (g)")
    fats = models.DecimalField(max_digits=5, decimal_places=2, verbose_name="Fats (g)")
    serving_size = models.CharField(max_length=50, default="100g", verbose_name="Serving Size")
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="Created At")
    
    class Meta:
        db_table = 'food_item'
        verbose_name = 'Food Item'
        verbose_name_plural = 'Food Items'
        ordering = ['name']
    
    def __str__(self):
        return f"{self.name} ({self.food_category})"


class DietPlanTemplate(models.Model):
    """
    Pre-made diet plan templates for different goals and calorie ranges
    """
    GOAL_CHOICES = [
        ('weight_loss', 'Weight Loss'),
        ('weight_gain', 'Weight Gain'),
        ('muscle_building', 'Muscle Building'),
    ]
    
    name = models.CharField(max_length=100, verbose_name="Template Name")
    goal_type = models.CharField(max_length=20, choices=GOAL_CHOICES, verbose_name="Goal Type")
    calorie_min = models.IntegerField(verbose_name="Minimum Calories")
    calorie_max = models.IntegerField(verbose_name="Maximum Calories")
    description = models.TextField(blank=True, verbose_name="Description")
    meals_data = models.JSONField(verbose_name="Meals Data")  # {"breakfast": [...], "lunch": [...], "dinner": [...], "snacks": [...]}
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="Created At")
    updated_at = models.DateTimeField(auto_now=True, verbose_name="Updated At")
    
    class Meta:
        db_table = 'diet_plan_template'
        verbose_name = 'Diet Plan Template'
        verbose_name_plural = 'Diet Plan Templates'
        ordering = ['goal_type', 'calorie_min']
    
    def __str__(self):
        return f"{self.name} ({self.calorie_min}-{self.calorie_max} cal)"


class UserDietPlan(models.Model):
    """
    Personalized diet plan assigned by trainer to user
    """
    user = models.ForeignKey(UserLogin, on_delete=models.CASCADE, related_name='diet_plans', verbose_name="User")
    trainer = models.ForeignKey(Trainer, on_delete=models.CASCADE, related_name='created_diet_plans', verbose_name="Trainer")
    template = models.ForeignKey(DietPlanTemplate, on_delete=models.SET_NULL, null=True, blank=True, verbose_name="Template Used")
    plan_name = models.CharField(max_length=100, verbose_name="Plan Name")
    target_calories = models.IntegerField(verbose_name="Target Daily Calories")
    meals_data = models.JSONField(verbose_name="Customized Meals")  # Trainer can modify template
    notes = models.TextField(blank=True, verbose_name="Trainer Notes")
    start_date = models.DateField(verbose_name="Start Date")
    end_date = models.DateField(null=True, blank=True, verbose_name="End Date")
    is_active = models.BooleanField(default=True, verbose_name="Is Active")
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="Created At")
    updated_at = models.DateTimeField(auto_now=True, verbose_name="Updated At")
    
    class Meta:
        db_table = 'user_diet_plan'
        verbose_name = 'User Diet Plan'
        verbose_name_plural = 'User Diet Plans'
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.user.name} - {self.plan_name}"


class WorkoutVideo(models.Model):
    """
    WorkoutVideo model to store workout videos uploaded by trainers
    """
    GOAL_TYPE_CHOICES = [
        ('weight_gain', 'Weight Gain'),
        ('weight_loss', 'Weight Loss'),
        ('muscle_gain', 'Muscle Gain'),
        ('muscle_building', 'Muscle Building'),
        ('others', 'General Fitness'),
    ]
    
    DIFFICULTY_LEVEL_CHOICES = [
        ('beginner', 'Beginner (0-10kg difference)'),
        ('advanced', 'Advanced (11-30kg difference)'),
    ]
    
    UPLOAD_TYPE_CHOICES = [
        ('web', 'Web Upload'),
        ('bulk', 'Bulk/Admin Upload'),
    ]
    
    title = models.CharField(max_length=255, verbose_name="Video Title")
    description = models.TextField(verbose_name="Description")
    video_file = models.FileField(upload_to='workout_videos/', verbose_name="Video File")
    thumbnail = models.ImageField(upload_to='video_thumbnails/', null=True, blank=True, verbose_name="Thumbnail")
    goal_type = models.CharField(max_length=50, choices=GOAL_TYPE_CHOICES, verbose_name="Goal Type")
    difficulty_level = models.CharField(max_length=20, choices=DIFFICULTY_LEVEL_CHOICES, verbose_name="Difficulty Level")
    min_weight_difference = models.IntegerField(default=0, verbose_name="Min Weight Difference (kg)")
    max_weight_difference = models.IntegerField(default=10, verbose_name="Max Weight Difference (kg)")
    duration = models.IntegerField(null=True, blank=True, verbose_name="Duration (seconds)")
    uploaded_by = models.ForeignKey(Trainer, on_delete=models.CASCADE, related_name='uploaded_videos', null=True, blank=True)
    uploaded_via = models.CharField(max_length=10, choices=UPLOAD_TYPE_CHOICES, default='web', verbose_name="Upload Type")
    day_number = models.IntegerField(null=True, blank=True, verbose_name="Day Number (for daily progression)")
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="Created At")
    updated_at = models.DateTimeField(auto_now=True, verbose_name="Updated At")
    is_active = models.BooleanField(default=True, verbose_name="Is Active")
    
    class Meta:
        db_table = 'workout_video'
        verbose_name = 'Workout Video'
        verbose_name_plural = 'Workout Videos'
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.title} - {self.goal_type} ({self.difficulty_level})"


class VideoRecommendation(models.Model):
    """
    VideoRecommendation model to track trainer-recommended videos for specific users
    """
    video = models.ForeignKey(WorkoutVideo, on_delete=models.CASCADE, related_name='recommendations')
    user = models.ForeignKey(UserProfile, on_delete=models.CASCADE, related_name='recommended_videos')
    recommended_by = models.ForeignKey(Trainer, on_delete=models.CASCADE, related_name='video_recommendations')
    note = models.TextField(null=True, blank=True, verbose_name="Trainer's Note")
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="Recommended At")
    
    class Meta:
        db_table = 'video_recommendation'
        verbose_name = 'Video Recommendation'
        verbose_name_plural = 'Video Recommendations'
        ordering = ['-created_at']
        unique_together = ['video', 'user']
    
    def __str__(self):
        return f"{self.video.title} → {self.user.user.name}"


class ChatMessage(models.Model):
    """
    ChatMessage model to store messages between users and trainers
    """
    SENDER_CHOICES = [
        ('user', 'User'),
        ('trainer', 'Trainer'),
    ]
    
    user = models.ForeignKey(UserProfile, on_delete=models.CASCADE, related_name='chat_messages')
    trainer = models.ForeignKey(Trainer, on_delete=models.CASCADE, related_name='chat_messages')
    message = models.TextField(verbose_name="Message")
    sender_type = models.CharField(max_length=10, choices=SENDER_CHOICES, verbose_name="Sender Type")
    is_read = models.BooleanField(default=False, verbose_name="Is Read")
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="Created At")
    
    class Meta:
        db_table = 'chat_message'
        verbose_name = 'Chat Message'
        verbose_name_plural = 'Chat Messages'
        ordering = ['created_at']
    
    def __str__(self):
        return f"{self.sender_type}: {self.message[:50]}"


class FoodEntry(models.Model):
    """
    FoodEntry model to track user's daily food consumption with quantities
    """
    MEAL_TYPE_CHOICES = [
        ('breakfast', 'Breakfast'),
        ('lunch', 'Lunch'),
        ('dinner', 'Dinner'),
        ('snacks', 'Snacks'),
        ('fruits', 'Fruits'),
        ('nuts', 'Nuts'),
        ('milks', 'Milks'),
        ('other', 'Other'),
    ]
    
    user = models.ForeignKey(UserLogin, on_delete=models.CASCADE, related_name='food_entries', verbose_name="User")
    food_item = models.ForeignKey(FoodItem, on_delete=models.PROTECT, related_name='entries', verbose_name="Food Item")
    quantity = models.FloatField(verbose_name="Quantity")
    quantity_unit = models.CharField(max_length=50, default="g", verbose_name="Unit (g, ml, piece, cup, bowl, etc.)")
    meal_type = models.CharField(max_length=20, choices=MEAL_TYPE_CHOICES, verbose_name="Meal Type")
    calculated_calories = models.FloatField(verbose_name="Calculated Calories")
    is_custom_calories = models.BooleanField(default=False, verbose_name="Is Custom Default Calorie")
    entry_date = models.DateField(verbose_name="Entry Date")
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="Created At")
    updated_at = models.DateTimeField(auto_now=True, verbose_name="Updated At")
    
    class Meta:
        db_table = 'food_entry'
        verbose_name = 'Food Entry'
        verbose_name_plural = 'Food Entries'
        ordering = ['-entry_date', 'meal_type']
        indexes = [
            models.Index(fields=['user', 'entry_date']),
        ]
    
    def __str__(self):
        return f"{self.user.name} - {self.food_item.name} ({self.quantity}{self.quantity_unit}) - {self.entry_date}"
    
    def save(self, *args, **kwargs):
        """Calculate calories based on quantity"""
        unit = (self.quantity_unit or '').lower()
        if self.is_custom_calories:
            # For custom foods, treat FoodItem.calories as per 100g (or per piece for discrete units)
            if unit in ['piece', 'cup', 'bowl']:
                self.calculated_calories = self.food_item.calories * self.quantity
            else:
                self.calculated_calories = (self.food_item.calories / 100) * self.quantity
        else:
            # Calculate based on quantity and unit
            if unit in ['piece', 'cup', 'bowl']:
                # For discrete items: multiply base calories by quantity
                # Example: 2 idli = 70 cal * 2 = 140 cal
                self.calculated_calories = self.food_item.calories * self.quantity
            else:
                # For grams/ml: calculate proportionally from 100g base
                # Example: 200g rice = (130 cal / 100) * 200 = 260 cal
                self.calculated_calories = (self.food_item.calories / 100) * self.quantity
        
        super().save(*args, **kwargs)
    
    @classmethod
    def get_daily_total(cls, user, entry_date):
        """Get total calories for a specific date"""
        entries = cls.objects.filter(user=user, entry_date=entry_date)
        total = sum([entry.calculated_calories for entry in entries])
        return total
    
    @classmethod
    def get_daily_breakdown(cls, user, entry_date):
        """Get calorie breakdown by meal type for a specific date"""
        entries = cls.objects.filter(user=user, entry_date=entry_date)
        breakdown = {}
        for meal_type in dict(cls.MEAL_TYPE_CHOICES).keys():
            meal_entries = entries.filter(meal_type=meal_type)
            meal_total = sum([entry.calculated_calories for entry in meal_entries])
            breakdown[meal_type] = {
                'total_calories': meal_total,
                'entries': meal_entries.count()
            }
        return breakdown
