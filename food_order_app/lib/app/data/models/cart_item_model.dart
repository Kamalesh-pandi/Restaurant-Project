import 'menu_item_model.dart';
import 'modifier_model.dart';

class CartItemModel {
  final String cartItemId;
  final MenuItemModel item;
  int quantity;
  final List<ModifierOption> selectedModifiers;
  final String? specialInstructions;

  CartItemModel({
    required this.cartItemId,
    required this.item,
    this.quantity = 1,
    this.selectedModifiers = const [],
    this.specialInstructions,
  });

  double get unitPrice {
    double modifierTotal = selectedModifiers.fold(0.0, (sum, mod) => sum + mod.extraPrice);
    return item.price + modifierTotal;
  }

  double get totalPrice {
    return unitPrice * quantity;
  }

  Map<String, dynamic> toJson() {
    return {
      'cartItemId': cartItemId,
      'menuItemId': item.id,
      'itemName': item.name,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'selectedModifiers': selectedModifiers.map((m) => m.toJson()).toList(),
      'specialInstructions': specialInstructions,
    };
  }

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    List<ModifierOption> mods = [];
    if (json['selectedModifiers'] is List) {
      mods = (json['selectedModifiers'] as List)
          .map((m) => ModifierOption.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
    return CartItemModel(
      cartItemId: json['cartItemId']?.toString() ?? '',
      item: MenuItemModel.fromJson(
          json['item'] is Map ? Map<String, dynamic>.from(json['item']) : json),
      quantity: json['quantity'] ?? 1,
      selectedModifiers: mods,
      specialInstructions: json['specialInstructions']?.toString(),
    );
  }
}
