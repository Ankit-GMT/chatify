import 'package:chatify/controllers/tabBar_controller.dart';
import 'package:chatify/widgets/chat_user_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UnreadChats extends StatelessWidget {
  final tabController = Get.put(TabBarController());

  UnreadChats({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
          () => tabController.isLoading3.value
          ? const Center(child: CircularProgressIndicator())
          : tabController.unreadChats.isEmpty
          ? Center(child: Text("No chats here"),)
          : tabController.filteredUnreadList.isEmpty
          ? Center(
        child: Text("No search result found"),
      )
          : ListView.separated(
        padding: const EdgeInsets.only(bottom: 80),
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final chat = tabController.filteredUnreadList[index];
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
              chatType: tabController.filteredUnreadList
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
        itemCount: tabController.filteredUnreadList.length,
      ),
    );
  }
}
