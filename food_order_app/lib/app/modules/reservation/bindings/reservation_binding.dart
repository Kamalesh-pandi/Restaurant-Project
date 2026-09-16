import 'package:get/get.dart';
import '../../../data/providers/reservation_provider.dart';
import '../../../data/repositories/reservation_repository.dart';
import '../../../core/network/api_client.dart';
import '../controllers/reservation_controller.dart';

class ReservationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReservationProvider>(() => ReservationProvider(Get.find<ApiClient>()), fenix: true);
    Get.lazyPut<ReservationRepository>(() => ReservationRepository(Get.find<ReservationProvider>()), fenix: true);
    Get.lazyPut<ReservationController>(() => ReservationController(), fenix: true);
  }
}
