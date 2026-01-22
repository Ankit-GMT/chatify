import 'package:chatify/Screens/chat_background_preview.dart';
import 'package:chatify/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chat_background_controller.dart';

class ChatWallpaperPicker extends StatelessWidget {
  final int chatId;

  const ChatWallpaperPicker({super.key, required this.chatId});

  @override
  Widget build(BuildContext context) {
    final ChatBackgroundController controller =
        Get.find<ChatBackgroundController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat Background"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (controller.viewMode.value == BackgroundViewMode.category) {
              controller.viewMode.value = BackgroundViewMode.home;
            } else {
              Get.back();
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Categories
          Obx(() {
            // HOME MODE (Default + Gallery + Categories)
            if (controller.viewMode.value == BackgroundViewMode.home) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _optionTile(
                      child: Image.asset(
                        "assets/images/chat_bg_default.png",
                        fit: BoxFit.cover,
                      ),
                      label: "Default",
                      onTap: () => Get.to(
                        () => const ChatBackgroundPreview(
                          imageUrl: "assets/images/chat_bg_default.png",
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _optionTile(
                      child: const Icon(Icons.add_photo_alternate, size: 40),
                      label: "Gallery",
                      onTap: controller.pickFromGallery,
                    ),
                    const SizedBox(height: 12),
                    _optionTile(
                      child: const Icon(Icons.grid_view, size: 40),
                      label: "Categories",
                      onTap: () {
                        // Just switch view, don’t load yet
                        controller.viewMode.value = BackgroundViewMode.category;
                        controller.selectedCategory.value =
                            controller.categories.first;
                        controller
                            .fetchByCategory(controller.selectedCategory.value);
                      },
                    ),
                  ],
                ),
              );
            }

            // 🔹 CATEGORY MODE (ChoiceChips)
            return SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: controller.categories.length,
                itemBuilder: (_, i) {
                  final cat = controller.categories[i];
                  // final selected =
                  //     controller.selectedCategory.value == cat;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Obx(
                      () => ChoiceChip(
                        showCheckmark: false,
                        label: Text(
                          cat,
                          style: TextStyle(
                            color: controller.selectedCategory.value == cat
                                ? AppColors.white
                                : AppColors.black,
                          ),
                        ),
                        selectedColor: AppColors.primary,
                        selected: controller.selectedCategory.value == cat,
                        onSelected: (_) {
                          controller.fetchByCategory(cat);
                        },
                      ),
                    ),
                  );
                },
              ),
            );
          }),

          // Wallpapers Grid
          Expanded(
            child: Obx(() {
              if (controller.viewMode.value != BackgroundViewMode.category) {
                return const SizedBox(); // No grid in HOME
              }

              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              return GridView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: controller.backgrounds.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemBuilder: (_, i) {
                  final bg = controller.backgrounds[i];

                  return _tile(
                    Image.network(bg.thumbnailUrl, fit: BoxFit.cover),
                    () => Get.to(
                      () => ChatBackgroundPreview(background: bg),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _tile(Widget child, VoidCallback onTap, {String? label}) {
    return InkWell(
      onTap: onTap,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox.expand(child: child),
          ),
          if (label != null)
            Positioned(
              bottom: 6,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _optionTile({
    required Widget child,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 90,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.grey.withAlpha(50),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.grey.withAlpha(50),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            SizedBox(
              width: 56,
              height: 56,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: child,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}
