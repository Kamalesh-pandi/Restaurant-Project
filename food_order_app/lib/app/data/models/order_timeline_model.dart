class OrderTimelineStage {
  final String title;
  final String description;
  final String time;
  final bool isCompleted;
  final bool isCurrent;

  OrderTimelineStage({
    required this.title,
    required this.description,
    required this.time,
    this.isCompleted = false,
    this.isCurrent = false,
  });

  factory OrderTimelineStage.fromJson(Map<String, dynamic> json) {
    return OrderTimelineStage(
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      isCompleted: json['isCompleted'] ?? json['completed'] ?? false,
      isCurrent: json['isCurrent'] ?? json['current'] ?? false,
    );
  }
}

class OrderTimelineModel {
  final String orderId;
  final String currentStatus;
  final String orderType;
  final String estimatedDeliveryTime;
  final String? partnerName;
  final String? partnerPhone;
  final String? partnerVehicleNumber;
  final String? deliveryOtp;
  final List<OrderTimelineStage> stages;

  OrderTimelineModel({
    required this.orderId,
    required this.currentStatus,
    this.orderType = 'DELIVERY',
    required this.estimatedDeliveryTime,
    this.partnerName,
    this.partnerPhone,
    this.partnerVehicleNumber,
    this.deliveryOtp,
    required this.stages,
  });

  String get statusDisplay {
    final s = currentStatus.toUpperCase();
    if (s == 'SERVED') {
      return orderType.contains('DINE')
          ? 'SERVED AT TABLE'
          : (orderType.contains('TAKEAWAY') ? 'SERVED / READY' : 'FOOD SERVED');
    }
    if (s == 'READY') return 'FOOD READY';
    if (s == 'PREPARING' || s == 'KITCHEN') return 'COOKING IN KITCHEN';
    if (s == 'OUT_FOR_DELIVERY' || s == 'ON_DELIVERY' || s == 'EN_ROUTE') {
      return 'OUT FOR DELIVERY';
    }
    if (s == 'ASSIGNED') return 'RIDER ASSIGNED';
    if (s == 'DELIVERED') return 'DELIVERED';
    if (s == 'NEW' || s == 'PLACED') return 'ORDER PLACED';
    return s;
  }

