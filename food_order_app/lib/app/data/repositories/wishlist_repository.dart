import '../models/menu_item_model.dart';
import '../providers/wishlist_provider.dart';

class WishlistRepository {
  final WishlistProvider _wishlistProvider;

  WishlistRepository(this._wishlistProvider);

  Future<List<MenuItemModel>> getWishlist(String phone) async {
    try {
      final res = await _wishlistProvider.getWishlist(phone);
      return res.map((json) => MenuItemModel.fromJson(json)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> toggleWishlist(String phone, String itemId) async {
    try {
      await _wishlistProvider.toggleWishlist(phone, itemId);
      return true;
    } catch (_) {
      return false;
    }
  }
}
