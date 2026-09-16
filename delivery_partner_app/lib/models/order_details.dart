class OrderItemDetail {
  final String orderItemId;
  final String? menuItemId;
  final String name;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? specialInstructions;
  bool isChecked; // Checkbox state for rider verification

  OrderItemDetail({
    required this.orderItemId,
    this.menuItemId,
    required this.name,
    required this.quantity,
    this.unitPrice = 0.0,
    this.totalPrice = 0.0,
    this.specialInstructions,
    this.isChecked = false,
  });

  factory OrderItemDetail.fromJson(Map<String, dynamic> json) {
    // Some backend endpoints embed MenuItem or have itemName
    String itemName = json['name']?.toString() ??
        json['itemName']?.toString() ??
        (json['menuItem'] != null ? json['menuItem']['name']?.toString() : null) ??
        'Restaurant Item';

    return OrderItemDetail(
      orderItemId: json['orderItemId']?.toString() ?? json['id']?.toString() ?? '',
      menuItemId: json['menuItemId']?.toString(),
      name: itemName,
      quantity: json['quantity'] != null ? (json['quantity'] as num).toInt() : 1,
      unitPrice: json['unitPrice'] != null ? (json['unitPrice'] as num).toDouble() : 0.0,
      totalPrice: json['totalPrice'] != null ? (json['totalPrice'] as num).toDouble() : 0.0,
      specialInstructions: json['specialInstructions']?.toString(),
    );
  }
}

class OrderDetail {
  final String orderId;
  final String? orderNumber;
  final String? status;
  final String? orderType;
  final double totalAmount;
  final String? deliveryAddress;
  final String? customerName;
  final String? customerPhone;
  final String? deliveryNotes;
  final String? deliveryOtp;
  final String? createdAt;
  final String? outletName;
  final String? outletAddress;
  final List<OrderItemDetail> items;

  OrderDetail({
    required this.orderId,
    this.orderNumber,
    this.status,
    this.orderType,
    this.totalAmount = 0.0,
    this.deliveryAddress,
    this.customerName,
    this.customerPhone,
    this.deliveryNotes,
    this.deliveryOtp,
    this.createdAt,
    this.outletName = 'Central Kitchen & Restaurant',
    this.outletAddress = '100 Feet Road, Indiranagar, Bengaluru',
    this.items = const [],
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json, [List<OrderItemDetail>? itemsList]) {
    return OrderDetail(
      orderId: json['orderId']?.toString() ?? json['id']?.toString() ?? '',
      orderNumber: json['orderNumber']?.toString() ?? (json['orderId'] != null ? json['orderId'].toString().substring(0, 8).toUpperCase() : 'ORD-1092'),
      status: json['status']?.toString() ?? 'ASSIGNED',
      orderType: json['orderType']?.toString() ?? 'DELIVERY',
      totalAmount: json['totalAmount'] != null ? (json['totalAmount'] as num).toDouble() : 0.0,
      deliveryAddress: json['deliveryAddress']?.toString() ?? 'Customer Address',
      customerName: json['customerName']?.toString() ?? 'Customer',
      customerPhone: json['customerPhone']?.toString() ?? '',
      deliveryNotes: json['deliveryNotes']?.toString(),
      deliveryOtp: json['deliveryOtp']?.toString(),
      createdAt: json['createdAt']?.toString(),
      outletName: json['outletName']?.toString() ?? 'Central Kitchen & Restaurant',
      outletAddress: json['outletAddress']?.toString() ?? '100 Feet Road, Indiranagar, Bengaluru',
      items: itemsList ?? [],
    );
  }

  OrderDetail copyWithItems(List<OrderItemDetail> newItems) {
    return OrderDetail(
      orderId: orderId,
      orderNumber: orderNumber,
      status: status,
      orderType: orderType,
      totalAmount: totalAmount,
      deliveryAddress: deliveryAddress,
      customerName: customerName,
      customerPhone: customerPhone,
      deliveryNotes: deliveryNotes,
      deliveryOtp: deliveryOtp,
      createdAt: createdAt,
      outletName: outletName,
      outletAddress: outletAddress,
      items: newItems,
    );
  }
}
