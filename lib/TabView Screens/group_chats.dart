import 'package:chatify/Screens/create_group_screen.dart';
import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/controllers/tabBar_controller.dart';
import 'package:chatify/widgets/chat_user_card.dart';
import 'package:chatify/widgets/empty_message_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class GroupChats extends StatelessWidget {
  final tabController = Get.put(TabBarController());

  final box = GetStorage();

  GroupChats({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => tabController.isLoading1.value
          ? const Center(child: CircularProgressIndicator())
          : tabController.groupChats.isEmpty
              ? RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    await tabController.getAllChats();
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: Get.height *0.6,
                        child: EmptyMessagesWidget(
                        isGroup: true,
                        onTap: () {
                          Get.to(() =>
                              CreateGroupScreen(currentUserId: box.read("userId")));
                        },
                                            ),
                      ),
                    ],
                  ),
                )
              : tabController.filteredGroupsList.isEmpty
                  ? Center(
                      child: Text("No search result found"),
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async {
                        await tabController.getAllChats();
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.only(bottom: 80),
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        itemBuilder: (context, index) {
                          final chat = tabController.filteredGroupsList[index];
                          final isSelected =
                              tabController.selectedChats.contains(chat);
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onLongPress: () =>
                                tabController.toggleSelection(chat),
                            child: ChatUserCard(
                              index: index,
                              onTap: () {
                                if (tabController.isSelectionMode.value) {
                                  tabController.toggleSelection(chat);
                                } else {
                                  tabController.handleChatOpen(chat);
                                }
                              },
                              chatUser: null,
                              chatType: tabController.filteredGroupsList
                                  .elementAt(index),
                              isSelected: isSelected,
                            ),
                          );
                        },
                        separatorBuilder: (BuildContext context, int index) {
                          return Divider(
                            thickness: 1,
                            indent: 15,
                            endIndent: 15,
                          );
                        },
                        itemCount: tabController.filteredGroupsList.length,
                      ),
                    ),
    );
  }
}
