import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/reservation_model.dart';
import '../../../data/models/restaurant_table_model.dart';
import '../../../data/repositories/reservation_repository.dart';
import '../../../data/services/storage_service.dart';
import '../../../core/utils/snackbars.dart';
import '../../../core/utils/app_dialogs.dart';

class ReservationController extends GetxController {
  final ReservationRepository _repository = Get.find<ReservationRepository>();
  final StorageService _storage = Get.find<StorageService>();

  final String defaultOutletId = '11111111-1111-1111-1111-111111111111';

  // Navigation tab: 0 = Book Table, 1 = My Bookings
  final RxInt activeTabIndex = 0.obs;

  // Booking Form State
  final RxBool isLoading = false.obs;
  final RxInt partySize = 2.obs;
  final Rx<DateTime> selectedDate = DateTime.now().add(const Duration(days: 1)).obs;
  final RxString selectedTimeSlot = '07:30 PM'.obs;

  final List<String> availableTimeSlots = [
    '12:30 PM',
    '01:00 PM',
    '01:30 PM',
    '07:00 PM',
    '07:30 PM',
    '08:00 PM',
    '08:30 PM',
    '09:00 PM',
  ];

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final notesController = TextEditingController();

  // Table Selection State
  final RxList<RestaurantTableModel> tables = <RestaurantTableModel>[].obs;
  final RxBool isTablesLoading = false.obs;
  final Rxn<RestaurantTableModel> selectedTable = Rxn<RestaurantTableModel>();
  final RxString selectedSectionFilter = 'All'.obs;

  // Reservation History State
  final RxList<ReservationModel> reservationHistory = <ReservationModel>[].obs;
  final RxBool isHistoryLoading = false.obs;

  List<String> get availableSections {
    final sections = tables.map((t) => t.section.trim()).where((s) => s.isNotEmpty).toSet().toList();
    sections.sort();
    return ['All', ...sections];
  }

  List<RestaurantTableModel> get filteredTables {
    if (selectedSectionFilter.value == 'All') {
      return tables;
    }
    return tables
        .where((t) => t.section.trim().toLowerCase() == selectedSectionFilter.value.toLowerCase())
        .toList();
  }

  String getTableLabel(String? tableId, String? fallback) {
    if (fallback != null && fallback.trim().isNotEmpty) return 'Table ${fallback.trim()}';
    if (tableId == null || tableId.isEmpty) return 'Table Assigned Upon Arrival';
    final found = tables.firstWhereOrNull((t) => t.tableId == tableId);
    if (found != null) {
      return 'Table ${found.tableNumber} (${found.section})';
    }
    return 'Reserved Table';
  }

  @override
  void onInit() {
    super.onInit();
    final user = _storage.user;
    if (user != null) {
      nameController.text = user.name;
      phoneController.text = user.phone;
    }

    // Check if initial tab was specified via Get.arguments
    if (Get.arguments != null && Get.arguments is Map) {
      final initialTab = Get.arguments['initialTab'];
      if (initialTab is int) {
        activeTabIndex.value = initialTab;
      }
    }

    fetchTables();
    fetchReservationHistory();
  }

  Future<void> fetchTables() async {
    isTablesLoading.value = true;
    try {
      final list = await _repository.getTables(defaultOutletId);
      tables.assignAll(list);
    } catch (e) {
      debugPrint('Error fetching tables: $e');
    } finally {
      isTablesLoading.value = false;
    }
  }

  void selectTable(RestaurantTableModel table) {
    if (!table.isAvailable) {
      AppSnackbars.showInfo(
        title: 'Table Unavailable',
        message: 'Table ${table.tableNumber} is currently ${table.status.toLowerCase()}. Please select an available table.',
      );
      return;
    }

    if (selectedTable.value?.tableId == table.tableId) {
      // Toggle deselect
      selectedTable.value = null;
    } else {
      selectedTable.value = table;
    }
  }

  Future<void> fetchReservationHistory() async {
    final phone = _storage.user?.phone ?? phoneController.text.trim();
    if (phone.isEmpty) return;

    isHistoryLoading.value = true;
    try {
      final list = await _repository.getReservationHistory(phone);
      reservationHistory.assignAll(list);
    } catch (e) {
      debugPrint('Error fetching reservation history: $e');
    } finally {
      isHistoryLoading.value = false;
    }
  }

  Future<void> cancelReservation(String reservationId) async {
    final confirm = await AppDialogs.confirm(
      title: 'Cancel Reservation?',
      message:
          'Are you sure you want to cancel this table reservation? This action cannot be undone.',
      confirmText: 'Yes, Cancel',
      cancelText: 'Keep Booking',
      isDestructive: true,
      icon: Icons.event_busy_rounded,
    );

    if (confirm != true) return;

    isLoading.value = true;
    try {
      final updated = await _repository.cancelReservation(reservationId);
      // Update item in local list
      final index = reservationHistory.indexWhere((r) => r.id == reservationId);
      if (index != -1) {
        reservationHistory[index] = updated;
      }
      AppSnackbars.showSuccess(title: 'Cancelled', message: 'Your reservation has been cancelled.');
      // Refresh table availability
      fetchTables();
    } catch (e) {
      AppSnackbars.showError(title: 'Cancellation Failed', message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> submitReservation() async {
    if (nameController.text.trim().isEmpty || phoneController.text.trim().isEmpty) {
      AppSnackbars.showError(title: 'Required Fields', message: 'Please enter your name and phone number.');
      return;
    }

    isLoading.value = true;
    try {
      final res = ReservationModel(
        tableId: selectedTable.value?.tableId,
        tableNumber: selectedTable.value?.tableNumber,
        customerName: nameController.text.trim(),
        phone: phoneController.text.trim(),
        email: _storage.user?.email ?? '',
        partySize: partySize.value,
        date: DateFormat('yyyy-MM-dd').format(selectedDate.value),
        time: selectedTimeSlot.value,
        specialRequest: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
      );

      final confirmed = await _repository.createReservation(res);

      // Add to history and refresh tables
      reservationHistory.insert(0, confirmed);
      fetchTables();

      // Reset form selection
      selectedTable.value = null;
      notesController.clear();

      AppDialogs.success(
        title: 'Table Reserved!',
        message:
            'Your table has been reserved for ${confirmed.partySize} guests on ${confirmed.date} at ${confirmed.time}.',
        buttonText: 'View My Bookings',
        extraContent: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.table_restaurant_rounded,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    confirmed.tableNumber != null &&
                            confirmed.tableNumber!.isNotEmpty
                        ? 'Table ${confirmed.tableNumber}'
                        : (selectedTable.value != null
                            ? 'Table ${selectedTable.value!.tableNumber}'
                            : 'Reservation Confirmed'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF2A1508),
                    ),
                  ),
                ],
              ),
              if (confirmed.id != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Reservation ID: #${confirmed.id!.substring(0, 8)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ],
          ),
        ),
        onDone: () {
          // Switch to My Bookings tab
          activeTabIndex.value = 1;
        },
      );
    } catch (e) {
      AppSnackbars.showError(title: 'Booking Failed', message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    nameController.clear();
    phoneController.clear();
    notesController.clear();
    super.onClose();
  }
}
