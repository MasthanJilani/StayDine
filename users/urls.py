from django.urls import path
from . import views

urlpatterns = [
    path('', views.initiate_payment, name='initiate_payment'),
    path('confirm/', views.payment_confirm, name='payment-confirm'),
    path('success/', views.payment_success, name='payment_success'),

]