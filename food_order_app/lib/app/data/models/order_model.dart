import 'cart_item_model.dart';
import 'menu_item_model.dart';

enum OrderType { delivery, takeaway, dineIn }

extension OrderTypeX on OrderType {
  String get nameStr {
    switch (this) {
      case OrderType.dineIn:
        return 'DINE_IN';
      case OrderType.takeaway:
        return 'TAKEAWAY';
      case OrderType.delivery:
      default:
        return 'DELIVERY';
    }
  }

  String get label {
    switch (this) {
      case OrderType.dineIn:
        return 'Dine-In';
      case OrderType.takeaway:
        return 'Takeaway';
      case OrderType.delivery:
      default:
        return 'Delivery';
    }
  }
}

class OrderModel {
  final String? id;
  final String customerId;
  final OrderType orderType;
  final String? tableNumber;
  final String? deliveryAddress;
  final List<CartItemModel> items;
  final double subtotal;
  final double gstAmount;
  final double deliveryFee;
  final double discount;
  final double grandTotal;
  final String paymentStatus; // PENDING, PAID, FAILED
  final String orderStatus; // PLACED, PREPARING, OUT_FOR_DELIVERY, DELIVERED
  final String? razorpayPaymentId;
  final DateTime createdAt;
  final DateTime? estimatedDeliveryTime;

  OrderModel({
    this.id,
    required this.customerId,
    required this.orderType,
    this.tableNumber,
    this.deliveryAddress,
    required this.items,
    required this.subtotal,
    required this.gstAmount,
    required this.deliveryFee,
    required this.discount,
    required this.grandTotal,
    this.paymentStatus = 'PENDING',
    this.orderStatus = 'PLACED',
    this.razorpayPaymentId,
    DateTime? createdAt,
    this.estimatedDeliveryTime,
  }) : createdAt = createdAt ?? DateTime.now();

  DateTime get effectiveEstimatedDeliveryTime {
    if (estimatedDeliveryTime != null) {
      return estimatedDeliveryTime!;
    }
    return createdAt.add(const Duration(minutes: 35));
  }

  String get orderTypeDisplay {
    switch (orderType) {
      case OrderType.dineIn:
        return 'DINE_IN';
      case OrderType.takeaway:
        return 'TAKEAWAY';
      case OrderType.delivery:
      default:
        return 'DELIVERY';
    }
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    OrderType parsedType = OrderType.delivery;
    String typeStr =
        (json['orderType'] ?? json['type'])?.toString().toUpperCase() ?? '';
    if (typeStr == 'DINE_IN' || typeStr == 'DINEIN') {
      parsedType = OrderType.dineIn;
    } else if (typeStr == 'TAKEAWAY') {
      parsedType = OrderType.takeaway;
    }

    double parsedGrandTotal =
        (json['grandTotal'] ?? json['totalAmount'] ?? json['total'] ?? 0)
            .toDouble();
    double parsedSubtotal =
        (json['subtotal'] ?? (parsedGrandTotal > 0 ? parsedGrandTotal : 0))
            .toDouble();

    List<CartItemModel> parsedItems = [];
    if (json['items'] is List) {
      for (var i in json['items']) {
        if (i is Map<String, dynamic>) {
          parsedItems.add(CartItemModel(
            cartItemId: i['cartItemId']?.toString() ??
                'item_${DateTime.now().microsecondsSinceEpoch}_${i['menuItemId']}',
            item: MenuItemModel(
              id: i['menuItemId']?.toString() ?? '',
              categoryId: i['categoryId']?.toString() ?? 'cat_general',
              name: i['menuItemName']?.toString() ??
                  i['name']?.toString() ??
                  'Gourmet Dish',
              price: (i['price'] ?? 0).toDouble(),
              description: '',
              imageUrl: '',
            ),
            quantity: (i['quantity'] ?? 1) is int
                ? i['quantity']
                : int.tryParse(i['quantity'].toString()) ?? 1,
          ));
        }
      }
    }

    // Safety net: if grandTotal is 0 but items exist with prices
    if (parsedGrandTotal == 0 && parsedItems.isNotEmpty) {
      parsedGrandTotal = parsedItems.fold(
          0.0, (sum, it) => sum + (it.item.price * it.quantity));
      if (parsedSubtotal == 0) parsedSubtotal = parsedGrandTotal;
    }

    return OrderModel(
      id: json['id']?.toString() ?? json['orderId']?.toString(),
      customerId: json['customerId']?.toString() ?? '',
      orderType: parsedType,
      tableNumber: json['tableNumber']?.toString(),
      deliveryAddress: json['deliveryAddress']?.toString(),
      items: parsedItems,
      subtotal: parsedSubtotal,
      gstAmount: (json['gstAmount'] ?? json['tax'] ?? 0).toDouble(),
      deliveryFee: (json['deliveryFee'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      grandTotal: parsedGrandTotal,
      paymentStatus: json['paymentStatus']?.toString() ?? 'PENDING',
      orderStatus: json['orderStatus']?.toString() ??
          json['status']?.toString() ??
          'PLACED',
      razorpayPaymentId: json['razorpayPaymentId']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : (json['seatedAt'] != null
              ? DateTime.tryParse(json['seatedAt'].toString()) ?? DateTime.now()
              : DateTime.now()),
      estimatedDeliveryTime: json['estimatedDeliveryTime'] != null
          ? DateTime.tryParse(json['estimatedDeliveryTime'].toString())
          : (json['estimatedTime'] != null
              ? DateTime.tryParse(json['estimatedTime'].toString())
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'orderType': orderType.nameStr,
      'tableNumber': tableNumber,
      'deliveryAddress': deliveryAddress,
      'items': items.map((i) => i.toJson()).toList(),
      'subtotal': subtotal,
      'gstAmount': gstAmount,
      'deliveryFee': deliveryFee,
      'discount': discount,
      'grandTotal': grandTotal,
      'paymentStatus': paymentStatus,
      'orderStatus': orderStatus,
      'razorpayPaymentId': razorpayPaymentId,
      'estimatedDeliveryTime': estimatedDeliveryTime?.toIso8601String(),
    };
  }

  Map<String, dynamic> toDirectOrderJson({
    required String name,
    required String phone,
    required String email,
    String? address,
    String? addressId,
    String? notes,
    String paymentMethod = 'RAZORPAY',
  }) {
    return {
      'outletId': '11111111-1111-1111-1111-111111111111',
      'customerName': name.isNotEmpty ? name : 'Customer',
      'customerPhone': phone,
      'customerEmail': email,
      'orderType': orderType == OrderType.dineIn
          ? 'DINE_IN'
          : (orderType == OrderType.takeaway ? 'TAKEAWAY' : 'DELIVERY'),
      'deliveryAddress': address ?? deliveryAddress ?? '',
      if (addressId != null && addressId.isNotEmpty) 'addressId': addressId,
      'deliveryNotes': notes ?? '',
      'paymentMethod': paymentMethod,
      'items': items.map((cartItem) {
        return {
          'menuItemId': cartItem.item.id,
          'quantity': cartItem.quantity,
          'modifiers': cartItem.selectedModifiers.map((m) => m.name).join(', '),
        };
      }).toList(),
    };
  }
}
