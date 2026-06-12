// lib/models/contact.dart

class Contact {
  final String name;
  final String mobileNo;
  final String image;

  Contact({
    required this.name,
    required this.mobileNo,
    required this.image,
  });

  // A factory method to easily create a Contact from a map
  factory Contact.fromMap(Map<String, String> map) {
    return Contact(
      name: map['name']!,
      mobileNo: map['mobile_no']!,
      image: map['img']!,
    );
  }

  // Static method to get the dummy data
  static List<Contact> getDummyContacts() {
    return [
      Contact.fromMap({
        'img': 'https://i.postimg.cc/g25VYN7X/user-1.png',
        'name': 'Darlene Robert',
        'mobile_no': '+63-955-9741-420',
      }),
      Contact.fromMap({
        'img': 'https://i.postimg.cc/cCsYDjvj/user-2.png',
        'name': 'John Doe',
        'mobile_no': '234-567-8901',
      }),
      Contact.fromMap({
        'img': 'https://i.postimg.cc/sXC5W1s3/user-3.png',
        'name': 'Alice Smith',
        'mobile_no': '345-678-9012',
      }),
      Contact.fromMap({
        'img': 'https://i.postimg.cc/4dvVQZxV/user-4.png',
        'name': 'Robert Johnson',
        'mobile_no': '456-789-0123',
      }),
      Contact.fromMap({
        'img': 'https://i.postimg.cc/FzDSwZcK/user-5.png',
        'name': 'Emma Davis',
        'mobile_no': '567-890-1234',
      }),
    ];
  }
}
