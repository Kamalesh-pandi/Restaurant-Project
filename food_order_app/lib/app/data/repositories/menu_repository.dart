import 'package:flutter/foundation.dart';
import '../models/category_model.dart';
import '../models/menu_item_model.dart';
import '../models/modifier_model.dart';
import '../providers/menu_provider.dart';

class MenuRepository {
  final MenuProvider _menuProvider;

  MenuRepository(this._menuProvider);

  Future<List<CategoryModel>> getCategories() async {
    try {
      final list = await _menuProvider.getCategories();
      List<CategoryModel> mapped = list.map((item) => CategoryModel.fromJson(item)).toList();
      final seen = <String>{};
      mapped = mapped.where((c) => seen.add(c.name.toLowerCase())).toList();
      if (!mapped.any((c) => c.id == 'all')) {
        mapped.insert(0, CategoryModel(id: 'all', name: 'All Dishes', description: 'Complete Gourmet Menu'));
      }
      return mapped;
    } catch (e) {
      debugPrint('Notice: Failed to fetch database categories ($e).');
      return [CategoryModel(id: 'all', name: 'All Dishes', description: 'Complete Gourmet Menu')];
    }
  }

  Future<List<MenuItemModel>> getMenuItems() async {
    try {
      final list = await _menuProvider.getMenuItems();
      final mapped = list.map((item) => MenuItemModel.fromJson(item)).toList();
      final seen = <String>{};
      return mapped.where((item) => seen.add(item.id.isNotEmpty ? item.id : item.name.toLowerCase())).toList();
    } catch (e) {
      debugPrint('Notice: Failed to fetch database menu items ($e).');
      return [];
    }
  }

  Future<List<MenuItemModel>> getSpecials() async {
    try {
      final list = await _menuProvider.getSpecials();
      final mapped = list.map((item) => MenuItemModel.fromJson(item)).toList();
      if (mapped.isNotEmpty) {
        final seen = <String>{};
        return mapped.where((item) => item.isSpecial && seen.add(item.id.isNotEmpty ? item.id : item.name.toLowerCase())).toList();
      }
    } catch (e) {
      debugPrint('Notice: Failed to fetch database specials ($e).');
    }
    final allItems = await getMenuItems();
    return allItems.where((item) => item.isSpecial).toList();
  }

  Future<List<ModifierGroup>> getModifierGroups(String itemId) async {
    try {
      final list = await _menuProvider.getModifierGroups(itemId);
      return list.map((item) => ModifierGroup.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }
}
