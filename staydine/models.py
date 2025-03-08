from django.db import models

# Create your models here.
class Highlights(models.Model):
    title = models.CharField(max_length=100)
    description = models.TextField()
    image_url = models.URLField(max_length=1000)

    def __str__(self):
        return self.title

class Contact(models.Model):
    name=models.CharField(max_length=122)
    email=models.EmailField(max_length=254)
    phone=models.CharField(max_length=10)
    desc=models.TextField()
    date=models.DateField()
    def _str_(self):
        return self.name
    
class Dining(models.Model):    
    email = models.EmailField(max_length=254, unique=True, primary_key=True)
    item_no=models.IntegerField()
    quantity=models.IntegerField()  

    def __str__(self):
        return self.email
    
class RoomType(models.Model):
    name = models.CharField(max_length=100)
    price_per_night = models.DecimalField(max_digits=10, decimal_places=2)
    description = models.TextField()
    image_url = models.URLField(max_length=1000)
    
    def __str__(self):
        return self.name

class BedType(models.Model):
    name = models.CharField(max_length=50, primary_key=True)

    def __str__(self):
        return self.name

class Accommodation(models.Model):
   

    email = models.EmailField(max_length=254, primary_key=True, serialize=False, unique=True)
    room = models.ForeignKey(RoomType, on_delete=models.CASCADE)
    bed_type = models.ForeignKey(BedType, on_delete=models.CASCADE)
    start_date = models.DateField()
    end_date = models.DateField()

    def __str__(self):
        return f"{self.room} booked by {self.email} from {self.start_date} to {self.end_date}"

    
class MenuItem(models.Model):
    CATEGORY_CHOICES = [
        ('Pizza', 'Pizza'),
        ('Beverages', 'Beverages'),
        ('South Indian', 'South Indian'),
        ('Starters', 'Starters'),
        ('Dessert', 'Dessert'),
        ('North Indian', 'North Indian'),
    ]
    
    title = models.CharField(max_length=100)
    category = models.CharField(max_length=50, choices=CATEGORY_CHOICES,default='Beverages')
    description = models.TextField()
    image_url = models.URLField(max_length=1000)
    price = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)

    def __str__(self):
        return self.title

class Order(models.Model):
    email = models.EmailField(max_length=254)
    created_at = models.DateTimeField(auto_now_add=True)
    total_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)

    def __str__(self):
        return f"Order {self.id} by {self.email} on {self.created_at}"

class OrderItem(models.Model):
    order = models.ForeignKey(Order, related_name='items', on_delete=models.CASCADE)
    menu_item = models.ForeignKey(MenuItem, on_delete=models.CASCADE)
    quantity = models.IntegerField()

    def __str__(self):
        return f"{self.quantity} x {self.menu_item.title} for Order {self.order.id}"