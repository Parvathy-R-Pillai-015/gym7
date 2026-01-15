from django.contrib import admin
from .models import UserLogin, Trainer

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
