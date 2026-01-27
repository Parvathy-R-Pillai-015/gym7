from django.db import migrations, models
from django.utils import timezone


def backfill_payment_dates(apps, schema_editor):
    UserProfile = apps.get_model('users', 'UserProfile')
    for profile in UserProfile.objects.filter(payment_status=True):
        # Prefer existing subscription_start_date, fallback to updated_at
        payment_date = profile.subscription_start_date or profile.updated_at
        profile.payment_date = payment_date
        profile.save(update_fields=['payment_date'])


def remove_payment_dates(apps, schema_editor):
    # No-op rollback handler
    pass


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0018_populate_subscription_dates'),
    ]

    operations = [
        migrations.AddField(
            model_name='userprofile',
            name='payment_date',
            field=models.DateTimeField(blank=True, null=True, verbose_name='Last Payment Date'),
        ),
        migrations.RunPython(backfill_payment_dates, remove_payment_dates),
    ]