  factory OrderTimelineModel.fromJson(Map<String, dynamic> json) {
    String id = json['orderId']?.toString() ?? json['id']?.toString() ?? '';
    String status = json['status']?.toString() ?? json['currentStatus']?.toString() ?? 'NEW';
    String eta = json['estimatedDeliveryTime']?.toString() ?? '30 Mins';
    String typeStr = (json['orderType'] ?? json['type'] ?? 'DELIVERY').toString().toUpperCase();

    final upperStatus = status.toUpperCase();
    final bool isDineIn = typeStr.contains('DINE');
    final bool isTakeaway = typeStr.contains('TAKEAWAY');

    List<OrderTimelineStage> parsedStages = [];
    if (json['stages'] is List && (json['stages'] as List).isNotEmpty) {
      parsedStages = (json['stages'] as List)
          .map((s) => OrderTimelineStage.fromJson(s))
          .toList();
    } else {
      bool isNew = upperStatus == 'NEW' || upperStatus == 'PLACED' || upperStatus == 'DRAFT';
      bool isPrep = upperStatus == 'PREPARING' || upperStatus == 'KITCHEN';
      bool isReady = upperStatus == 'READY';
      bool isServed = upperStatus == 'SERVED';
      bool isAssigned = upperStatus == 'ASSIGNED';
      bool isEnRoute = upperStatus == 'OUT_FOR_DELIVERY' ||
          upperStatus == 'ON_DELIVERY' ||
          upperStatus == 'EN_ROUTE';
      bool isDone = upperStatus == 'DELIVERED' ||
          upperStatus == 'COMPLETED' ||
          upperStatus == 'PAID' ||
          upperStatus == 'BILLED';

      if (isDineIn) {
        parsedStages = [
          OrderTimelineStage(
            title: 'Order Placed & Received',
            description: 'Your table order has been sent to the kitchen.',
            time: 'Confirmed',
            isCompleted: true,
            isCurrent: isNew,
          ),
          OrderTimelineStage(
            title: 'Cooking in Kitchen',
            description: isReady || isServed || isDone
                ? 'Chef finished cooking your delicious meal.'
                : (isPrep
                    ? 'Chef is crafting your gourmet dishes with fresh ingredients.'
                    : 'Queued for kitchen preparation.'),
            time: (isReady || isServed || isDone)
                ? 'Prepared'
                : (isPrep ? 'In Progress' : 'Pending'),
            isCompleted: isReady || isServed || isDone,
            isCurrent: isPrep,
          ),
          OrderTimelineStage(
            title: 'Food Served at Table',
            description: isServed || isDone
                ? 'Your food has been served hot at your table. Enjoy your meal!'
                : (isReady
                    ? 'Food is ready and being brought to your table now!'
                    : 'Awaiting kitchen preparation.'),
            time: isServed || isDone
                ? 'Served'
                : (isReady ? 'Serving Now' : 'Pending'),
            isCompleted: isServed || isDone,
            isCurrent: isReady || isServed,
          ),
          OrderTimelineStage(
            title: 'Dining Experience',
            description: isDone
                ? 'Bill settled. Thank you for dining with us!'
                : (isServed
                    ? 'Enjoy your gourmet dishes! Request bill whenever ready.'
                    : 'Awaiting food service.'),
            time: isDone ? 'Completed' : (isServed ? 'Dining' : 'Pending'),
            isCompleted: isDone,
            isCurrent: isDone,
          ),
        ];
      } else if (isTakeaway) {
        parsedStages = [
          OrderTimelineStage(
            title: 'Order Placed & Received',
            description: 'Your takeaway order has been sent to the kitchen.',
            time: 'Confirmed',
            isCompleted: true,
            isCurrent: isNew,
          ),
          OrderTimelineStage(
            title: 'Cooking in Kitchen',
            description: isReady || isServed || isDone
                ? 'Chef finished preparing and packing your takeaway meal.'
                : (isPrep
                    ? 'Chef is preparing your takeaway dishes fresh.'
                    : 'Queued for kitchen preparation.'),
            time: (isReady || isServed || isDone)
                ? 'Prepared'
                : (isPrep ? 'In Progress' : 'Pending'),
            isCompleted: isReady || isServed || isDone,
            isCurrent: isPrep,
          ),
          OrderTimelineStage(
            title: 'Ready for Pickup / Served',
            description: isServed || isDone
                ? 'Order served and handed over to you at the counter.'
                : (isReady
                    ? 'Your meal is freshly packed and ready at the counter!'
                    : 'Awaiting kitchen preparation.'),
            time: isServed || isDone
                ? 'Handed Over'
                : (isReady ? 'Ready for Pickup' : 'Pending'),
            isCompleted: isServed || isDone,
            isCurrent: isReady || (isServed && !isDone),
          ),
          OrderTimelineStage(
            title: 'Completed',
            description: isServed || isDone
                ? 'Takeaway collected. Enjoy your gourmet meal!'
                : 'Pending pickup collection.',
            time: isServed || isDone ? 'Completed' : 'Pending',
            isCompleted: isServed || isDone,
            isCurrent: isServed || isDone,
          ),
        ];
      } else {
        // DELIVERY
        final hasPartner = json['partnerName'] != null &&
            json['partnerName'].toString().isNotEmpty;
        final partnerInfo = hasPartner
            ? '${json['partnerName']} (${json['partnerVehicleNumber'] ?? 'Rider'})'
            : 'Delivery partner';

        parsedStages = [
          OrderTimelineStage(
            title: 'Order Placed & Received',
            description: 'Your order has been sent to Spice Haven kitchen.',
            time: 'Confirmed',
            isCompleted: true,
            isCurrent: isNew,
          ),
          OrderTimelineStage(
            title: 'Cooking in Kitchen',
            description: isReady || isServed || isAssigned || isEnRoute || isDone
                ? 'Chef completed cooking your gourmet dishes.'
                : (isPrep
                    ? 'Chef is crafting your gourmet dishes with fresh ingredients.'
                    : 'Queued for kitchen preparation.'),
            time: (isReady || isServed || isAssigned || isEnRoute || isDone)
                ? 'Completed'
                : (isPrep ? 'In Progress' : 'Pending'),
            isCompleted:
                isReady || isServed || isAssigned || isEnRoute || isDone,
            isCurrent: isPrep,
          ),
          OrderTimelineStage(
            title: isEnRoute
                ? 'Out for Delivery'
                : (isAssigned
                    ? 'Rider Assigned'
                    : (isServed
                        ? 'Food Served by Kitchen'
                        : (isReady
                            ? 'Food Ready for Pickup'
                            : 'Delivery Dispatch'))),
            description: isEnRoute
                ? 'Handed to $partnerInfo. En-route to your location.'
                : (isAssigned
                    ? '$partnerInfo assigned to pick up your order from kitchen.'
                    : (isServed
                        ? (hasPartner
                            ? 'Food served by kitchen and handed to $partnerInfo.'
                            : 'Food prepared and served by kitchen. Packed & ready for delivery partner.')
                        : (isReady
                            ? 'Food is packed and waiting for delivery partner pickup.'
                            : 'A rider will be assigned once cooking is completed.'))),
            time: isEnRoute
                ? 'En-Route'
                : (isAssigned
                    ? 'Assigned'
                    : (isServed
                        ? 'Served'
                        : (isReady ? 'Ready' : 'Pending'))),
            isCompleted: isEnRoute || isDone,
            isCurrent: !isDone && (isReady || isServed || isAssigned || isEnRoute),
          ),
          OrderTimelineStage(
            title: 'Delivered',
            description: isDone
                ? 'Order delivered to your doorstep. Enjoy your meal!'
                : (isEnRoute
                    ? 'Delivery partner is approaching your doorstep.'
                    : 'Final delivery to your doorstep.'),
            time: isDone ? 'Delivered' : 'Pending',
            isCompleted: isDone,
            isCurrent: isDone,
          ),
        ];
      }
    }

    return OrderTimelineModel(
      orderId: id,
      currentStatus: status,
      orderType: typeStr,
      estimatedDeliveryTime: eta,
      partnerName: json['partnerName']?.toString(),
      partnerPhone: json['partnerPhone']?.toString(),
      partnerVehicleNumber: json['partnerVehicleNumber']?.toString(),
      deliveryOtp: json['deliveryOtp']?.toString(),
      stages: parsedStages,
    );
  }
}
