class DeliveryAssignment {
  final String assignmentId;
  final String orderId;
  final String orderNumber;
  final String partnerId;
  final String? partnerName;
  final String? partnerPhone;
  final String status; // ASSIGNED, ACCEPTED, PICKED_UP, DELIVERED, REJECTED
  final String? assignedAt;
  final String? acceptedAt;
  final String? pickedUpAt;
  final String? deliveredAt;
  final String deliveryAddress;
  final String customerPhone;
  final String customerName;
  final String restaurantName;
  final String? otpCode;
  final String? deliveryNotes;
  final double deliveryFee;
  final double tipAmount;
  final String? itemSummary;
  final int itemsCount;
  final double? deliveryLat;
  final double? deliveryLng;
  final String? estimatedDeliveryTime;
  final double totalOrderAmount;

  DeliveryAssignment({
    required this.assignmentId,
    required this.orderId,
    String? orderNumber,
    required this.partnerId,
    this.partnerName,
    this.partnerPhone,
    required this.status,
    this.assignedAt,
    this.acceptedAt,
    this.pickedUpAt,
    this.deliveredAt,
    required this.deliveryAddress,
    required this.customerPhone,
    String? customerName,
    String? restaurantName,
    this.otpCode,
    this.deliveryNotes,
    this.deliveryFee = 40.0,
    this.tipAmount = 0.0,
    this.itemSummary,
    this.itemsCount = 0,
    this.deliveryLat,
    this.deliveryLng,
    this.estimatedDeliveryTime,
    this.totalOrderAmount = 0.0,
  })  : orderNumber = (orderNumber != null && orderNumber.isNotEmpty)
            ? orderNumber
            : (orderId.length > 6 ? 'ORD-${orderId.substring(0, 6).toUpperCase()}' : 'ORD-$orderId'),
        customerName = (customerName != null && customerName.trim().isNotEmpty) ? customerName.trim() : 'Customer',
        restaurantName = (restaurantName != null && restaurantName.trim().isNotEmpty) ? restaurantName.trim() : 'Spice Haven Kitchen';

  bool get isAssigned => status == 'ASSIGNED';
  bool get isAccepted => status == 'ACCEPTED';
  bool get isPickedUp => status == 'PICKED_UP';
  bool get isDelivered => status == 'DELIVERED';
  bool get isRejected => status == 'REJECTED';
  bool get isActive => isAssigned || isAccepted || isPickedUp;

  double get totalEarning => deliveryFee + tipAmount;

  factory DeliveryAssignment.fromJson(Map<String, dynamic> json) {
    final rawOrderId = json['orderId']?.toString() ?? '';
    final rawOrderNum = json['orderNumber']?.toString() ??
        (rawOrderId.length > 6 ? 'ORD-${rawOrderId.substring(0, 6).toUpperCase()}' : 'ORD-$rawOrderId');

    return DeliveryAssignment(
      assignmentId: json['assignmentId']?.toString() ?? '',
      orderId: rawOrderId,
      orderNumber: rawOrderNum,
      partnerId: json['partnerId']?.toString() ?? '',
      partnerName: json['partnerName']?.toString(),
      partnerPhone: json['partnerPhone']?.toString(),
      status: json['status']?.toString() ?? 'ASSIGNED',
      assignedAt: json['assignedAt']?.toString(),
      acceptedAt: json['acceptedAt']?.toString(),
      pickedUpAt: json['pickedUpAt']?.toString(),
      deliveredAt: json['deliveredAt']?.toString(),
      deliveryAddress: json['deliveryAddress']?.toString() ?? 'Customer Address',
      customerPhone: json['customerPhone']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? json['customer']?.toString() ?? 'Customer',
      restaurantName: json['restaurantName']?.toString() ?? 'Spice Haven Central Kitchen',
      otpCode: json['otpCode']?.toString(),
      deliveryNotes: json['deliveryNotes']?.toString(),
      deliveryFee: json['deliveryFee'] != null ? (json['deliveryFee'] as num).toDouble() : 40.0,
      tipAmount: json['tipAmount'] != null ? (json['tipAmount'] as num).toDouble() : 0.0,
      itemSummary: json['itemSummary']?.toString(),
      itemsCount: json['itemsCount'] != null ? (json['itemsCount'] as num).toInt() : 0,
      deliveryLat: json['deliveryLat'] != null ? (json['deliveryLat'] as num).toDouble() : null,
      deliveryLng: json['deliveryLng'] != null ? (json['deliveryLng'] as num).toDouble() : null,
      estimatedDeliveryTime: json['estimatedDeliveryTime']?.toString(),
      totalOrderAmount: json['totalOrderAmount'] != null ? (json['totalOrderAmount'] as num).toDouble() : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assignmentId': assignmentId,
      'orderId': orderId,
      'orderNumber': orderNumber,
      'partnerId': partnerId,
      'partnerName': partnerName,
      'partnerPhone': partnerPhone,
      'status': status,
      'assignedAt': assignedAt,
      'acceptedAt': acceptedAt,
      'pickedUpAt': pickedUpAt,
      'deliveredAt': deliveredAt,
      'deliveryAddress': deliveryAddress,
      'customerPhone': customerPhone,
      'customerName': customerName,
      'restaurantName': restaurantName,
      'otpCode': otpCode,
      'deliveryNotes': deliveryNotes,
      'deliveryFee': deliveryFee,
      'tipAmount': tipAmount,
      'itemSummary': itemSummary,
      'itemsCount': itemsCount,
      'deliveryLat': deliveryLat,
      'deliveryLng': deliveryLng,
      'estimatedDeliveryTime': estimatedDeliveryTime,
      'totalOrderAmount': totalOrderAmount,
    };
  }
}
