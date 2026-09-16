import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/customer_address_model.dart';
import '../../../data/services/storage_service.dart';
import '../../profile/controllers/profile_controller.dart';
import '../controllers/home_controller.dart';

class LocationSelectorSheet extends StatefulWidget {
  const LocationSelectorSheet({super.key});

  @override
  State<LocationSelectorSheet> createState() => _LocationSelectorSheetState();
}

class _LocationSelectorSheetState extends State<LocationSelectorSheet> {
  final TextEditingController _customAddressController = TextEditingController();
  bool _showCustomInput = false;

  void _selectAndClose(HomeController controller, String address) {
    controller.selectOutlet(address);
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.find<HomeController>();
    final StorageService storage = Get.find<StorageService>();

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 24,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Drag Handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

            // Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Delivery Address',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2A1508),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Choose from saved addresses or current GPS',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.close_rounded, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Detect Current Location Button
                    Obx(
                      () => Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: controller.isDetectingLocation.value
                              ? null
                              : () async {
                                  await controller.detectCurrentLocation();
                                  if (context.mounted && Navigator.of(context).canPop()) {
                                    Navigator.of(context).pop();
                                  }
                                },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withOpacity(0.08),
                                  AppColors.primary.withOpacity(0.02),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: controller.isDetectingLocation.value
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.my_location_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        controller.isDetectingLocation.value
                                            ? 'Locating nearest outlet...'
                                            : 'Use Current GPS Location',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2A1508),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        controller.isDetectingLocation.value
                                            ? 'Searching nearby Spice Haven outlets'
                                            : 'Auto-select delivery area',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Saved Customer Addresses Section
                    Obx(() {
                      final currentOutlet = controller.selectedOutlet.value;
                      final deletedIds = storage.deletedAddressIds;
                      final deletedStrings = storage.deletedAddressStrings;

                      final List<CustomerAddressModel> addresses = [];

                      if (Get.isRegistered<ProfileController>()) {
                        final profileCtrl = Get.find<ProfileController>();
                        for (var a in profileCtrl.customerAddresses) {
                          if (a.addressId != null && deletedIds.contains(a.addressId)) continue;
                          if (deletedStrings.contains(a.fullAddress.trim())) continue;
                          if (!addresses.any((e) => e.fullAddress.trim() == a.fullAddress.trim())) {
                            addresses.add(a);
                          }
                        }
                      }

                      final rawJsonList = storage.savedCustomerAddressesJson;
                      for (var e in rawJsonList) {
                        final a = CustomerAddressModel.fromJson(e);
                        if (a.addressId != null && deletedIds.contains(a.addressId)) continue;
                        if (deletedStrings.contains(a.fullAddress.trim())) continue;
                        if (!addresses.any((item) => item.fullAddress.trim() == a.fullAddress.trim())) {
                          addresses.add(a);
                        }
                      }

                      final dbUserAddress = storage.user?.address?.trim();
                      final hasDbUserAddress = dbUserAddress != null &&
                          dbUserAddress.isNotEmpty &&
                          !deletedStrings.contains(dbUserAddress);

                      if (addresses.isEmpty && !hasDbUserAddress) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'SAVED ADDRESSES',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Divider(
                                  color: Colors.grey.shade300,
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // 1. Render Structured Customer Addresses
                          if (addresses.isNotEmpty)
                            Column(
                              children: [
                                for (int i = 0; i < addresses.length; i++) ...[
                                  if (i > 0) const SizedBox(height: 10),
                                  Builder(
                                    builder: (context) {
                                      final addr = addresses[i];
                                      final isSelected =
                                          currentOutlet == addr.fullAddress.trim();

                                      IconData icon = Icons.home_rounded;
                                      if (addr.label.toLowerCase().contains('work')) {
                                        icon = Icons.work_rounded;
                                      } else if (addr.label.toLowerCase().contains('other')) {
                                        icon = Icons.location_on_rounded;
                                      }

                                      return Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () => _selectAndClose(controller, addr.fullAddress),
                                          borderRadius: BorderRadius.circular(16),
                                          child: Container(
                                            padding: const EdgeInsets.all(14),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? AppColors.primary.withOpacity(0.08)
                                                  : Colors.grey.shade50,
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: isSelected
                                                    ? AppColors.primary
                                                    : Colors.grey.shade200,
                                                width: isSelected ? 2 : 1,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: isSelected
                                                        ? AppColors.primary
                                                        : Colors.grey.shade200,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    icon,
                                                    size: 18,
                                                    color: isSelected ? Colors.white : Colors.grey.shade700,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Text(
                                                            addr.label,
                                                            style: const TextStyle(
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.bold,
                                                              color: Color(0xFF2A1508),
                                                            ),
                                                          ),
                                                          if (addr.isDefault || isSelected) ...[
                                                            const SizedBox(width: 6),
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(
                                                                  horizontal: 6, vertical: 2),
                                                              decoration: BoxDecoration(
                                                                color: AppColors.primary,
                                                                borderRadius: BorderRadius.circular(6),
                                                              ),
                                                              child: const Text(
                                                                'Active',
                                                                style: TextStyle(
                                                                  fontSize: 9,
                                                                  fontWeight: FontWeight.bold,
                                                                  color: Colors.white,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        addr.fullAddress,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey.shade600,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (isSelected)
                                                  const Icon(Icons.check_circle_rounded,
                                                      color: AppColors.primary, size: 20),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ],
                            )
                          else if (hasDbUserAddress)
                            // Fallback single DB user address card
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _selectAndClose(controller, dbUserAddress),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: currentOutlet == dbUserAddress
                                        ? AppColors.primary.withOpacity(0.08)
                                        : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: currentOutlet == dbUserAddress
                                          ? AppColors.primary
                                          : Colors.grey.shade200,
                                      width: currentOutlet == dbUserAddress ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.home_rounded,
                                          color: AppColors.primary, size: 22),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Account Address',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF2A1508),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              dbUserAddress,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (currentOutlet == dbUserAddress)
                                        const Icon(Icons.check_circle_rounded,
                                            color: AppColors.primary, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          const SizedBox(height: 20),
                        ],
                      );
                    }),

                    // Custom Delivery Address Toggle
                    if (!_showCustomInput)
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showCustomInput = true;
                            });
                          },
                          icon: const Icon(Icons.add_location_alt_rounded,
                              size: 18, color: AppColors.primary),
                          label: const Text(
                            'Enter Custom Delivery Address',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Custom Address',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2A1508),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _customAddressController,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Enter street, building, or landmark...',
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: Colors.grey.shade300),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _showCustomInput = false;
                                    });
                                  },
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    final text = _customAddressController.text.trim();
                                    if (text.isNotEmpty) {
                                      _selectAndClose(controller, text);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Deliver Here'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }
}
