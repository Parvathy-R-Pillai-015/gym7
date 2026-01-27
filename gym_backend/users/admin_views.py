from django.shortcuts import render
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.utils import timezone
import json
from .models import UserLogin, Trainer, UserProfile, SubscriptionRenewal

# Admin API Views

@csrf_exempt
def get_all_users(request):
    """Get all registered users with their profile and payment status"""
    if request.method == 'GET':
        try:
            users = UserLogin.objects.filter(role='user').order_by('-created_at')
            user_list = []
            
            for user in users:
                try:
                    profile = UserProfile.objects.get(user=user)
                    trainer_name = profile.assigned_trainer.user.name if profile.assigned_trainer else None
                    remaining_days = profile.get_remaining_days() if profile.payment_status else 0
                    user_data = {
                        'id': user.id,
                        'name': user.name,
                        'email': user.emailid,
                        'mobile': profile.mobile_number,
                        'age': profile.age,
                        'gender': profile.gender,
                        'goal': profile.goal,
                        'payment_status': profile.payment_status,
                        'payment_amount': profile.payment_amount,
                        'payment_method': profile.payment_method,
                        'assigned_trainer': trainer_name,
                        'subscription_start_date': profile.subscription_start_date.isoformat() if profile.subscription_start_date else None,
                        'subscription_end_date': profile.subscription_end_date.isoformat() if profile.subscription_end_date else None,
                        'subscription_status': 'active' if profile.is_subscription_active() else 'expired',
                        'remaining_days': remaining_days,
                        'created_at': user.created_at.strftime('%Y-%m-%d %H:%M:%S')
                    }
                except UserProfile.DoesNotExist:
                    user_data = {
                        'id': user.id,
                        'name': user.name,
                        'email': user.emailid,
                        'mobile': None,
                        'age': None,
                        'gender': None,
                        'goal': None,
                        'payment_status': False,
                        'payment_amount': 0,
                        'payment_method': None,
                        'assigned_trainer': None,
                        'created_at': user.created_at.strftime('%Y-%m-%d %H:%M:%S')
                    }
                
                user_list.append(user_data)
            
            return JsonResponse({
                'success': True,
                'users': user_list,
                'total': len(user_list)
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
def get_paid_users(request):
    """Get all users who have completed payment with full details"""
    if request.method == 'GET':
        try:
            profiles = UserProfile.objects.filter(payment_status=True).select_related('user', 'assigned_trainer').order_by('-updated_at')
            user_list = []
            
            for profile in profiles:
                user = profile.user
                trainer = profile.assigned_trainer
                
                # Prepare trainer data with full details
                trainer_data = None
                if trainer:
                    trainer_data = {
                        'id': trainer.id,
                        'name': trainer.user.name,
                        'email': trainer.user.emailid,
                        'mobile': trainer.mobile,
                        'gender': trainer.gender,
                        'experience': trainer.experience,
                        'specialization': trainer.specialization,
                        'certification': trainer.certification or 'Not Specified',
                        'goal_category': trainer.goal_category
                    }
                
                remaining_days = profile.get_remaining_days()
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
                    'workout_time': profile.workout_time,
                    'diet_preference': profile.diet_preference,
                    'food_allergies': profile.food_allergies,
                    'health_conditions': profile.health_conditions,
                    'payment_amount': profile.payment_amount,
                    'payment_method': profile.payment_method or 'Not Recorded',
                    'assigned_trainer': trainer_data,
                    'subscription_start_date': profile.subscription_start_date.isoformat() if profile.subscription_start_date else None,
                    'subscription_end_date': profile.subscription_end_date.isoformat() if profile.subscription_end_date else None,
                    'subscription_status': 'active' if profile.is_subscription_active() else 'expired',
                    'remaining_days': remaining_days,
                    'payment_date': timezone.localtime(profile.payment_date).strftime('%Y-%m-%d %H:%M:%S') if profile.payment_date else timezone.localtime(profile.updated_at).strftime('%Y-%m-%d %H:%M:%S'),
                    'joined_date': timezone.localtime(user.created_at).strftime('%Y-%m-%d')
                }
                # Include recent renewal history
                renewals = SubscriptionRenewal.objects.filter(user=user).order_by('-renewed_at')[:5]
                user_data['renewals'] = [
                    {
                        'months': r.months,
                        'amount': r.amount,
                        'payment_method': r.payment_method or 'Not Recorded',
                        'renewed_at': timezone.localtime(r.renewed_at).strftime('%Y-%m-%d %H:%M:%S'),
                    }
                    for r in renewals
                ]
                user_list.append(user_data)
            
            return JsonResponse({
                'success': True,
                'users': user_list,
                'total': len(user_list)
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
def get_unpaid_users(request):
    """Get all users who have not completed payment"""
    if request.method == 'GET':
        try:
            # Get users with profiles but no payment
            profiles = UserProfile.objects.filter(payment_status=False).select_related('user').order_by('-created_at')
            user_list = []
            
            for profile in profiles:
                user = profile.user
                user_data = {
                    'id': user.id,
                    'name': user.name,
                    'email': user.emailid,
                    'mobile': profile.mobile_number,
                    'age': profile.age,
                    'gender': profile.gender,
                    'goal': profile.goal,
                    'target_months': profile.target_months,
                    'payment_amount': profile.payment_amount,
                    'created_at': user.created_at.strftime('%Y-%m-%d %H:%M:%S')
                    # Note: payment_method and assigned_trainer are NOT included for unpaid users
                }
                user_list.append(user_data)
            
            return JsonResponse({
                'success': True,
                'users': user_list,
                'total': len(user_list)
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
def get_trainers_by_goal(request, goal):
    """Get trainers assigned to a specific goal category"""
    if request.method == 'GET':
        try:
            trainers = Trainer.objects.filter(
                goal_category=goal,
                is_active=True
            ).select_related('user').all()[:2]  # Limit to 2 trainers per category
            
            trainer_list = []
            for trainer in trainers:
                trainer_data = {
                    'id': trainer.id,
                    'name': trainer.user.name,
                    'email': trainer.user.emailid,
                    'mobile': trainer.mobile,
                    'specialization': trainer.specialization,
                    'experience': trainer.experience,
                    'certification': trainer.certification,
                    'goal_category': trainer.goal_category
                }
                trainer_list.append(trainer_data)
            
            return JsonResponse({
                'success': True,
                'trainers': trainer_list,
                'goal': goal,
                'total': len(trainer_list)
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
def get_all_trainers(request):
    """Get all trainers with their assigned goal categories"""
    if request.method == 'GET':
        try:
            trainers = Trainer.objects.select_related('user').all()
            trainer_list = []
            
            for trainer in trainers:
                # Count assigned users
                assigned_count = UserProfile.objects.filter(assigned_trainer=trainer).count()
                
                trainer_data = {
                    'id': trainer.id,
                    'name': trainer.user.name,
                    'email': trainer.user.emailid,
                    'mobile': trainer.mobile,
                    'gender': trainer.gender,
                    'experience': trainer.experience,
                    'specialization': trainer.specialization,
                    'certification': trainer.certification or 'Not Specified',
                    'goal_category': trainer.goal_category,
                    'is_active': trainer.is_active,
                    'assigned_users_count': assigned_count,
                    'created_at': trainer.created_at.strftime('%Y-%m-%d')
                }
                trainer_list.append(trainer_data)
            
            return JsonResponse({
                'success': True,
                'trainers': trainer_list,
                'total': len(trainer_list)
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
def assign_trainer_to_goal(request):
    """Assign a trainer to a goal category (max 2 per category)"""
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            trainer_id = data.get('trainer_id')
            goal_category = data.get('goal_category')
            
            if not trainer_id or not goal_category:
                return JsonResponse({
                    'success': False,
                    'message': 'Trainer ID and goal category are required'
                }, status=400)
            
            # Check if category already has 2 trainers
            current_trainers_count = Trainer.objects.filter(
                goal_category=goal_category,
                is_active=True
            ).count()
            
            if current_trainers_count >= 2:
                return JsonResponse({
                    'success': False,
                    'message': f'This category already has 2 trainers assigned. Please remove one first.'
                }, status=400)
            
            trainer = Trainer.objects.get(id=trainer_id)
            trainer.goal_category = goal_category
            trainer.is_active = True
            trainer.save()
            
            return JsonResponse({
                'success': True,
                'message': f'Trainer assigned to {goal_category} successfully',
                'trainer': {
                    'id': trainer.id,
                    'name': trainer.user.name,
                    'goal_category': trainer.goal_category
                }
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
        'message': 'Only POST method is allowed'
    }, status=405)


@csrf_exempt
def create_trainer(request):
    """Admin can create a new trainer account"""
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            name = data.get('name')
            emailid = data.get('emailid')
            mobile = data.get('mobile')
            gender = data.get('gender')
            experience = data.get('experience')
            specialization = data.get('specialization')
            certification = data.get('certification', '')
            
            if not all([name, emailid, mobile, gender, experience, specialization]):
                return JsonResponse({
                    'success': False,
                    'message': 'All required fields must be provided'
                }, status=400)
            
            # Check if email already exists
            if UserLogin.objects.filter(emailid=emailid).exists():
                return JsonResponse({
                    'success': False,
                    'message': 'Email already exists'
                }, status=400)
            
            # Validate mobile number
            if len(mobile) != 10 or not mobile.isdigit():
                return JsonResponse({
                    'success': False,
                    'message': 'Mobile number must be 10 digits'
                }, status=400)
            
            # Generate password: trainername+tr
            password = name.lower().replace(' ', '') + '+tr'
            
            # Create UserLogin account
            user = UserLogin.objects.create(
                name=name,
                emailid=emailid,
                password=password,
                role='trainer'
            )
            
            # Create Trainer profile
            trainer = Trainer.objects.create(
                user=user,
                mobile=mobile,
                gender=gender,
                experience=experience,
                specialization=specialization,
                certification=certification,
                is_active=True
            )
            
            return JsonResponse({
                'success': True,
                'message': 'Trainer created successfully',
                'trainer': {
                    'id': trainer.id,
                    'name': user.name,
                    'email': user.emailid,
                    'mobile': trainer.mobile,
                    'password': password  # Return password so admin can share it
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
def remove_trainer_from_goal(request):
    """Remove a trainer from their assigned goal category"""
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            trainer_id = data.get('trainer_id')
            
            if not trainer_id:
                return JsonResponse({
                    'success': False,
                    'message': 'Trainer ID is required'
                }, status=400)
            
            trainer = Trainer.objects.get(id=trainer_id)
            trainer.goal_category = None
            trainer.save()
            
            return JsonResponse({
                'success': True,
                'message': 'Trainer removed from goal category successfully'
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
        'message': 'Only POST method is allowed'
    }, status=405)
