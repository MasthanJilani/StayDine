from django.urls import path
from . import views

urlpatterns = [
    path('', views.home, name='staydine-home'),
    path('about/', views.about, name='staydine-about'),
    path('contact/', views.contact, name='staydine-contact'),
    path("services/",views.services,name='staydine-services'),
    path("bookings/",views.bookings,name='staydine-room-bookings'),
    path("restaurant/", views.restaurant, name='staydine-restaurant'),
    path('bed-types/', views.bed_types, name='staydine-bed-types'),
]
# urlpatterns = [
#     path("events",views.events,name='events'),
# ]