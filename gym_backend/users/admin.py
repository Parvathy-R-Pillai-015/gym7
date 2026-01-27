from django.contrib import admin
from .models import UserLogin, Trainer, WorkoutVideo, ChatMessage, FoodRecipe

# Register your models here.

@admin.register(UserLogin)
class UserLoginAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'emailid', 'role', 'is_active', 'created_at')
    list_filter = ('role', 'is_active', 'created_at')
    search_fields = ('name', 'emailid')
    readonly_fields = ('created_at', 'updated_at')
    ordering = ('-created_at',)
    
    fieldsets = (
        ('User Information', {
            'fields': ('name', 'emailid', 'password', 'role')
        }),
        ('Status', {
            'fields': ('is_active',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )

@admin.register(Trainer)
class TrainerAdmin(admin.ModelAdmin):
    list_display = ('id', 'get_trainer_name', 'get_trainer_email', 'mobile', 'gender', 'experience', 'specialization', 'joining_period', 'created_at')
    list_filter = ('gender', 'specialization', 'joining_period', 'created_at')
    search_fields = ('user__name', 'user__emailid', 'mobile')
    readonly_fields = ('created_at',)
    ordering = ('-created_at',)
    
    def get_trainer_name(self, obj):
        return obj.user.name
    get_trainer_name.short_description = 'Name'
    
    def get_trainer_email(self, obj):
        return obj.user.emailid
    get_trainer_email.short_description = 'Email'
    
    fieldsets = (
        ('User Information', {
            'fields': ('user',)
        }),
        ('Trainer Details', {
            'fields': ('mobile', 'gender', 'experience', 'specialization', 'joining_period')
        }),
        ('Timestamps', {
            'fields': ('created_at',),
            'classes': ('collapse',)
        }),
    )

@admin.register(WorkoutVideo)
class WorkoutVideoAdmin(admin.ModelAdmin):
    list_display = ('day_number', 'title', 'goal_type', 'difficulty_level', 'uploaded_via', 'uploaded_by', 'is_active', 'created_at')
    list_filter = ('uploaded_via', 'goal_type', 'difficulty_level', 'is_active', 'created_at')
    search_fields = ('title', 'description')
    readonly_fields = ('created_at', 'updated_at')
    ordering = ('day_number', 'goal_type', 'difficulty_level')
    
    fieldsets = (
        ('Video Information', {
            'fields': ('title', 'description', 'video_file', 'thumbnail', 'duration')
        }),
        ('Classification', {
            'fields': ('goal_type', 'difficulty_level', 'min_weight_difference', 'max_weight_difference')
        }),
        ('Upload Details', {
            'fields': ('uploaded_by', 'uploaded_via', 'day_number')
        }),
        ('Status', {
            'fields': ('is_active',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def get_queryset(self, request):
        qs = super().get_queryset(request)
        return qs.select_related('uploaded_by', 'uploaded_by__user')

@admin.register(ChatMessage)
class ChatMessageAdmin(admin.ModelAdmin):
    list_display = ('id', 'get_user_name', 'get_trainer_name', 'sender_type', 'is_read', 'created_at')
    list_filter = ('sender_type', 'is_read', 'created_at')
    search_fields = ('user__user__name', 'trainer__user__name', 'message')
    readonly_fields = ('created_at',)
    ordering = ('-created_at',)
    
    def get_user_name(self, obj):
        return obj.user.user.name
    get_user_name.short_description = 'User'
    
    def get_trainer_name(self, obj):
        return obj.trainer.user.name
    get_trainer_name.short_description = 'Trainer'
    
    fieldsets = (
        ('Chat Participants', {
            'fields': ('user', 'trainer')
        }),
        ('Message Details', {
            'fields': ('message', 'sender_type', 'is_read')
        }),
        ('Timestamp', {
            'fields': ('created_at',),
            'classes': ('collapse',)
        }),
    )

@admin.register(FoodRecipe)
class FoodRecipeAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'food_type', 'created_by', 'created_at')
    list_filter = ('food_type', 'created_at')
    search_fields = ('name', 'ingredients', 'instructions')
    readonly_fields = ('created_at',)
    ordering = ('-created_at',)
    
    fieldsets = (
        ('Recipe Information', {
            'fields': ('name', 'food_type', 'created_by')
        }),
        ('Recipe Details', {
            'fields': ('ingredients', 'instructions')
        }),
        ('Timestamp', {
            'fields': ('created_at',),
            'classes': ('collapse',)
        }),
    )
