from django.shortcuts import render
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
import json
from .models import UserLogin, Trainer

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
                return JsonResponse({
                    'success': True,
                    'message': 'Login successful',
                    'user': {
                        'id': user.id,
                        'name': user.name,
                        'emailid': user.emailid,
                        'role': user.role
                    }
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
