import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/controllers/chat_screen_controller.dart';
import 'package:chatify/controllers/group_controller.dart';
import 'package:chatify/controllers/tabBar_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddGroupMembersScreen extends StatelessWidget {
  final int groupId;
  const AddGroupMembersScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    final groupController = Get.put(GroupController());

    final tabController = Get.find<TabBarController>();
    final chatController = Get.find<ChatScreenController>();

    final availableUsers = tabController.registeredUsers
        .where((user) => !groupController.currentGroupMembers.contains(user.userId))
        .toList();
    return Scaffold(
      appBar: AppBar(
        title:
          Obx(() => Text(
            groupController.selectedContacts.isEmpty
                ? "Select Members"
                : "${groupController.selectedContacts.length} selected",
            style: TextStyle(fontWeight: FontWeight.w500),
          ),),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          spacing: 10,
          children: [
            SizedBox(
              height: Get.height * 0.01,
            ),
            Expanded(
              child: ListView.builder(
                itemCount: availableUsers.length,
                itemBuilder: (context, index) {
                  final contact = availableUsers[index];

                  return Obx(
                        () {
                      final isSelected = groupController.selectedContacts
                          .contains(contact.userId);
                      return ListTile(
                        onTap: () => groupController.onTap(contact.userId!),
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(contact.profileImageUrl ?? ''),
                        ),
                        title: Text("${contact.firstName} ${contact.lastName}"),
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: Colors.green)
                            : Icon(Icons.radio_button_unchecked,
                            color: Colors.grey),
                        tileColor:
                        isSelected ? Colors.green.withOpacity(0.1) : null,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Obx(
            () => groupController.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : FloatingActionButton(
          backgroundColor: AppColors.primary,
          onPressed: groupController.selectedContacts.isNotEmpty
              ? () async {
            await groupController.addMembers(
              memberIds: groupController.selectedContacts.toList(), groupId: groupId,
            );
            chatController.fetchChatType(groupId);
          }
              : null,
          child: Icon(
            Icons.arrow_forward,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}
