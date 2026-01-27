from django.shortcuts import render
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.core.files.storage import default_storage
from django.core.files.base import ContentFile
from django.utils import timezone
import json
from datetime import datetime, timedelta, date
from .models import UserLogin, Trainer, UserProfile, Attendance, Review, FoodItem, DietPlanTemplate, UserDietPlan, WorkoutVideo, VideoRecommendation, ChatMessage, FoodEntry, SubscriptionRenewal

# Create your views here.

@csrf_exempt
def create_user(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            name = data.get('name')
            emailid = data.get('emailid')
            password = data.get('password')
            
            if not name or not emailid or not password:
                return JsonResponse({
                    'success': False,
                    'message': 'All fields (name, emailid, password) are required'
                }, status=400)
            
            # Check if user with this email already exists
            if UserLogin.objects.filter(emailid=emailid).exists():
                return JsonResponse({
                    'success': False,
                    'message': 'User with this email already exists'
                }, status=400)
            
            # Create new user
            user = UserLogin.objects.create(
                name=name,
                emailid=emailid,
                password=password  # Password will be hashed in the model's save method
            )
            
            return JsonResponse({
                'success': True,
                'message': 'User registered successfully',
                'user': {
                    'id': user.id,
                    'name': user.name,
                    'emailid': user.emailid
                }
            }, status=201)
            
        except json.JSONDecodeError:
            return JsonResponse({
                'success': False,
                'message': 'Invalid JSON data'
            }, status=400)
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
def login_user(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            emailid = data.get('emailid')
            password = data.get('password')
            
            print(f"[LOGIN ATTEMPT] Email: {emailid}")  # Debug log
            
            if not emailid or not password:
                return JsonResponse({
                    'success': False,
                    'message': 'Email and password are required'
                }, status=400)
            
            # Find user by emailid
            try:
                user = UserLogin.objects.get(emailid=emailid)
                print(f"[USER FOUND] Name: {user.name}, Email: {user.emailid}")  # Debug log
            except UserLogin.DoesNotExist:
                print(f"[USER NOT FOUND] Email: {emailid} - REJECTED")  # Debug log
                return JsonResponse({
                    'success': False,
                    'message': 'User not registered. Please register first.'
                }, status=401)
            
            # Check if user is active
            if not user.is_active:
                print(f"[INACTIVE USER] Email: {emailid} - REJECTED")  # Debug log
                return JsonResponse({
                    'success': False,
                    'message': 'Account is inactive. Please contact support.'
                }, status=401)
            
            # Check password
            if user.check_password(password):
                print(f"[LOGIN SUCCESS] Email: {emailid} - Role: {user.role}")  # Debug log
                
                user_data = {
                    'id': user.id,
                    'name': user.name,
                    'emailid': user.emailid,
                    'role': user.role
                }
                
                # If user is a trainer, include trainer_id
                if user.role == 'trainer':
                    try:
                        trainer = Trainer.objects.get(user=user)
                        user_data['trainer_id'] = trainer.id
                    except Trainer.DoesNotExist:
                        pass
                
                return JsonResponse({
                    'success': True,
                    'message': 'Login successful',
                    'user': user_data
                }, status=200)
            else:
                print(f"[WRONG PASSWORD] Email: {emailid} - REJECTED")  # Debug log
                return JsonResponse({
                    'success': False,
                    'message': 'Invalid email or password'
                }, status=401)
            
        except json.JSONDecodeError:
            return JsonResponse({
                'success': False,
                'message': 'Invalid JSON data'
            }, status=400)
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
def create_trainer(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            name = data.get('name')
            emailid = data.get('emailid')
            mobile = data.get('mobile')
            gender = data.get('gender')
            experience = data.get('experience')
            specialization = data.get('specialization')
            joining_period = data.get('joining_period')
            password = data.get('password')
            
            if not all([name, emailid, mobile, gender, experience, specialization, joining_period, password]):
                return JsonResponse({'success': False, 'message': 'All fields are required'}, status=400)
            
            if UserLogin.objects.filter(emailid=emailid).exists():
                return JsonResponse({'success': False, 'message': 'Email already exists'}, status=400)
            
            if len(mobile) != 10 or not mobile.isdigit():
                return JsonResponse({'success': False, 'message': 'Mobile number must be 10 digits'}, status=400)
            
            user = UserLogin.objects.create(name=name, emailid=emailid, password=password, role='trainer')
            trainer = Trainer.objects.create(user=user, mobile=mobile, gender=gender, experience=int(experience), specialization=specialization, joining_period=joining_period)
            
            return JsonResponse({'success': True, 'message': 'Trainer added successfully', 'trainer': {'id': trainer.id, 'name': user.name, 'emailid': user.emailid, 'mobile': trainer.mobile, 'specialization': trainer.specialization}}, status=201)
        except Exception as e:
            return JsonResponse({'success': False, 'message': str(e)}, status=500)
    return JsonResponse({'success': False, 'message': 'Only POST method is allowed'}, status=405)


@csrf_exempt
def create_profile(request):
    """Create or update user profile with fitness goals"""
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            user_id = data.get('user_id')
            
            # Validate user_id
            if not user_id:
                return JsonResponse({
                    'success': False,
                    'message': 'User ID is required'
                }, status=400)
            
            # Check if user exists
            try:
                user = UserLogin.objects.get(id=user_id)
            except UserLogin.DoesNotExist:
                return JsonResponse({
                    'success': False,
                    'message': 'User not found'
                }, status=404)
            
            # Get all required fields
            mobile_number = data.get('mobile_number', '')
            age = data.get('age')
            gender = data.get('gender')
            current_weight = data.get('current_weight')
            current_height = data.get('current_height')
            goal = data.get('goal')
            target_weight = data.get('target_weight')
            target_months = data.get('target_months')
            workout_time = data.get('workout_time')
            diet_preference = data.get('diet_preference')
            food_allergies = data.get('food_allergies', '')
            health_conditions = data.get('health_conditions', '')
            trainer_id = data.get('trainer_id')
            
            # Validate required fields
            if not all([age, gender, current_weight, current_height, goal, target_weight, target_months, workout_time, diet_preference]):
                return JsonResponse({
                    'success': False,
                    'message': 'All fields are required except food allergies and health conditions'
                }, status=400)
            
            # Calculate payment amount based on target months
            payment_map = {1: 399, 2: 499, 3: 699, 6: 1199, 8: 1599, 12: 2199}
            payment_amount = payment_map.get(int(target_months), 0)
            
            # Check if profile already exists and update or create
            try:
                profile = UserProfile.objects.get(user=user)
                # Update existing profile
                profile.mobile_number = mobile_number
                profile.age = int(age)
                profile.gender = gender
                profile.current_weight = float(current_weight)
                profile.current_height = float(current_height)
                profile.goal = goal
                profile.target_weight = float(target_weight)
                profile.target_months = int(target_months)
                profile.workout_time = workout_time
                profile.diet_preference = diet_preference
                profile.food_allergies = food_allergies
                profile.health_conditions = health_conditions
                profile.payment_amount = payment_amount
                
                # Assign trainer if provided
                if trainer_id:
                    try:
                        trainer = Trainer.objects.get(id=trainer_id)
                        profile.assigned_trainer = trainer
                    except Trainer.DoesNotExist:
                        pass
                
                profile.save()
            except UserProfile.DoesNotExist:
                # Get trainer if provided
                assigned_trainer = None
                if trainer_id:
                    try:
                        assigned_trainer = Trainer.objects.get(id=trainer_id)
                    except Trainer.DoesNotExist:
                        pass
                
                # Create new profile with all fields
                profile = UserProfile.objects.create(
                    user=user,
                    mobile_number=mobile_number,
                    age=int(age),
                    gender=gender,
                    current_weight=float(current_weight),
                    current_height=float(current_height),
                    goal=goal,
                    target_weight=float(target_weight),
                    target_months=int(target_months),
                    workout_time=workout_time,
                    diet_preference=diet_preference,
                    food_allergies=food_allergies,
                    health_conditions=health_conditions,
                    payment_amount=payment_amount,
                    assigned_trainer=assigned_trainer
                )
            
            return JsonResponse({
                'success': True,
                'message': 'Profile saved successfully',
                'profile': {
                    'id': profile.id,
                    'user_id': user.id,
                    'age': profile.age,
                    'gender': profile.gender,
                    'current_weight': profile.current_weight,
                    'current_height': profile.current_height,
                    'goal': profile.goal,
                    'target_weight': profile.target_weight,
                    'target_months': profile.target_months,
                    'workout_time': profile.workout_time,
                    'diet_preference': profile.diet_preference,
                    'food_allergies': profile.food_allergies,
                    'health_conditions': profile.health_conditions,
                    'payment_amount': profile.payment_amount,
                    'payment_status': profile.payment_status
                }
            }, status=200)
            
        except json.JSONDecodeError:
            return JsonResponse({
                'success': False,
                'message': 'Invalid JSON data'
            }, status=400)
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
def get_profile(request, user_id):
    """Get user profile by user_id"""
    if request.method == 'GET':
        try:
            print(f"Getting profile for user_id: {user_id}")
            user = UserLogin.objects.get(id=user_id)
            try:
                profile = UserProfile.objects.get(user=user)
                print(f"Profile found: {profile.id}, payment_status: {profile.payment_status}")
                
                # Get trainer info if assigned
                trainer_info = None
                if profile.assigned_trainer:
                    trainer = profile.assigned_trainer
                    trainer_info = {
                        'id': trainer.id,
                        'name': trainer.user.name,
                        'email': trainer.user.emailid,
                        'mobile': trainer.mobile,
                        'experience': trainer.experience,
                        'specialization': trainer.specialization,
                        'certification': trainer.certification or 'Not Specified'
                    }
                
                response_data = {
                    'success': True,
                    'profile': {
                        'id': profile.id,
                        'user_id': user.id,
                        'mobile_number': profile.mobile_number,
                        'age': profile.age,
                        'gender': profile.gender,
                        'current_weight': profile.current_weight,
                        'current_height': profile.current_height,
                        'goal': profile.goal,
                        'target_weight': profile.target_weight,
                        'target_months': profile.target_months,
                        'workout_time': profile.workout_time,
                        'diet_preference': profile.diet_preference,
                        'food_allergies': profile.food_allergies,
                        'health_conditions': profile.health_conditions,
                        'payment_amount': profile.payment_amount,
                        'payment_status': profile.payment_status,
                        'assigned_trainer': trainer_info
                    }
                }
                print(f"Returning response: {response_data}")
                return JsonResponse(response_data, status=200)
            except UserProfile.DoesNotExist:
                print(f"Profile not found for user_id: {user_id}")
                return JsonResponse({
                    'success': False,
                    'message': 'Profile not found'
                }, status=404)
        except UserLogin.DoesNotExist:
            print(f"User not found: {user_id}")
            return JsonResponse({
                'success': False,
                'message': 'User not found'
            }, status=404)
        except Exception as e:
            print(f"Error in get_profile: {str(e)}")
            return JsonResponse({
                'success': False,
                'message': str(e)
            }, status=500)
    
    return JsonResponse({
        'success': False,
        'message': 'Only GET method is allowed'
    }, status=405)


@csrf_exempt
def update_payment_status(request):
    """Update payment status after successful payment - sets subscription dates"""
    if request.method == 'POST':
        try:
            from datetime import timedelta
            from django.utils import timezone
            
            data = json.loads(request.body)
            user_id = data.get('user_id')
            payment_status = data.get('payment_status', True)
            
            if not user_id:
                return JsonResponse({
                    'success': False,
                    'message': 'User ID is required'
                }, status=400)
            
            payment_method = data.get('payment_method', '')
            
            user = UserLogin.objects.get(id=user_id)
            profile = UserProfile.objects.get(user=user)
            profile.payment_status = payment_status
            
            if payment_method:
                profile.payment_method = payment_method
            
            # Set subscription dates when payment is made
            if payment_status:
                now = timezone.now()
                profile.subscription_start_date = now
                profile.payment_date = now
                # Add target_months to current date (using 30 days per month)
                profile.subscription_end_date = now + timedelta(days=profile.target_months * 30)
            
            profile.save()

            # Record initial payment as a renewal entry for auditability
            if payment_status:
                try:
                    amount = profile.payment_amount or profile.calculate_payment_amount()
                    SubscriptionRenewal.objects.create(
                        user=user,
                        months=profile.target_months,
                        amount=amount,
                        payment_method=payment_method or None,
                    )
                except Exception:
                    # Non-blocking: if history creation fails, still return success
                    pass
            
            return JsonResponse({
                'success': True,
                'message': 'Payment status updated successfully',
                'payment_status': profile.payment_status,
                'subscription_end_date': profile.subscription_end_date.isoformat() if profile.subscription_end_date else None
            }, status=200)
            
        except UserLogin.DoesNotExist:
            return JsonResponse({
                'success': False,
                'message': 'User not found'
            }, status=404)
        except UserProfile.DoesNotExist:
            return JsonResponse({
                'success': False,
                'message': 'Profile not found'
            }, status=404)
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
def get_trainer_users(request, trainer_id):
    """Get all users assigned to a specific trainer (only paid users)"""
    if request.method == 'GET':
        try:
            trainer = Trainer.objects.get(id=trainer_id)
            profiles = UserProfile.objects.filter(
                assigned_trainer=trainer,
                payment_status=True  # Only show paid users
            ).select_related('user').order_by('-created_at')
            
            user_list = []
            for profile in profiles:
                user = profile.user
                
                # Calculate remaining days
                remaining_days = profile.get_remaining_days()
                
                # Get attendance stats
                total_attendance = Attendance.objects.filter(
                    user=user,
                    trainer=trainer,
                    status='accepted'
                ).count()
                
                pending_attendance = Attendance.objects.filter(
                    user=user,
                    trainer=trainer,
                    status='pending'
                ).count()
                
                user_data = {
                    'id': user.id,
                    'name': user.name,
                    'email': user.emailid,
                    'mobile': profile.mobile_number,
                    'age': profile.age,
                    'gender': profile.gender,
                    'current_weight': profile.current_weight,
                    'current_height': profile.current_height,
                    'goal': profile.goal,
                    'target_weight': profile.target_weight,
                    'target_months': profile.target_months,
                    'remaining_days': remaining_days,
                    'subscription_start_date': profile.subscription_start_date.isoformat() if profile.subscription_start_date else None,
                    'subscription_end_date': profile.subscription_end_date.isoformat() if profile.subscription_end_date else None,
                    'subscription_status': 'active' if profile.is_subscription_active() else 'expired',
                    'payment_date': profile.payment_date.isoformat() if profile.payment_date else None,
                    'workout_time': profile.workout_time,
                    'diet_preference': profile.diet_preference,
                    'food_allergies': profile.food_allergies or '',
                    'health_conditions': profile.health_conditions or '',
                    'payment_amount': profile.payment_amount,
                    'total_attendance': total_attendance,
                    'pending_attendance': pending_attendance,
                    'created_at': profile.created_at.strftime('%Y-%m-%d')
                }
                user_list.append(user_data)
            
            return JsonResponse({
                'success': True,
                'users': user_list,
                'total': len(user_list)
            }, status=200)
            
        except Trainer.DoesNotExist:
            return JsonResponse({
                'success': False,
                'message': 'Trainer not found'
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
def request_attendance(request):
    """User requests attendance for today"""
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            user_id = data.get('user_id')
            
            if not user_id:
                return JsonResponse({
                    'success': False,
                    'message': 'User ID is required'
                }, status=400)
            
            user = UserLogin.objects.get(id=user_id)
            profile = UserProfile.objects.get(user=user)
            
            if not profile.assigned_trainer:
                return JsonResponse({
                    'success': False,
                    'message': 'No trainer assigned to this user'
                }, status=400)
            
            # Check if attendance already requested for today
            today = datetime.now().date()
            if Attendance.objects.filter(user=user, date=today).exists():
                return JsonResponse({
                    'success': False,
                    'message': 'Attendance already requested for today'
                }, status=400)
            
            # Create attendance request
            attendance = Attendance.objects.create(
                user=user,
                trainer=profile.assigned_trainer,
                date=today,
                status='pending'
            )
            
            return JsonResponse({
                'success': True,
                'message': 'Attendance request submitted successfully',
                'attendance': {
                    'id': attendance.id,
                    'date': attendance.date.strftime('%Y-%m-%d'),
                    'status': attendance.status
                }
            }, status=201)
            
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
        'message': 'Only POST method is allowed'
    }, status=405)


@csrf_exempt
def get_user_attendance(request, user_id):
    """Get attendance history for a specific user including absent days"""
    if request.method == 'GET':
        try:
            user = UserLogin.objects.get(id=user_id)
            profile = UserProfile.objects.get(user=user)
            
            # Get all attendance records
            attendances = Attendance.objects.filter(user=user).order_by('-date')
            
            # Get start date (when user created profile)
            start_date = profile.created_at.date()
            today = date.today()
            
            # Create a dictionary of dates with attendance
            attendance_dict = {}
            for att in attendances:
                attendance_dict[att.date] = {
                    'id': att.id,
                    'date': att.date.strftime('%Y-%m-%d'),
                    'status': att.status,
                    'request_date': att.request_date.strftime('%Y-%m-%d %H:%M'),
                    'accepted_date': att.accepted_date.strftime('%Y-%m-%d %H:%M') if att.accepted_date else None,
                    'is_absent': False
                }
            
            # Generate full attendance list including absent days (but not today)
            attendance_list = []
            current_date = start_date
            yesterday = today - timedelta(days=1)
            
            while current_date <= today:
                if current_date in attendance_dict:
                    # Attendance record exists
                    attendance_list.append(attendance_dict[current_date])
                elif current_date < today:
                    # Past date with no attendance record - mark as absent
                    attendance_list.append({
                        'id': None,
                        'date': current_date.strftime('%Y-%m-%d'),
                        'status': 'absent',
                        'request_date': None,
                        'accepted_date': None,
                        'is_absent': True
                    })
                # If current_date == today and no record, don't add anything (user can still request)
                current_date += timedelta(days=1)
            
            # Sort by date descending (newest first)
            attendance_list.sort(key=lambda x: x['date'], reverse=True)
            
            # Calculate statistics (only count past days as absent, not today)
            total_accepted = attendances.filter(status='accepted').count()
            total_pending = attendances.filter(status='pending').count()
            total_past_days = (yesterday - start_date).days + 1 if yesterday >= start_date else 0
            total_absent = max(0, total_past_days - attendances.filter(date__lt=today).count())
            total_days = (today - start_date).days + 1
            
            return JsonResponse({
                'success': True,
                'attendances': attendance_list,
                'total_accepted': total_accepted,
                'total_pending': total_pending,
                'total_absent': total_absent,
                'total_days': total_days
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
def accept_attendance(request):
    """Trainer accepts user's attendance request"""
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            attendance_id = data.get('attendance_id')
            status = data.get('status', 'accepted')  # accepted or rejected
            
            if not attendance_id:
                return JsonResponse({
                    'success': False,
                    'message': 'Attendance ID is required'
                }, status=400)
            
            attendance = Attendance.objects.get(id=attendance_id)
            attendance.status = status
            if status == 'accepted':
                attendance.accepted_date = datetime.now()
            attendance.save()
            
            return JsonResponse({
                'success': True,
                'message': f'Attendance {status} successfully',
                'attendance': {
                    'id': attendance.id,
                    'user': attendance.user.name,
                    'date': attendance.date.strftime('%Y-%m-%d'),
                    'status': attendance.status
                }
            }, status=200)
            
        except Attendance.DoesNotExist:
            return JsonResponse({
                'success': False,
                'message': 'Attendance record not found'
            }, status=404)
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
def get_pending_attendance_requests(request, trainer_id):
    """Get all pending attendance requests for a trainer"""
    if request.method == 'GET':
        try:
            trainer = Trainer.objects.get(id=trainer_id)
            pending_requests = Attendance.objects.filter(
                trainer=trainer,
                status='pending'
            ).select_related('user').order_by('-date')
            
            request_list = []
            for att in pending_requests:
                request_list.append({
                    'id': att.id,
                    'user_id': att.user.id,
                    'user_name': att.user.name,
                    'date': att.date.strftime('%Y-%m-%d'),
                    'request_date': att.request_date.strftime('%Y-%m-%d %H:%M')
                })
            
            return JsonResponse({
                'success': True,
                'requests': request_list,
                'total': len(request_list)
            }, status=200)
            
        except Trainer.DoesNotExist:
            return JsonResponse({
                'success': False,
                'message': 'Trainer not found'
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
def create_review(request):
    """User creates a review for their trainer (once per month)"""
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            user_id = data.get('user_id')
            rating = data.get('rating')
            review_text = data.get('review_text')
            
            if not all([user_id, rating, review_text]):
                return JsonResponse({
                    'success': False,
                    'message': 'User ID, rating, and review text are required'
                }, status=400)
            
            if rating not in [1, 2, 3, 4, 5]:
                return JsonResponse({
                    'success': False,
                    'message': 'Rating must be between 1 and 5'
                }, status=400)
            
            user = UserLogin.objects.get(id=user_id)
            profile = UserProfile.objects.get(user=user)
            
            if not profile.assigned_trainer:
                return JsonResponse({
                    'success': False,
                    'message': 'No trainer assigned to this user'
                }, status=400)
            
            # Check if user already posted review this month
            from django.utils import timezone
            one_month_ago = timezone.now() - timedelta(days=30)
            recent_review = Review.objects.filter(
                user=user,
                trainer=profile.assigned_trainer,
                created_at__gte=one_month_ago
            ).first()
            
            if recent_review:
                return JsonResponse({
                    'success': False,
                    'message': 'You can only post one review per month. Try again later.'
                }, status=400)
            
            # Create review
            review = Review.objects.create(
                user=user,
                trainer=profile.assigned_trainer,
                rating=rating,
                review_text=review_text
            )
            
            return JsonResponse({
                'success': True,
                'message': 'Review posted successfully',
                'review': {
                    'id': review.id,
                    'rating': review.rating,
                    'review_text': review.review_text,
                    'created_at': review.created_at.strftime('%Y-%m-%d %H:%M')
                }
            }, status=201)
            
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
        'message': 'Only POST method is allowed'
    }, status=405)


@csrf_exempt
def get_trainer_reviews(request, trainer_id):
    """Get all reviews for a specific trainer"""
    if request.method == 'GET':
        try:
            trainer = Trainer.objects.get(id=trainer_id)
            reviews = Review.objects.filter(trainer=trainer).select_related('user').order_by('-created_at')
            
            review_list = []
            total_rating = 0
            
            for review in reviews:
                review_list.append({
                    'id': review.id,
                    'user_name': review.user.name,
                    'rating': review.rating,
                    'review_text': review.review_text,
                    'created_at': review.created_at.strftime('%Y-%m-%d'),
                    'time': review.created_at.strftime('%H:%M')
                })
                total_rating += review.rating
            
            average_rating = round(total_rating / len(reviews), 1) if reviews.exists() else 0
            
            return JsonResponse({
                'success': True,
                'reviews': review_list,
                'total_reviews': len(review_list),
                'average_rating': average_rating
            }, status=200)
            
        except Trainer.DoesNotExist:
            return JsonResponse({
                'success': False,
                'message': 'Trainer not found'
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
def get_all_reviews(request):
    """Get all reviews from all users (for admin)"""
    if request.method == 'GET':
        try:
            reviews = Review.objects.select_related('user', 'trainer__user').order_by('-created_at')
            
            review_list = []
            for review in reviews:
                review_list.append({
                    'id': review.id,
                    'user_name': review.user.name,
                    'user_email': review.user.emailid,
                    'trainer_name': review.trainer.user.name,
                    'rating': review.rating,
                    'review_text': review.review_text,
                    'created_at': review.created_at.strftime('%Y-%m-%d %H:%M')
                })
            
            return JsonResponse({
                'success': True,
                'reviews': review_list,
                'total': len(review_list)
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


# ==================== DIET PLAN APIs ====================

@csrf_exempt
def get_food_items(request):
    """Get all food items, optionally filtered by user allergies"""
    if request.method == 'GET':
        try:
            user_id = request.GET.get('user_id')
            exclude_allergies = request.GET.get('exclude_allergies', 'false').lower() == 'true'
            
            foods = FoodItem.objects.all()
            
            # Filter by user's diet preference and allergies
            if user_id and exclude_allergies:
                try:
                    user = UserLogin.objects.get(id=user_id)
                    profile = UserProfile.objects.get(user=user)
                    
                    # Filter by diet preference
                    # vegan: only vegan foods
                    # vegetarian: vegan + vegetarian foods (no meat/seafood)
                    # non_veg: all foods
                    if profile.diet_preference == 'vegan':
                        foods = foods.filter(diet_type='vegan')
                    elif profile.diet_preference == 'vegetarian':
                        foods = foods.filter(diet_type__in=['vegan', 'vegetarian'])
                    # non_veg gets all foods (no filter needed)
                    
                    # Filter out allergic foods
                    if profile.food_allergies:
                        allergies = [a.strip().lower() for a in profile.food_allergies.split(',')]
                        # Map common allergy terms to food categories
                        allergy_category_map = {
                            'milk': 'dairy',
                            'dairy': 'dairy',
                            'seafood': 'seafood',
                            'fish': 'seafood',
                            'nuts': 'nuts',
                            'eggs': 'eggs',
                            'egg': 'eggs'
                        }
                        
                        excluded_categories = []
                        for allergy in allergies:
                            if allergy in allergy_category_map:
                                excluded_categories.append(allergy_category_map[allergy])
                        
                        if excluded_categories:
                            foods = foods.exclude(food_category__in=excluded_categories)
                except:
                    pass  # If user not found, return all foods
            
            food_list = []
            for food in foods:
                food_list.append({
                    'id': food.id,
                    'name': food.name,
                    'category': food.food_category,
                    'diet_type': food.diet_type,
                    'calories': float(food.calories),
                    'protein': float(food.protein),
                    'carbs': float(food.carbs),
                    'fats': float(food.fats),
                    'serving_size': food.serving_size
                })
            
            return JsonResponse({
                'success': True,
                'foods': food_list,
                'total': len(food_list)
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
def get_diet_templates(request):
    """Get diet plan templates filtered by goal and calorie range"""
    if request.method == 'GET':
        try:
            goal = request.GET.get('goal')  # weight_loss, weight_gain, muscle_building, others
            target_calories = request.GET.get('target_calories')
            user_weight = request.GET.get('user_weight')  # For 'others' goal weight-based filtering
            
            templates = DietPlanTemplate.objects.all()
            
            if goal:
                templates = templates.filter(goal_type=goal)
            
            # For 'others' goal, filter by user weight to get appropriate calorie range
            if goal == 'others' and user_weight:
                weight = float(user_weight)
                # Weight-based calorie ranges for maintenance
                if weight <= 40:
                    templates = templates.filter(calorie_min__lte=1500, calorie_max__gte=1200)
                elif weight <= 50:
                    templates = templates.filter(calorie_min__lte=1800, calorie_max__gte=1500)
                elif weight <= 60:
                    templates = templates.filter(calorie_min__lte=2100, calorie_max__gte=1800)
                else:  # 61-70kg
                    templates = templates.filter(calorie_min__lte=2400, calorie_max__gte=2100)
            elif target_calories:
                cal = int(target_calories)
                templates = templates.filter(calorie_min__lte=cal, calorie_max__gte=cal)
            
            template_list = []
            for template in templates:
                template_list.append({
                    'id': template.id,
                    'name': template.name,
                    'goal_type': template.goal_type,
                    'calorie_min': template.calorie_min,
                    'calorie_max': template.calorie_max,
                    'description': template.description,
                    'meals_data': template.meals_data
                })
            
            return JsonResponse({
                'success': True,
                'templates': template_list,
                'total': len(template_list)
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
def calculate_target_calories(request, user_id):
    """Calculate personalized daily calories based on user's goals and timeline"""
    if request.method == 'GET':
        try:
            user = UserLogin.objects.get(id=user_id)
            profile = UserProfile.objects.get(user=user)
            
            # Check if user has 'others' goal (maintenance calories)
            if profile.goal == 'others':
                # For 'others' goal, use maintenance calories (BMR)
                bmr = profile.current_weight * 24
                return JsonResponse({
                    'success': True,
                    'user_id': user_id,
                    'goal': 'others',
                    'current_weight': profile.current_weight,
                    'target_calories': int(bmr),
                    'bmr': int(bmr),
                    'message': 'Maintenance calories for general fitness',
                    'food_allergies': profile.food_allergies if profile.food_allergies else 'none',
                    'diet_preference': profile.diet_preference,
                    'requires_diet_plan': True
                }, status=200)
            
            # Use new personalized calculation method
            calc_result = profile.calculate_target_calories()
            
            return JsonResponse({
                'success': True,
                'user_id': user_id,
                'goal': profile.goal,
                'current_weight': profile.current_weight,
                'target_weight': profile.target_weight,
                'target_months': profile.target_months,
                'target_calories': calc_result['target_calories'],
                'bmr': calc_result['bmr'],
                'weekly_change': calc_result['weekly_change'],
                'daily_adjustment': calc_result['daily_adjustment'],
                'is_safe': calc_result['is_safe'],
                'warnings': calc_result['warnings'],
                'food_allergies': profile.food_allergies if profile.food_allergies else 'none',
                'diet_preference': profile.diet_preference,
                'requires_diet_plan': True
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
def create_user_diet_plan(request):
    """Trainer creates a personalized diet plan for a user"""
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            user_id = data.get('user_id')
            trainer_id = data.get('trainer_id')
            template_id = data.get('template_id')
            plan_name = data.get('plan_name')
            target_calories = data.get('target_calories')
            meals_data = data.get('meals_data')
            notes = data.get('notes', '')
            start_date = data.get('start_date')
            
            if not all([user_id, trainer_id, plan_name, target_calories, meals_data]):
                return JsonResponse({
                    'success': False,
                    'message': 'Missing required fields'
                }, status=400)
            
            user = UserLogin.objects.get(id=user_id)
            trainer = Trainer.objects.get(id=trainer_id)
            template = DietPlanTemplate.objects.get(id=template_id) if template_id else None
            
            # Convert start_date string to date object if provided
            if start_date:
                if isinstance(start_date, str):
                    from datetime import datetime
                    start_date_obj = datetime.strptime(start_date, '%Y-%m-%d').date()
                else:
                    start_date_obj = start_date
            else:
                start_date_obj = date.today()
            
            # Deactivate existing active plans
            UserDietPlan.objects.filter(user=user, is_active=True).update(is_active=False)
            
            # Create new diet plan
            diet_plan = UserDietPlan.objects.create(
                user=user,
                trainer=trainer,
                template=template,
                plan_name=plan_name,
                target_calories=target_calories,
                meals_data=meals_data,
                notes=notes,
                start_date=start_date_obj,
                is_active=True
            )
            
            return JsonResponse({
                'success': True,
                'message': 'Diet plan created successfully',
                'diet_plan': {
                    'id': diet_plan.id,
                    'plan_name': diet_plan.plan_name,
                    'target_calories': diet_plan.target_calories,
                    'start_date': diet_plan.start_date.strftime('%Y-%m-%d')
                }
            }, status=201)
            
        except UserLogin.DoesNotExist:
            return JsonResponse({
                'success': False,
                'message': 'User not found'
            }, status=404)
        except Trainer.DoesNotExist:
            return JsonResponse({
                'success': False,
                'message': 'Trainer not found'
            }, status=404)
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
def get_user_diet_plan(request, user_id):
    """Get active diet plan for a user"""
    if request.method == 'GET':
        try:
            user = UserLogin.objects.get(id=user_id)
            diet_plan = UserDietPlan.objects.filter(user=user, is_active=True).first()
            
            if not diet_plan:
                return JsonResponse({
                    'success': True,
                    'has_plan': False,
                    'message': 'No active diet plan found'
                }, status=200)
            
            return JsonResponse({
                'success': True,
                'has_plan': True,
                'diet_plan': {
                    'id': diet_plan.id,
                    'plan_name': diet_plan.plan_name,
                    'target_calories': diet_plan.target_calories,
                    'meals_data': diet_plan.meals_data,
                    'notes': diet_plan.notes,
                    'start_date': diet_plan.start_date.strftime('%Y-%m-%d'),
                    'trainer_name': diet_plan.trainer.user.name,
                    'created_at': diet_plan.created_at.strftime('%Y-%m-%d')
                }
            }, status=200)
            
        except UserLogin.DoesNotExist:
            return JsonResponse({
                'success': False,
                'message': 'User not found'
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
def get_trainer_diet_plans(request, trainer_id):
    """Get all diet plans created by a trainer"""
    if request.method == 'GET':
        try:
            trainer = Trainer.objects.get(id=trainer_id)
            diet_plans = UserDietPlan.objects.filter(trainer=trainer).select_related('user').order_by('-created_at')
            
            plan_list = []
            for plan in diet_plans:
                plan_list.append({
                    'id': plan.id,
                    'user_name': plan.user.name,
                    'user_id': plan.user.id,
                    'plan_name': plan.plan_name,
                    'target_calories': plan.target_calories,
                    'start_date': plan.start_date.strftime('%Y-%m-%d'),
                    'is_active': plan.is_active,
                    'created_at': plan.created_at.strftime('%Y-%m-%d')
                })
            
            return JsonResponse({
                'success': True,
                'diet_plans': plan_list,
                'total': len(plan_list)
            }, status=200)
            
        except Trainer.DoesNotExist:
            return JsonResponse({
                'success': False,
                'message': 'Trainer not found'
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
# ============================================================================
# WORKOUT VIDEO MANAGEMENT VIEWS
# ============================================================================

@csrf_exempt
def upload_video(request):
    """
    Upload a workout video (trainer only)
    """
    if request.method == 'POST':
        try:
            trainer_id = request.POST.get('trainer_id')
            title = request.POST.get('title')
            description = request.POST.get('description')
            goal_type = request.POST.get('goal_type')
            difficulty_level = request.POST.get('difficulty_level')
            video_file = request.FILES.get('video_file')
            thumbnail = request.FILES.get('thumbnail')
            duration = request.POST.get('duration')
            
            if not all([trainer_id, title, description, goal_type, difficulty_level, video_file]):
                return JsonResponse({
                    'success': False,
                    'message': 'All required fields must be provided'
                }, status=400)
            
            # Get trainer
            try:
                trainer = Trainer.objects.get(id=trainer_id)
            except Trainer.DoesNotExist:
                return JsonResponse({
                    'success': False,
                    'message': 'Trainer not found'
                }, status=404)
            
            # Set weight difference based on difficulty level
            if difficulty_level == 'beginner':
                min_weight_diff = 0
                max_weight_diff = 10
            else:  # advanced
                min_weight_diff = 11
                max_weight_diff = 30
            
            # Create video
            video = WorkoutVideo.objects.create(
                title=title,
                description=description,
                video_file=video_file,
                thumbnail=thumbnail,
                goal_type=goal_type,
                difficulty_level=difficulty_level,
                min_weight_difference=min_weight_diff,
                max_weight_difference=max_weight_diff,
                duration=int(duration) if duration else None,
                uploaded_by=trainer,
                uploaded_via='web'  # Mark as web upload
            )
            
            return JsonResponse({
                'success': True,
                'message': 'Video uploaded successfully',
                'video': {
                    'id': video.id,
                    'title': video.title,
                    'goal_type': video.goal_type,
                    'difficulty_level': video.difficulty_level
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
def list_trainer_videos(request, trainer_id):
    """
    List all videos uploaded by a specific trainer (web uploads only, not bulk)
    """
    if request.method == 'GET':
        try:
            trainer = Trainer.objects.get(id=trainer_id)
            videos = WorkoutVideo.objects.filter(uploaded_by=trainer, uploaded_via='web', is_active=True).order_by('-created_at')
            
            video_list = []
            for video in videos:
                video_list.append({
                    'id': video.id,
                    'title': video.title,
                    'description': video.description,
                    'video_url': video.video_file.url if video.video_file else None,
                    'thumbnail_url': video.thumbnail.url if video.thumbnail else None,
                    'goal_type': video.goal_type,
                    'difficulty_level': video.difficulty_level,
                    'weight_range': f"{video.min_weight_difference}-{video.max_weight_difference}kg",
                    'duration': video.duration,
                    'created_at': video.created_at.strftime('%Y-%m-%d')
                })
            
            return JsonResponse({
                'success': True,
                'videos': video_list,
                'total': len(video_list)
            }, status=200)
            
        except Trainer.DoesNotExist:
            return JsonResponse({
                'success': False,
                'message': 'Trainer not found'
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
def get_user_videos(request, user_id):
    """
    Get filtered videos for a specific user based on their goal and weight difference
    Daily progression: Show one video per day based on user's enrollment date
    """
    if request.method == 'GET':
        try:
            user_profile = UserProfile.objects.get(user_id=user_id)
            
            # Calculate weight difference
            if user_profile.goal == 'others':
                weight_difference = 0  # General fitness, show beginner videos
            else:
                weight_difference = abs(user_profile.target_weight - user_profile.current_weight)
            
            # Calculate days since enrollment (starting from day 1)
            days_enrolled = (date.today() - user_profile.created_at.date()).days + 1
            
            # Video filtering based on weight difference
            if weight_difference <= 10:
                # User needs to lose/gain 0-10kg: Show beginner videos
                difficulty_filter = ['beginner']
            else:
                # User needs to lose/gain more than 10kg: Show all videos
                difficulty_filter = ['beginner', 'advanced']
            
            # Get all videos for the user's goal and difficulty level, ordered by day_number
            all_videos = WorkoutVideo.objects.filter(
                goal_type=user_profile.goal,
                difficulty_level__in=difficulty_filter,
                is_active=True
            ).exclude(
                day_number__isnull=True  # Only videos with day numbers (bulk videos)
            ).order_by('day_number')
            
            # Get web-uploaded videos (no day restriction) - only from assigned trainer
            web_videos_query = WorkoutVideo.objects.filter(
                goal_type=user_profile.goal,
                difficulty_level__in=difficulty_filter,
                is_active=True,
                uploaded_via='web',
                day_number__isnull=True
            )
            
            # Filter by assigned trainer if user has one
            if user_profile.assigned_trainer:
                web_videos_query = web_videos_query.filter(uploaded_by=user_profile.assigned_trainer)
            
            web_videos = web_videos_query.order_by('-created_at')
            
            # Get trainer-recommended videos
            recommended_video_ids = VideoRecommendation.objects.filter(
                user=user_profile
            ).values_list('video_id', flat=True)
            
            video_list = []
            
            # Add daily progression videos (unlock based on days enrolled)
            for video in all_videos:
                is_unlocked = video.day_number <= days_enrolled
                is_recommended = video.id in recommended_video_ids
                recommendation = None
                
                if is_recommended:
                    rec = VideoRecommendation.objects.get(video=video, user=user_profile)
                    recommendation = {
                        'note': rec.note,
                        'recommended_by': rec.recommended_by.user.name,
                        'recommended_at': rec.created_at.strftime('%Y-%m-%d')
                    }
                
                video_list.append({
                    'id': video.id,
                    'title': video.title,
                    'description': video.description,
                    'video_url': video.video_file.url if (video.video_file and is_unlocked) else None,
                    'thumbnail_url': video.thumbnail.url if video.thumbnail else None,
                    'goal_type': video.goal_type,
                    'difficulty_level': video.difficulty_level,
                    'weight_range': f"{video.min_weight_difference}-{video.max_weight_difference}kg",
                    'duration': video.duration,
                    'is_recommended': is_recommended,
                    'recommendation': recommendation,
                    'day_number': video.day_number,
                    'is_unlocked': is_unlocked,
                    'unlock_day': video.day_number,
                    'created_at': video.created_at.strftime('%Y-%m-%d')
                })
            
            # Add web-uploaded videos (always available)
            for video in web_videos:
                is_recommended = video.id in recommended_video_ids
                recommendation = None
                
                if is_recommended:
                    rec = VideoRecommendation.objects.get(video=video, user=user_profile)
                    recommendation = {
                        'note': rec.note,
                        'recommended_by': rec.recommended_by.user.name,
                        'recommended_at': rec.created_at.strftime('%Y-%m-%d')
                    }
                
                video_list.append({
                    'id': video.id,
                    'title': video.title,
                    'description': video.description,
                    'video_url': video.video_file.url if video.video_file else None,
                    'thumbnail_url': video.thumbnail.url if video.thumbnail else None,
                    'goal_type': video.goal_type,
                    'difficulty_level': video.difficulty_level,
                    'weight_range': f"{video.min_weight_difference}-{video.max_weight_difference}kg",
                    'duration': video.duration,
                    'is_recommended': is_recommended,
                    'recommendation': recommendation,
                    'day_number': None,
                    'is_unlocked': True,  # Web videos always unlocked
                    'unlock_day': None,
                    'created_at': video.created_at.strftime('%Y-%m-%d')
                })
            
            return JsonResponse({
                'success': True,
                'videos': video_list,
                'total': len(video_list),
                'user_info': {
                    'goal': user_profile.goal,
                    'weight_difference': weight_difference,
                    'days_enrolled': days_enrolled,
                    'unlock_status': f"Day {days_enrolled}: {len([v for v in video_list if v.get('is_unlocked')])} videos available",
                    'assigned_trainer_id': user_profile.assigned_trainer.id if user_profile.assigned_trainer else None,
                    'assigned_trainer_name': user_profile.assigned_trainer.user.name if user_profile.assigned_trainer else None
                }
            }, status=200)
            
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
def delete_video(request, video_id):
    """
    Delete a video (soft delete by setting is_active to False)
    """
    if request.method == 'DELETE':
        try:
            video = WorkoutVideo.objects.get(id=video_id)
            video.is_active = False
            video.save()
            
            return JsonResponse({
                'success': True,
                'message': 'Video deleted successfully'
            }, status=200)
            
        except WorkoutVideo.DoesNotExist:
            return JsonResponse({
                'success': False,
                'message': 'Video not found'
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
def recommend_video_to_user(request):
    """
    Trainer recommends a specific video to a user
    """
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            video_id = data.get('video_id')
            user_id = data.get('user_id')
            trainer_id = data.get('trainer_id')
            note = data.get('note', '')
            
            if not all([video_id, user_id, trainer_id]):
                return JsonResponse({
                    'success': False,
                    'message': 'video_id, user_id, and trainer_id are required'
                }, status=400)
            
            video = WorkoutVideo.objects.get(id=video_id)
            user_profile = UserProfile.objects.get(user_id=user_id)
            trainer = Trainer.objects.get(id=trainer_id)
            
            # Create or update recommendation
            recommendation, created = VideoRecommendation.objects.update_or_create(
                video=video,
                user=user_profile,
                defaults={
                    'recommended_by': trainer,
                    'note': note
                }
            )
            
            return JsonResponse({
                'success': True,
                'message': 'Video recommended successfully',
                'is_new': created
            }, status=201 if created else 200)
            
        except WorkoutVideo.DoesNotExist:
            return JsonResponse({
                'success': False,
                'message': 'Video not found'
            }, status=404)
        except UserProfile.DoesNotExist:
            return JsonResponse({
                'success': False,
                'message': 'User profile not found'
            }, status=404)
        except Trainer.DoesNotExist:
            return JsonResponse({
                'success': False,
                'message': 'Trainer not found'
            }, status=404)
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
def get_trainer_details(request, trainer_id):
    """
    Get trainer details by ID
    """
    if request.method == 'GET':
        try:
            trainer = Trainer.objects.get(id=trainer_id)
            
            return JsonResponse({
                'success': True,
                'id': trainer.id,
                'name': trainer.user.name,
                'email': trainer.user.emailid,
                'mobile': trainer.mobile,
                'gender': trainer.gender,
                'experience': trainer.experience,
                'specialization': trainer.specialization,
                'certification': trainer.certification,
                'goal_category': trainer.goal_category,
                'joining_period': trainer.joining_period,
                'is_active': trainer.is_active
            }, status=200)
            
        except Trainer.DoesNotExist:
            return JsonResponse({
                'success': False,
                'message': 'Trainer not found'
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
def get_trainer_details(request, trainer_id):
    '''Get trainer details by ID'''
    if request.method == 'GET':
        try:
            trainer = Trainer.objects.get(id=trainer_id)
            return JsonResponse({'success': True, 'id': trainer.id, 'name': trainer.user.name, 'email': trainer.user.emailid, 'mobile': trainer.mobile, 'gender': trainer.gender, 'experience': trainer.experience, 'specialization': trainer.specialization, 'certification': trainer.certification, 'goal_category': trainer.goal_category, 'joining_period': trainer.joining_period, 'is_active': trainer.is_active}, status=200)
        except Trainer.DoesNotExist:
            return JsonResponse({'success': False, 'message': 'Trainer not found'}, status=404)
        except Exception as e:
            return JsonResponse({'success': False, 'message': str(e)}, status=500)
    return JsonResponse({'success': False, 'message': 'Only GET method is allowed'}, status=405)


# ===== CHAT SYSTEM API ENDPOINTS =====

@csrf_exempt
def send_chat_message(request):
    """
    Send a chat message from user to trainer or trainer to user
    """
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            user_id = data.get('user_id')
            trainer_id = data.get('trainer_id')
            message = data.get('message')
            sender_type = data.get('sender_type')  # 'user' or 'trainer'
            
            if not all([user_id, trainer_id, message, sender_type]):
                return JsonResponse({
                    'success': False,
                    'message': 'user_id, trainer_id, message, and sender_type are required'
                }, status=400)
            
            user_profile = UserProfile.objects.get(user_id=user_id)
            trainer = Trainer.objects.get(id=trainer_id)
            
            # Create chat message
            chat_message = ChatMessage.objects.create(
                user=user_profile,
                trainer=trainer,
                message=message,
                sender_type=sender_type,
                is_read=False
            )
            
            return JsonResponse({
                'success': True,
                'message': 'Message sent successfully',
                'chat_message': {
                    'id': chat_message.id,
                    'message': chat_message.message,
                    'sender_type': chat_message.sender_type,
                    'created_at': chat_message.created_at.isoformat(),
                    'is_read': chat_message.is_read
                }
            }, status=201)
            
        except UserProfile.DoesNotExist:
            return JsonResponse({
                'success': False,
                'message': 'User profile not found'
            }, status=404)
        except Trainer.DoesNotExist:
            return JsonResponse({
                'success': False,
                'message': 'Trainer not found'
            }, status=404)
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
def get_chat_messages(request, user_id, trainer_id):
    """
    Get all chat messages between a user and trainer
    """
    if request.method == 'GET':
        try:
            user_profile = UserProfile.objects.get(user_id=user_id)
            trainer = Trainer.objects.get(id=trainer_id)
            
            messages = ChatMessage.objects.filter(
                user=user_profile,
                trainer=trainer
            ).order_by('created_at')
            
            messages_list = []
            for msg in messages:
                messages_list.append({
                    'id': msg.id,
                    'message': msg.message,
                    'sender_type': msg.sender_type,
                    'sender_name': user_profile.user.name if msg.sender_type == 'user' else trainer.user.name,
                    'is_read': msg.is_read,
                    'created_at': msg.created_at.isoformat()
                })
            
            # Mark all trainer messages as read by user (or vice versa)
            unread_messages = messages.exclude(sender_type=request.GET.get('reader_type', 'user'))
            unread_messages.update(is_read=True)
            
            return JsonResponse({
                'success': True,
                'messages': messages_list,
                'total_messages': len(messages_list)
            }, status=200)
            
        except UserProfile.DoesNotExist:
            return JsonResponse({
                'success': False,
                'message': 'User profile not found'
            }, status=404)
        except Trainer.DoesNotExist:
            return JsonResponse({
                'success': False,
                'message': 'Trainer not found'
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
def get_trainer_chats(request, trainer_id):
    """
    Get all users who have chatted with this trainer
    """
    if request.method == 'GET':
        try:
            trainer = Trainer.objects.get(id=trainer_id)
            
            # Get distinct users who have chatted with this trainer
            user_ids = ChatMessage.objects.filter(trainer=trainer).values_list('user_id', flat=True).distinct()
            
            chats_list = []
            for user_profile in UserProfile.objects.filter(id__in=user_ids):
                # Get last message
                last_message = ChatMessage.objects.filter(
                    user=user_profile,
                    trainer=trainer
                ).order_by('-created_at').first()
                
                # Count unread messages from user
                unread_count = ChatMessage.objects.filter(
                    user=user_profile,
                    trainer=trainer,
                    sender_type='user',
                    is_read=False
                ).count()
                
                # Convert UTC to local timezone for display
                last_message_time = timezone.localtime(last_message.created_at).strftime('%Y-%m-%d %H:%M:%S') if last_message else ''
                
                chats_list.append({
                    'user_id': user_profile.user.id,
                    'user_name': user_profile.user.name,
                    'user_email': user_profile.user.emailid,
                    'last_message': last_message.message if last_message else '',
                    'last_message_time': last_message_time,
                    'unread_count': unread_count
                })
            
            return JsonResponse({
                'success': True,
                'chats': chats_list,
                'total_chats': len(chats_list)
            }, status=200)
            
        except Trainer.DoesNotExist:
            return JsonResponse({
                'success': False,
                'message': 'Trainer not found'
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
def get_all_chats_admin(request):
    """
    Get all chat conversations for admin
    """
    if request.method == 'GET':
        try:
            # Get all distinct user-trainer pairs with proper distinct on both fields
            from django.db.models import Max
            
            # Get unique user-trainer pairs by grouping
            unique_pairs = ChatMessage.objects.values('user_id', 'trainer_id').annotate(
                last_message_time=Max('created_at')
            ).order_by('-last_message_time')
            
            chats_list = []
            seen_pairs = set()
            
            for pair in unique_pairs:
                pair_key = (pair['user_id'], pair['trainer_id'])
                
                # Skip if we've already seen this pair
                if pair_key in seen_pairs:
                    continue
                    
                seen_pairs.add(pair_key)
                
                user_profile = UserProfile.objects.get(id=pair['user_id'])
                trainer = Trainer.objects.get(id=pair['trainer_id'])
                
                # Get last message
                last_message = ChatMessage.objects.filter(
                    user_id=pair['user_id'],
                    trainer_id=pair['trainer_id']
                ).order_by('-created_at').first()
                
                # Get total message count
                message_count = ChatMessage.objects.filter(
                    user_id=pair['user_id'],
                    trainer_id=pair['trainer_id']
                ).count()
                
                # Convert UTC to local timezone for display
                last_message_time = timezone.localtime(last_message.created_at).strftime('%Y-%m-%d %H:%M:%S') if last_message else ''
                
                chats_list.append({
                    'user_id': user_profile.user.id,
                    'user_name': user_profile.user.name,
                    'user_email': user_profile.user.emailid,
                    'trainer_id': trainer.id,
                    'trainer_name': trainer.user.name,
                    'trainer_specialization': trainer.specialization,
                    'last_message': last_message.message if last_message else '',
                    'last_message_sender': last_message.sender_type if last_message else '',
                    'last_message_time': last_message_time,
                    'total_messages': message_count
                })
            
            return JsonResponse({
                'success': True,
                'chats': chats_list,
                'total_conversations': len(chats_list)
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
