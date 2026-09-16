class CustomerAddressModel {
  final String? addressId;
  final String? customerId;
  final String label; // "Home", "Work", "Other"
  final String houseNo;
  final String street;
  final String landmark;
  final String city;
  final String state;
  final String pincode;
  final String fullAddress;
  final bool isDefault;
  final double? latitude;
  final double? longitude;

  CustomerAddressModel({
    this.addressId,
    this.customerId,
    this.label = 'Home',
    this.houseNo = '',
    this.street = '',
    this.landmark = '',
    this.city = '',
    this.state = '',
    this.pincode = '',
    required this.fullAddress,
    this.isDefault = false,
    this.latitude,
    this.longitude,
  });

  factory CustomerAddressModel.fromJson(Map<String, dynamic> json) {
    String computedFull = json['fullAddress']?.toString() ?? json['address']?.toString() ?? '';
    if (computedFull.isEmpty) {
      List<String> parts = [
        json['houseNo']?.toString() ?? '',
        json['street']?.toString() ?? '',
        json['landmark']?.toString() ?? '',
        json['city']?.toString() ?? '',
        json['pincode']?.toString() ?? '',
      ].where((p) => p.isNotEmpty).toList();
      computedFull = parts.join(', ');
    }

    return CustomerAddressModel(
      addressId: json['addressId']?.toString() ?? json['id']?.toString(),
      customerId: json['customerId']?.toString(),
      label: json['label']?.toString() ?? 'Home',
      houseNo: json['houseNo']?.toString() ?? '',
      street: json['street']?.toString() ?? '',
      landmark: json['landmark']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      fullAddress: computedFull,
      isDefault: json['isDefault'] ?? json['default'] ?? false,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (addressId != null) 'addressId': addressId,
      if (customerId != null) 'customerId': customerId,
      'label': label,
      'houseNo': houseNo,
      'street': street,
      'landmark': landmark,
      'city': city,
      'state': state,
      'pincode': pincode,
      'fullAddress': fullAddress,
      'isDefault': isDefault,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }

  CustomerAddressModel copyWith({
    String? addressId,
    String? customerId,
    String? label,
    String? houseNo,
    String? street,
    String? landmark,
    String? city,
    String? state,
    String? pincode,
    String? fullAddress,
    bool? isDefault,
    double? latitude,
    double? longitude,
  }) {
    return CustomerAddressModel(
      addressId: addressId ?? this.addressId,
      customerId: customerId ?? this.customerId,
      label: label ?? this.label,
      houseNo: houseNo ?? this.houseNo,
      street: street ?? this.street,
      landmark: landmark ?? this.landmark,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      fullAddress: fullAddress ?? this.fullAddress,
      isDefault: isDefault ?? this.isDefault,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
