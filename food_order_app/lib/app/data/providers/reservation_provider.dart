import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/reservation_model.dart';

class ReservationProvider {
  final ApiClient _apiClient;

  ReservationProvider(this._apiClient);

  Future<Map<String, dynamic>> createReservation(ReservationModel reservation) async {
    final response = await _apiClient.post(
      ApiConstants.onlineReservation,
      data: reservation.toJson(),
    );
    return response as Map<String, dynamic>;
  }

  Future<List<dynamic>> getTables(String outletId) async {
    final response = await _apiClient.get(ApiConstants.outletTables(outletId));
    return response is List ? response : (response['data'] ?? []);
  }

  Future<List<dynamic>> getReservationHistory(String phone) async {
    final response = await _apiClient.get(ApiConstants.customerReservationHistory(phone));
    return response is List ? response : (response['data'] ?? []);
  }

  Future<Map<String, dynamic>> cancelReservation(String reservationId) async {
    final response = await _apiClient.post(ApiConstants.cancelReservation(reservationId));
    return response as Map<String, dynamic>;
  }
}
