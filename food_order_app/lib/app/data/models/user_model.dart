import 'customer_address_model.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? token;
  final int loyaltyPoints;
  final String? address;
  final List<CustomerAddressModel> addresses;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.token,
    this.loyaltyPoints = 120,
    this.address,
    this.addresses = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    var rawAddresses = json['addresses'] as List? ?? [];
    List<CustomerAddressModel> parsedAddresses =
        rawAddresses.map((a) => CustomerAddressModel.fromJson(a)).toList();

    final username = json['username']?.toString() ?? '';
    final isEmailUsername = username.contains('@');

    final extractedPhone = json['phone']?.toString() ??
        json['phoneNumber']?.toString() ??
        (!isEmailUsername && username.isNotEmpty ? username : '');

    final extractedEmail = json['email']?.toString() ??
        (isEmailUsername ? username : '');

    return UserModel(
      id: json['id']?.toString() ?? json['userId']?.toString() ?? json['customerId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Gourmet Customer',
      email: extractedEmail,
      phone: extractedPhone,
      token: json['token']?.toString() ?? json['jwtToken']?.toString(),
      loyaltyPoints: json['loyaltyPoints'] ?? 120,
      address: json['address']?.toString() ?? (parsedAddresses.isNotEmpty ? parsedAddresses.first.fullAddress : ''),
      addresses: parsedAddresses,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'token': token,
      'loyaltyPoints': loyaltyPoints,
      'address': address,
      'addresses': addresses.map((a) => a.toJson()).toList(),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? token,
    int? loyaltyPoints,
    String? address,
    List<CustomerAddressModel>? addresses,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      token: token ?? this.token,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      address: address ?? this.address,
      addresses: addresses ?? this.addresses,
    );
  }
}
