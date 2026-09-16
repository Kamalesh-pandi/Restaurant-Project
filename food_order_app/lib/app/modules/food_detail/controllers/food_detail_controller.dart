import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/snackbars.dart';
import '../../../data/models/menu_item_model.dart';
import '../../../data/models/modifier_model.dart';
import '../../../data/repositories/menu_repository.dart';
import '../../cart/controllers/cart_controller.dart';
import '../../wishlist/controllers/wishlist_controller.dart';

class FoodDetailController extends GetxController {
  final MenuRepository _menuRepository = Get.find<MenuRepository>();
  final CartController _cartController = Get.find<CartController>();
  final WishlistController _wishlistController = Get.find<WishlistController>();

  late final MenuItemModel item;

  final RxBool isLoadingModifiers = true.obs;
  final RxList<ModifierGroup> modifierGroups = <ModifierGroup>[].obs;
  final RxInt quantity = 1.obs;
  final RxMap<String, ModifierOption> singleSelections = <String, ModifierOption>{}.obs;
  final RxSet<ModifierOption> multiSelections = <ModifierOption>{}.obs;
  final RxBool isFavorite = false.obs;

  final TextEditingController instructionsController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments is MenuItemModel) {
      item = Get.arguments as MenuItemModel;
    } else {
      // Fallback dummy item if direct navigation fails
      item = MenuItemModel(
        id: '1',
        categoryId: 'mains',
        name: 'Gourmet Dish',
        description: 'Delicious chef prepared dish with premium ingredients.',
        price: 14.99,
        imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c',
      );
    }
    _loadModifiers();
    isFavorite.value = _wishlistController.isWishlisted(item.id);
  }

  Future<void> _loadModifiers() async {
    isLoadingModifiers.value = true;
    try {
      if (item.modifierGroups.isNotEmpty) {
        modifierGroups.assignAll(item.modifierGroups);
      } else {
        final groups = await _menuRepository.getModifierGroups(item.id);
        modifierGroups.assignAll(groups);
      }

      // Initialize default required selections
      for (var group in modifierGroups) {
        if (group.isRequired && !group.allowsMultiple && group.options.isNotEmpty) {
          singleSelections[group.id] = group.options.first;
        }
      }
    } catch (e) {
      debugPrint('Error loading modifiers: $e');
    } finally {
      isLoadingModifiers.value = false;
    }
  }

  double get calculatedPrice {
    double base = item.price;
    double singleModTotal = singleSelections.values.fold(0.0, (sum, mod) => sum + mod.extraPrice);
    double multiModTotal = multiSelections.fold(0.0, (sum, mod) => sum + mod.extraPrice);
    return (base + singleModTotal + multiModTotal) * quantity.value;
  }

  void selectSingleModifier(String groupId, ModifierOption option) {
    singleSelections[groupId] = option;
  }

  void toggleMultiModifier(ModifierOption option) {
    if (multiSelections.contains(option)) {
      multiSelections.remove(option);
    } else {
      multiSelections.add(option);
    }
  }

  void incrementQuantity() {
    quantity.value++;
  }

  void decrementQuantity() {
    if (quantity.value > 1) {
      quantity.value--;
    }
  }

  void toggleFavorite() {
    _wishlistController.toggleWishlist(item);
    isFavorite.value = _wishlistController.isWishlisted(item.id);
  }

  void shareItem() {
    final shareText = 'Check out ${item.name} on Spice Haven!\n'
        'Price: ₹${item.price.toStringAsFixed(2)}\n'
        '${item.description}\n\n'
        'Order now: https://spicehaven.app/item/${item.id}';

    _showShareBottomSheet(shareText);
  }

  void _showShareBottomSheet(String shareText) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Share ${item.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select an app to share dish details',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  _buildShareAppTile(
                    icon: Icons.chat_rounded,
                    label: 'WhatsApp',
                    color: const Color(0xFF25D366),
                    onTap: () {
                      final url = Uri.parse(
                          'https://wa.me/?text=${Uri.encodeComponent(shareText)}');
                      _launchExternalShareUrl(
                        url: url,
                        shareText: shareText,
                        appName: 'WhatsApp',
                      );
                    },
                  ),
                  const SizedBox(width: 20),
                  _buildShareAppTile(
                    icon: Icons.send_rounded,
                    label: 'Telegram',
                    color: const Color(0xFF0088CC),
                    onTap: () {
                      final url = Uri.parse(
                          'https://t.me/share/url?url=${Uri.encodeComponent("https://spicehaven.app/item/${item.id}")}&text=${Uri.encodeComponent(shareText)}');
                      _launchExternalShareUrl(
                        url: url,
                        shareText: shareText,
                        appName: 'Telegram',
                      );
                    },
                  ),
                  const SizedBox(width: 20),
                  _buildShareAppTile(
                    icon: Icons.email_rounded,
                    label: 'Email',
                    color: const Color(0xFFEA4335),
                    onTap: () {
                      final url = Uri.parse(
                          'mailto:?subject=${Uri.encodeComponent("Check out ${item.name} on Spice Haven!")}&body=${Uri.encodeComponent(shareText)}');
                      _launchExternalShareUrl(
                        url: url,
                        shareText: shareText,
                        appName: 'Email',
                      );
                    },
                  ),
                  const SizedBox(width: 20),
                  _buildShareAppTile(
                    icon: Icons.copy_rounded,
                    label: 'Copy Link',
                    color: const Color(0xFF475569),
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: shareText));
                      Get.back();
                      AppSnackbars.showSuccess(
                        title: 'Copied!',
                        message: 'Dish details link copied to clipboard.',
                      );
                    },
                  ),
                  const SizedBox(width: 20),
                  _buildShareAppTile(
                    icon: Icons.more_horiz_rounded,
                    label: 'More Apps',
                    color: AppColors.primary,
                    onTap: () async {
                      Get.back();
                      try {
                        await Share.share(
                          shareText,
                          subject: 'Check out ${item.name} on Spice Haven!',
                        );
                      } catch (e) {
                        debugPrint('Native share exception: $e');
                        await Clipboard.setData(ClipboardData(text: shareText));
                        AppSnackbars.showSuccess(
                          title: 'Copied to Clipboard!',
                          message: 'Details copied. Select an app to paste & share.',
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _launchExternalShareUrl({
    required Uri url,
    required String shareText,
    required String appName,
  }) async {
    Get.back();
    bool launched = false;
    try {
      if (await canLaunchUrl(url)) {
        launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        launched = await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('Error launching $appName: $e');
    }

    if (!launched) {
      await Clipboard.setData(ClipboardData(text: shareText));
      AppSnackbars.showSuccess(
        title: 'Copied to Clipboard!',
        message: 'Details for ${item.name} copied. Open $appName to paste & share!',
      );
    }
  }

  Widget _buildShareAppTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  void addToCart() {
    List<ModifierOption> allSelected = [
      ...singleSelections.values,
      ...multiSelections,
    ];

    final q = quantity.value;
    final itemName = item.name;

    _cartController.addToCart(
      item,
      quantity: q,
      selectedModifiers: allSelected,
      specialInstructions: instructionsController.text.trim().isNotEmpty
          ? instructionsController.text.trim()
          : null,
    );

    Get.back();

    Future.microtask(() {
      AppSnackbars.showSuccess(
        title: 'Added to Cart',
        message: '$itemName ($q) has been added to your cart!',
      );
    });
  }

  @override
  void onClose() {
    instructionsController.clear();
    super.onClose();
  }
}
