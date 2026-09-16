class DeliveryPartner {
  final String partnerId;
  final String name;
  final String phone;
  final String? email;
  final String? vehicleNumber;
  final String? vehicleType;
  final String status; // OFFLINE, ONLINE, ON_DELIVERY
  final double? currentLat;
  final double? currentLng;
  final String? lastLocationUpdate;
  final String? outletId;
  final double rating;
  final int totalDeliveries;
  final bool isApproved;
  final bool isActive;

  DeliveryPartner({
    required this.partnerId,
    required this.name,
    required this.phone,
    this.email,
    this.vehicleNumber,
    this.vehicleType,
    required this.status,
    this.currentLat,
    this.currentLng,
    this.lastLocationUpdate,
    this.outletId,
    this.rating = 5.0,
    this.totalDeliveries = 0,
    this.isApproved = true,
    this.isActive = true,
  });

  bool get isOnline => status == 'ONLINE';
  bool get isOnDelivery => status == 'ON_DELIVERY';
  bool get isOffline => status == 'OFFLINE';

  factory DeliveryPartner.fromJson(Map<String, dynamic> json) {
    return DeliveryPartner(
      partnerId: json['partnerId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Rider',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
      vehicleNumber: json['vehicleNumber']?.toString() ?? '',
      vehicleType: json['vehicleType']?.toString() ?? 'BIKE',
      status: json['status']?.toString() ?? 'OFFLINE',
      currentLat: json['currentLat'] != null ? (json['currentLat'] as num).toDouble() : null,
      currentLng: json['currentLng'] != null ? (json['currentLng'] as num).toDouble() : null,
      lastLocationUpdate: json['lastLocationUpdate']?.toString(),
      outletId: json['outletId']?.toString(),
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : 5.0,
      totalDeliveries: json['totalDeliveries'] != null ? (json['totalDeliveries'] as num).toInt() : 0,
      isApproved: json['isApproved'] as bool? ?? true,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'partnerId': partnerId,
      'name': name,
      'phone': phone,
      'email': email,
      'vehicleNumber': vehicleNumber,
      'vehicleType': vehicleType,
      'status': status,
      'currentLat': currentLat,
      'currentLng': currentLng,
      'lastLocationUpdate': lastLocationUpdate,
      'outletId': outletId,
      'rating': rating,
      'totalDeliveries': totalDeliveries,
      'isApproved': isApproved,
      'isActive': isActive,
    };
  }

  DeliveryPartner copyWith({
    String? status,
    double? currentLat,
    double? currentLng,
    int? totalDeliveries,
    double? rating,
  }) {
    return DeliveryPartner(
      partnerId: partnerId,
      name: name,
      phone: phone,
      email: email,
      vehicleNumber: vehicleNumber,
      vehicleType: vehicleType,
      status: status ?? this.status,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      lastLocationUpdate: lastLocationUpdate,
      outletId: outletId,
      rating: rating ?? this.rating,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      isApproved: isApproved,
      isActive: isActive,
    );
  }
}
