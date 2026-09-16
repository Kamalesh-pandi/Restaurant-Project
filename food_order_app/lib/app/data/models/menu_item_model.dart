import 'modifier_model.dart';

class MenuItemModel {
  final String id;
  final String categoryId;
  final String name;
  final String description;
  final double price;
  final double rating;
  final bool isVeg;
  final bool isSpecial;
  final String imageUrl;
  final List<ModifierGroup> modifierGroups;

  MenuItemModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    this.rating = 4.8,
    this.isVeg = true,
    this.isSpecial = false,
    required this.imageUrl,
    this.modifierGroups = const [],
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    var rawGroups = json['modifierGroups'] as List? ?? [];
    return MenuItemModel(
      id: json['itemId']?.toString() ?? json['id']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ?? json['category']?['categoryId']?.toString() ?? json['category']?['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: (json['price'] ?? 0).toDouble(),
      rating: (json['rating'] ?? 4.8).toDouble(),
      isVeg: json['isVeg'] ?? json['veg'] ?? true,
      isSpecial: json['isSpecial'] ?? json['special'] ?? false,
      imageUrl: json['imageUrl']?.toString() ?? json['image']?.toString() ?? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c',
      modifierGroups: rawGroups.map((group) => ModifierGroup.fromJson(group)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'rating': rating,
      'isVeg': isVeg,
      'isSpecial': isSpecial,
      'imageUrl': imageUrl,
      'modifierGroups': modifierGroups.map((g) => g.toJson()).toList(),
    };
  }
}
