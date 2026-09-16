import '../models/reservation_model.dart';
import '../models/restaurant_table_model.dart';
import '../providers/reservation_provider.dart';

class ReservationRepository {
  final ReservationProvider _reservationProvider;

  ReservationRepository(this._reservationProvider);

  Future<ReservationModel> createReservation(ReservationModel reservation) async {
    final res = await _reservationProvider.createReservation(reservation);
    return ReservationModel.fromJson(res);
  }

  Future<List<RestaurantTableModel>> getTables(String outletId) async {
    final list = await _reservationProvider.getTables(outletId);
    return list.map((e) => RestaurantTableModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ReservationModel>> getReservationHistory(String phone) async {
    final list = await _reservationProvider.getReservationHistory(phone);
    return list.map((e) => ReservationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ReservationModel> cancelReservation(String reservationId) async {
    final res = await _reservationProvider.cancelReservation(reservationId);
    return ReservationModel.fromJson(res);
  }
}
