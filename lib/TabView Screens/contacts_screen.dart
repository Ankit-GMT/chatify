import 'package:chatify/Screens/chat_screen.dart';
import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/controllers/tabBar_controller.dart';
import 'package:chatify/controllers/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tabController = Get.put(TabBarController());
    final userController = Get.put(UserController());

    return Obx(
      () => tabController.isLoading2.value
          ? const Center(child: CircularProgressIndicator())
          : (tabController.filteredRegisteredList.isEmpty &&
                  tabController.filteredNotRegisteredList.isEmpty)
              ? Center(
                  child: Text("No search result found"),
                )
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 5,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 5,
                      ),
                      Text(
                        "Contacts on Chatify",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: tabController.filteredRegisteredList.length,
                        itemBuilder: (context, index) {
                          final user =
                              tabController.filteredRegisteredList[index];
                          return ListTile(
                            onTap: () async {
                              if (user.chat == null) {
                                final chatType = await userController
                                    .createChat(user.userId!);
                                Get.to(() => ChatScreen(chatId: chatType.id));
                              } else {
                                // Get.to(() => ChatScreen(
                                //     chatId: user.chat?.id));
                                tabController.handleChatOpen(user.chat!);
                              }
                            },
                            leading: CircleAvatar(
                              backgroundImage: user.profileImageUrl != null
                                  ? NetworkImage(user.profileImageUrl!)
                                  : null,
                              child: user.profileImageUrl == null
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(
                                "${user.firstName ?? ''} ${user.lastName ?? ''}"),
                            subtitle: Text("${user.phoneNumber}"),
                            trailing:
                                // IconButton(
                                //   icon:
                                Icon(
                              Icons.message,
                              color: AppColors.primary,
                            ),
                          );
                        },
                      ),
                      Text(
                        "Invite to Chatify",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.only(bottom: 80),
                        physics: NeverScrollableScrollPhysics(),
                        itemCount:
                            tabController.filteredNotRegisteredList.length,
                        itemBuilder: (context, index) {
                          final user =
                              tabController.filteredNotRegisteredList[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: user.profileImageUrl != null
                                  ? NetworkImage(user.profileImageUrl!)
                                  : null,
                              child: user.profileImageUrl == null
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(
                                "${user.firstName ?? ''} ${user.lastName ?? ''}"),
                            subtitle: Text("${user.phoneNumber}"),
                            trailing: IconButton(
                              icon: Text("Invite"),
                              onPressed: () {
                                // send invite
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
    );
  }
}
