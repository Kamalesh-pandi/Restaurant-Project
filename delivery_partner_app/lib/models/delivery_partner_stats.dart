class DeliveryPartnerStats {
  final String partnerId;
  final String name;
  final String phone;
  final double rating;
  final String status;
  final int totalDeliveries;
  final int todayDeliveriesCount;
  final double todayEarnings;
  final double todayTips;
  final int weeklyDeliveriesCount;
  final double weeklyEarnings;
  final double allTimeEarnings;
  final double completionRate;
  final int avgDeliveryMinutes;
  final double totalDistanceKm;

  DeliveryPartnerStats({
    required this.partnerId,
    required this.name,
    required this.phone,
    required this.rating,
    required this.status,
    required this.totalDeliveries,
    required this.todayDeliveriesCount,
    required this.todayEarnings,
    required this.todayTips,
    required this.weeklyDeliveriesCount,
    required this.weeklyEarnings,
    required this.allTimeEarnings,
    required this.completionRate,
    required this.avgDeliveryMinutes,
    required this.totalDistanceKm,
  });

  int get todayDeliveries => todayDeliveriesCount;
  int get weeklyDeliveries => weeklyDeliveriesCount;
  int get avgDeliveryTimeMinutes => avgDeliveryMinutes;
  double get onTimeRate => completionRate;

  factory DeliveryPartnerStats.fromJson(Map<String, dynamic> json) {
    return DeliveryPartnerStats(
      partnerId: json['partnerId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : 5.0,
      status: json['status']?.toString() ?? 'OFFLINE',
      totalDeliveries: json['totalDeliveries'] != null ? (json['totalDeliveries'] as num).toInt() : 0,
      todayDeliveriesCount: json['todayDeliveriesCount'] != null ? (json['todayDeliveriesCount'] as num).toInt() : 0,
      todayEarnings: json['todayEarnings'] != null ? (json['todayEarnings'] as num).toDouble() : 0.0,
      todayTips: json['todayTips'] != null ? (json['todayTips'] as num).toDouble() : 0.0,
      weeklyDeliveriesCount: json['weeklyDeliveriesCount'] != null ? (json['weeklyDeliveriesCount'] as num).toInt() : 0,
      weeklyEarnings: json['weeklyEarnings'] != null ? (json['weeklyEarnings'] as num).toDouble() : 0.0,
      allTimeEarnings: json['allTimeEarnings'] != null ? (json['allTimeEarnings'] as num).toDouble() : 0.0,
      completionRate: json['completionRate'] != null ? (json['completionRate'] as num).toDouble() : 100.0,
      avgDeliveryMinutes: json['avgDeliveryMinutes'] != null ? (json['avgDeliveryMinutes'] as num).toInt() : 20,
      totalDistanceKm: json['totalDistanceKm'] != null ? (json['totalDistanceKm'] as num).toDouble() : 0.0,
    );
  }

  factory DeliveryPartnerStats.empty([String? partnerId]) {
    return DeliveryPartnerStats(
      partnerId: partnerId ?? '',
      name: '',
      phone: '',
      rating: 5.0,
      status: 'OFFLINE',
      totalDeliveries: 0,
      todayDeliveriesCount: 0,
      todayEarnings: 0.0,
      todayTips: 0.0,
      weeklyDeliveriesCount: 0,
      weeklyEarnings: 0.0,
      allTimeEarnings: 0.0,
      completionRate: 100.0,
      avgDeliveryMinutes: 20,
      totalDistanceKm: 0.0,
    );
  }
}
