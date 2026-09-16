class RestaurantTableModel {
  final String tableId;
  final String? outletId;
  final String tableNumber;
  final String section;
  final int capacity;
  final String status; // 'AVAILABLE', 'RESERVED', 'OCCUPIED'
  final int? xPos;
  final int? yPos;

  RestaurantTableModel({
    required this.tableId,
    this.outletId,
    required this.tableNumber,
    required this.section,
    required this.capacity,
    required this.status,
    this.xPos,
    this.yPos,
  });

  bool get isAvailable => status.toUpperCase() == 'AVAILABLE';
  bool get isReserved => status.toUpperCase() == 'RESERVED';
  bool get isOccupied => status.toUpperCase() == 'OCCUPIED';

  factory RestaurantTableModel.fromJson(Map<String, dynamic> json) {
    return RestaurantTableModel(
      tableId: json['tableId']?.toString() ?? json['id']?.toString() ?? '',
      outletId: json['outletId']?.toString(),
      tableNumber: json['tableNumber']?.toString() ?? 'T',
      section: json['section']?.toString() ?? 'General',
      capacity: (json['capacity'] as num?)?.toInt() ?? 2,
      status: json['status']?.toString() ?? 'AVAILABLE',
      xPos: (json['xPos'] as num?)?.toInt(),
      yPos: (json['yPos'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tableId': tableId,
      if (outletId != null) 'outletId': outletId,
      'tableNumber': tableNumber,
      'section': section,
      'capacity': capacity,
      'status': status,
      if (xPos != null) 'xPos': xPos,
      if (yPos != null) 'yPos': yPos,
    };
  }
}
