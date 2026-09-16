import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/menu_item_model.dart';
import '../../../data/models/modifier_model.dart';
import '../../cart/controllers/cart_controller.dart';

class CustomizationBottomSheet extends StatefulWidget {
  final MenuItemModel item;
  final List<ModifierGroup> modifierGroups;

  const CustomizationBottomSheet({
    super.key,
    required this.item,
    this.modifierGroups = const [],
  });

  @override
  State<CustomizationBottomSheet> createState() => _CustomizationBottomSheetState();
}

class _CustomizationBottomSheetState extends State<CustomizationBottomSheet> {
  int quantity = 1;
  final Map<String, ModifierOption> singleSelections = {};
  final Set<ModifierOption> multiSelections = {};
  final TextEditingController instructionsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    for (var group in widget.modifierGroups) {
      if (group.isRequired && !group.allowsMultiple && group.options.isNotEmpty) {
        singleSelections[group.id] = group.options.first;
      }
    }
  }

  double get calculatedPrice {
    double base = widget.item.price;
    double singleModTotal = singleSelections.values.fold(0.0, (sum, mod) => sum + mod.extraPrice);
    double multiModTotal = multiSelections.fold(0.0, (sum, mod) => sum + mod.extraPrice);
    return (base + singleModTotal + multiModTotal) * quantity;
  }

  @override
  Widget build(BuildContext context) {
    final CartController cartController = Get.find<CartController>();

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item Image Banner
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      widget.item.imageUrl,
                      height: 190,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 190,
                        color: AppColors.primaryLight,
                        child: const Icon(Icons.restaurant, size: 64, color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Item Name & Veg tag
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: widget.item.isVeg ? AppColors.vegGreen : AppColors.nonVegRed,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.circle,
                          size: 10,
                          color: widget.item.isVeg ? AppColors.vegGreen : AppColors.nonVegRed,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.item.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2A1508)),
                        ),
                      ),
                      Text(
                        AppFormatters.formatCurrency(widget.item.price),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.item.description,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 20),

                  // Modifier Groups
                  ...widget.modifierGroups.map((group) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              group.title,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2A1508)),
                            ),
                            if (group.isRequired)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'REQUIRED',
                                  style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...group.options.map((opt) {
                          if (group.allowsMultiple) {
                            bool isSelected = multiSelections.contains(opt);
                            return CheckboxListTile(
                              activeColor: AppColors.primary,
                              title: Text(opt.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              secondary: opt.extraPrice > 0
                                  ? Text(
                                      '+${AppFormatters.formatCurrency(opt.extraPrice)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                                    )
                                  : null,
                              value: isSelected,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    multiSelections.add(opt);
                                  } else {
                                    multiSelections.remove(opt);
                                  }
                                });
                              },
                            );
                          } else {
                            return RadioListTile<ModifierOption>(
                              activeColor: AppColors.primary,
                              title: Text(opt.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              secondary: opt.extraPrice > 0
                                  ? Text(
                                      '+${AppFormatters.formatCurrency(opt.extraPrice)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                                    )
                                  : null,
                              value: opt,
                              groupValue: singleSelections[group.id],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    singleSelections[group.id] = val;
                                  });
                                }
                              },
                            );
                          }
                        }),
                        const Divider(height: 24),
                      ],
                    );
                  }),

                  // Special Instructions Field
                  const Text('Special Kitchen Instructions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2A1508))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: instructionsController,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'e.g. Extra spicy, no onions, sauce on the side...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bottom Bar (Quantity Stepper + Add Button)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Quantity Counter
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (quantity > 1) {
                            setState(() => quantity--);
                          }
                        },
                        icon: const Icon(Icons.remove_rounded, color: AppColors.primary, size: 20),
                      ),
                      Text(
                        '$quantity',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2A1508)),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() => quantity++);
                        },
                        icon: const Icon(Icons.add_rounded, color: AppColors.primary, size: 20),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD4AF37), Color(0xFFA07212)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          List<ModifierOption> allSelected = [
                            ...singleSelections.values,
                            ...multiSelections,
                          ];

                          cartController.addToCart(
                            widget.item,
                            quantity: quantity,
                            selectedModifiers: allSelected,
                            specialInstructions: instructionsController.text.trim().isNotEmpty
                                ? instructionsController.text.trim()
                                : null,
                          );

                          Get.back();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          'Add to Cart (${AppFormatters.formatCurrency(calculatedPrice)})',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  }
}
