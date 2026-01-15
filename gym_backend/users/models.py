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
    user = models.OneToOneField(UserLogin, on_delete=models.CASCADE, related_name='trainer_profile')
    mobile = models.CharField(max_length=10, verbose_name="Mobile Number")
    gender = models.CharField(max_length=10, verbose_name="Gender")
    experience = models.IntegerField(verbose_name="Years of Experience")
    specialization = models.CharField(max_length=100, verbose_name="Specialization")
    joining_period = models.CharField(max_length=50, verbose_name="Joining Period")
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="Created At")
    
    class Meta:
        db_table = 'trainer'
        verbose_name = 'Trainer'
        verbose_name_plural = 'Trainers'
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.user.name} - {self.specialization}"
