import stripe
from django.shortcuts import render, redirect
from django.contrib import messages
from django.conf import settings
# from django.contrib.auth import logout
from django.contrib.auth.decorators import login_required
from .forms import UserRegisterForm, UserUpdateForm, ProfileUpdateForm, PaymentForm
from .models import Payment

# Create your views here.
def register(request):
    if request.method == 'POST':
        form = UserRegisterForm(request.POST)
        if form.is_valid():
            form.save()
            username = form.cleaned_data.get('username')
            messages.success(request, f'Account created for {username}! You can now log in!')
            return redirect('login')
    else:
        form = UserRegisterForm()
    return render(request, 'users/register.html', {'form': form, 'title': 'Registration'})

# def logout_view(request):
#     logout(request)
#     return render(request, 'users/logout.html')

@login_required
def profile(request):
    if request.method == 'POST':
        u_form = UserUpdateForm(request.POST, instance=request.user)
        p_form = ProfileUpdateForm(request.POST, request.FILES, instance=request.user.profile)
        if u_form.is_valid() and p_form.is_valid():
            u_form.save()
            p_form.save()
            messages.success(request, f'Your Account has been Updated!')
            return redirect('profile')
        
    else:
        u_form = UserUpdateForm(instance=request.user)
        p_form = ProfileUpdateForm(instance=request.user.profile)

    context = {
        'u_form': u_form,
        'p_form': p_form
    }
    return render(request, 'users/profile.html', context)

stripe.api_key = settings.STRIPE_SECRET_KEY

@login_required
def initiate_payment(request):
    amount = request.GET.get('amount', 0)
    if request.method == 'POST':
        form = PaymentForm(request.POST)
        if form.is_valid():
            amount = form.cleaned_data['amount']
            try:
                intent = stripe.PaymentIntent.create(
                    amount=int(amount * 100),
                    currency='usd',
                    payment_method_types=['card'],
                )
                payment = Payment.objects.create(
                    user=request.user,
                    amount=amount,
                    status='Pending',
                    transaction_id=intent['id']
                )
                return render(request, 'users/payment_confirm.html', {
                    'client_secret': intent.client_secret,
                    'stripe_publishable_key': settings.STRIPE_PUBLISHABLE_KEY,
                    'payment': payment,
                })
            except Exception as e:
                messages.error(request, "An error occurred. Please try again.")
                return redirect('initiate_payment')
    else:
        form = PaymentForm(initial={'amount': amount})

    return render(request, 'users/payment.html', {'form': form, 'title': 'Payment Page', 'amount': amount})

def payment_success(request):
    transaction_id = request.GET.get('transaction_id')
    if transaction_id:
        payment = Payment.objects.filter(transaction_id=transaction_id).first()
        if payment:
            payment.status = 'Completed'
            payment.save()
            messages.success(request, "Payment was successful!")
    return render(request, 'users/payment_success.html')

def payment_confirm(request):
    return render(request, 'users/payment_confirm.html', {'title': 'Confirmation Page'})
