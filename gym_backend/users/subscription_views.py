import json
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.utils import timezone
from datetime import timedelta
from .models import UserLogin, UserProfile, SubscriptionRenewal


@csrf_exempt
def get_subscription_status(request, user_id):
    """Get subscription status for a user"""
    if request.method == 'GET':
        try:
            user = UserLogin.objects.get(id=user_id)
            profile = UserProfile.objects.get(user=user)
            
            is_active = profile.is_subscription_active()
            remaining_days = profile.get_remaining_days()
            
            # Calculate if subscription is expiring soon (within 7 days)
            expiring_soon = False
            if is_active and remaining_days <= 7:
                expiring_soon = True
            
            # Calculate if subscription has already expired
            is_expired = profile.subscription_end_date and profile.subscription_end_date < timezone.now()
            
            return JsonResponse({
                'success': True,
                'subscription': {
                    'is_active': is_active,
                    'is_expired': is_expired,
                    'expiring_soon': expiring_soon,
                    'remaining_days': remaining_days,
                    'subscription_start_date': profile.subscription_start_date.isoformat() if profile.subscription_start_date else None,
                    'subscription_end_date': profile.subscription_end_date.isoformat() if profile.subscription_end_date else None,
                    'target_months': profile.target_months,
                    'can_renew': is_expired or remaining_days <= 7,
                    'payment_status': profile.payment_status
                }
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
        'message': 'Only GET method is allowed'
    }, status=405)


@csrf_exempt
def renew_subscription(request):
    """Renew subscription for a user"""
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            user_id = data.get('user_id')
            renewal_months = data.get('renewal_months')  # Months to renew (1, 2, 3, 6, 8, 12)
            payment_method = data.get('payment_method', '')
            
            if not user_id or not renewal_months:
                return JsonResponse({
                    'success': False,
                    'message': 'User ID and renewal months are required'
                }, status=400)
            
            user = UserLogin.objects.get(id=user_id)
            profile = UserProfile.objects.get(user=user)
            
            # Get the renewal amount based on months
            renewal_amount_map = {
                1: 399,
                2: 499,
                3: 699,
                6: 1199,
                8: 1599,
                12: 2199,
            }
            
            renewal_amount = renewal_amount_map.get(renewal_months, 0)
            if renewal_amount == 0:
                return JsonResponse({
                    'success': False,
                    'message': 'Invalid renewal months'
                }, status=400)
            
            # Extend subscription
            now = timezone.now()
            if profile.subscription_end_date and profile.subscription_end_date > now:
                # If subscription is still active, extend from current end date
                new_end_date = profile.subscription_end_date + timedelta(days=renewal_months * 30)
            else:
                # If subscription is expired, reset and add from today
                profile.subscription_start_date = now
                new_end_date = now + timedelta(days=renewal_months * 30)
            
            profile.subscription_end_date = new_end_date
            profile.payment_status = True
            profile.payment_date = now
            if payment_method:
                profile.payment_method = payment_method
            profile.save()

            # Record renewal history
            SubscriptionRenewal.objects.create(
                user=user,
                months=renewal_months,
                amount=renewal_amount,
                payment_method=payment_method or None,
            )
            
            return JsonResponse({
                'success': True,
                'message': 'Subscription renewed successfully',
                'renewal_amount': renewal_amount,
                'new_end_date': new_end_date.isoformat(),
                'renewal_days': renewal_months * 30
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
