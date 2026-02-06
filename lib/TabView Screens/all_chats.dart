import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/controllers/tabBar_controller.dart';
import 'package:chatify/widgets/chat_user_card.dart';
import 'package:chatify/widgets/empty_message_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AllChats extends StatelessWidget {
  final tabController = Get.put(TabBarController());

  AllChats({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => tabController.isLoading1.value
          ? const Center(child: CircularProgressIndicator())
          : tabController.allChats.isEmpty
              ? RefreshIndicator(
        color: AppColors.primary,
                  onRefresh: () async {
                    await tabController.getAllChats();
                  },
                  child: EmptyMessagesWidget(
                    onTap: () {
                      tabController.currentIndex.value = 3;
                    },
                  ),
                )
              : tabController.filteredChatsList.isEmpty
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
                          final chat = tabController.filteredChatsList[index];
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
                              chatType: tabController.filteredChatsList
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
                        itemCount: tabController.filteredChatsList.length,
                      ),
                    ),
    );
  }
}
