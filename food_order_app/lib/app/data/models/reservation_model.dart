import 'package:intl/intl.dart';

class ReservationModel {
  final String? id;
  final String? tableId;
  final String? tableNumber;
  final String customerName;
  final String phone;
  final String email;
  final int partySize;
  final String date;
  final String time;
  final String? specialRequest;
  final String status; // CONFIRMED, PENDING, CANCELLED, ARRIVED, NO_SHOW

  ReservationModel({
    this.id,
    this.tableId,
    this.tableNumber,
    required this.customerName,
    required this.phone,
    required this.email,
    required this.partySize,
    required this.date,
    required this.time,
    this.specialRequest,
    this.status = 'CONFIRMED',
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: json['reservationId']?.toString() ?? json['id']?.toString(),
      tableId: json['tableId']?.toString(),
      tableNumber: json['tableNumber']?.toString(),
      customerName: json['guestName']?.toString() ?? json['customerName']?.toString() ?? '',
      phone: json['guestPhone']?.toString() ?? json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? json['guestEmail']?.toString() ?? '',
      partySize: json['partySize'] ?? json['guests'] ?? 2,
      date: json['date']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      specialRequest: json['specialRequests']?.toString() ?? json['specialRequest']?.toString() ?? json['notes']?.toString(),
      status: json['status']?.toString() ?? 'CONFIRMED',
    );
  }

  Map<String, dynamic> toJson() {
    String formattedTime = '19:00:00';
    try {
      final input = time.trim();
      if (input.toUpperCase().contains('AM') || input.toUpperCase().contains('PM')) {
        final parsed = DateFormat('hh:mm a').parse(input);
        formattedTime = DateFormat('HH:mm:ss').format(parsed);
      } else if (input.contains(':')) {
        final parts = input.split(':');
        if (parts.length == 2) {
          formattedTime = '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}:00';
        } else {
          formattedTime = input;
        }
      }
    } catch (_) {
      formattedTime = '19:00:00';
    }

    return {
      if (id != null) 'reservationId': id,
      if (tableId != null && tableId!.isNotEmpty) 'tableId': tableId,
      'outletId': '11111111-1111-1111-1111-111111111111',
      'guestName': customerName,
      'guestPhone': phone,
      'partySize': partySize,
      'date': date,
      'time': formattedTime,
      'specialRequests': specialRequest ?? '',
      'isOnlineBooking': true,
      'status': status,
      'reminderSent': false,
    };
  }
}
