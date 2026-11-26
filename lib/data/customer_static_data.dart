import '../models/hotel_model.dart';

/// Structured static fallback data for the Customer Stay funnel, City Guide, and Wishlist.
class CustomerStaticData {
  CustomerStaticData._();

  static const List<Map<String, dynamic>> stayRoomOptions = [
    {
      'id': 'room_deluxe_01',
      'title': 'Deluxe King Room',
      'recommendedFor': 'Recommended for 2 Adults',
      'bedInfo': '1 King Bed • 320 sq.ft • City View',
      'amenities': ['Free Wi-Fi', 'Breakfast Included', 'AC', 'Smart TV'],
      'pricePerNight': 3499.0,
      'originalPrice': 4200.0,
      'taxes': 420.0,
      'freeCancellation': true,
      'image': 'assets/images/image 27.png',
    },
    {
      'id': 'room_exec_02',
      'title': 'Executive Suite with Balcony',
      'recommendedFor': 'Recommended for Families (3 Guests)',
      'bedInfo': '1 King Bed + Sofa Bed • 480 sq.ft • Pool View',
      'amenities': ['Free Wi-Fi', 'Breakfast & Dinner', 'Balcony', 'Mini Bar'],
      'pricePerNight': 5299.0,
      'originalPrice': 6400.0,
      'taxes': 636.0,
      'freeCancellation': true,
      'image': 'assets/images/image 27.png',
    },
    {
      'id': 'room_premium_03',
      'title': 'Presidential Heritage Suite',
      'recommendedFor': 'Recommended for 4 Guests',
      'bedInfo': '2 Bedrooms • 760 sq.ft • Lounge Access',
      'amenities': ['Free Wi-Fi', 'All Meals', 'Airport Pickup', 'Spa Access'],
      'pricePerNight': 8499.0,
      'originalPrice': 9999.0,
      'taxes': 1020.0,
      'freeCancellation': false,
      'image': 'assets/images/image 27.png',
    },
  ];

  static HotelRoom roomFromMap(Map<String, dynamic> map) {
    return HotelRoom(
      id: map['id'].toString(),
      title: map['title'].toString(),
      priceFormatted: '₹ ${(map['pricePerNight'] as num).toInt()}/-',
      pricePerNight: (map['pricePerNight'] as num).toDouble(),
      specs: map['bedInfo'].toString(),
      amenities: (map['amenities'] as List<dynamic>).join(' • '),
      image: map['image'].toString(),
    );
  }

  static const Map<String, dynamic> hyderabadCityGuide = {
    'city': 'Hyderabad',
    'tagline': 'City of Pearls, Heritage & Grand Celebrations',
    'about':
        'Hyderabad blends centuries-old royal heritage around Charminar and Golconda Fort with modern luxury stays and grand convention centers across Jubilee Hills, Banjara Hills, and HITEC City.',
    'nearbyStays': [
      {
        'name': 'Sri Meghana Grand Hotel',
        'area': 'Madhapur, Hyderabad',
        'rating': 4.7,
        'price': '₹ 3,499 / night',
        'image': 'assets/images/image 27.png',
      },
      {
        'name': 'Aranya Heritage Retreat',
        'area': 'Banjara Hills, Hyderabad',
        'rating': 4.8,
        'price': '₹ 4,850 / night',
        'image': 'assets/images/image 27.png',
      },
    ],
    'nearbyHalls': [
      {
        'name': 'Royal Palace Convention Hall',
        'area': 'Gachibowli, Hyderabad',
        'rating': 4.9,
        'capacity': '1,500 Guests',
        'price': '₹ 85,000 / slot',
        'image': 'assets/images/image 27.png',
      },
      {
        'name': 'Deccan Greens Banquet & Lawn',
        'area': 'Jubilee Hills, Hyderabad',
        'rating': 4.6,
        'capacity': '800 Guests',
        'price': '₹ 65,000 / slot',
        'image': 'assets/images/image 27.png',
      },
    ],
    'reviews': [
      {
        'author': 'Ananya Sharma',
        'rating': 4.9,
        'comment': 'Seamless stay booking near HITEC City. Quick check-in and spotless rooms.',
      },
      {
        'author': 'Karthik Reddy',
        'rating': 4.7,
        'comment': 'Booked a convention hall for a family reception — pricing was transparent.',
      },
    ],
    'faqs': [
      {
        'q': 'What is the best time to visit Hyderabad?',
        'a': 'October to March offers pleasant evenings ideal for heritage tours and outdoor lawn events.',
      },
      {
        'q': 'Do Zaatra stays allow flexible check-in?',
        'a': 'Most partner stays support early check-in requests via Host Chat prior to arrival.',
      },
      {
        'q': 'How does 50% advance booking work?',
        'a': 'Pay 50% online via Zaatra to lock your dates, and pay the remaining 50% directly at the venue.',
      },
    ],
  };

  static const List<Map<String, dynamic>> wishlistItems = [
    {
      'id': 'w1',
      'category': 'Stays',
      'title': 'Sri Meghana Grand Hotel',
      'subtitle': 'Madhapur, Hyderabad • Deluxe King',
      'rating': 4.7,
      'price': '₹ 3,499 / night',
      'image': 'assets/images/image 27.png',
    },
    {
      'id': 'w2',
      'category': 'Event halls',
      'title': 'Royal Palace Convention Hall',
      'subtitle': 'Gachibowli • Up to 1,500 Guests',
      'rating': 4.9,
      'price': '₹ 85,000 / slot',
      'image': 'assets/images/image 27.png',
    },
    {
      'id': 'w3',
      'category': 'Rider',
      'title': 'Hyderabad → Vijayawada Intercity',
      'subtitle': 'Toyota Innova Crysta • AC Sedan/SUV',
      'rating': 4.8,
      'price': '₹ 1,150 / seat',
      'image': 'assets/images/image 27.png',
    },
    {
      'id': 'w4',
      'category': 'Stays',
      'title': 'Aranya Heritage Villa',
      'subtitle': 'Banjara Hills • 3 BHK Private Villa',
      'rating': 4.8,
      'price': '₹ 6,200 / night',
      'image': 'assets/images/image 27.png',
    },
  ];
}
