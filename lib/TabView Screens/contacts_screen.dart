import 'package:chatify/Screens/chat_screen.dart';
import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/controllers/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userController = Get.find<UserController>();

    return Obx(
      () => userController.isLoading.value
          ? const Center(child: CircularProgressIndicator())
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
                  Text("Contacts on Chatify",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                  ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: userController.registeredUsers.length,
                    itemBuilder: (context, index) {
                      final user = userController.registeredUsers[index];
                      return ListTile(
                        onTap: () async{
                          if(user.chat == null){
                           final chatType = await userController.createChat(user.userId!);
                           Get.to(()=> ChatScreen(chatUser: null, chatType: chatType));
                          }else{
                            Get.to(()=> ChatScreen(chatUser: null, chatType: user.chat));
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
                        trailing: IconButton(
                          icon: Icon(
                            Icons.message,
                            color: AppColors.primary,
                          ),
                          onPressed: () {
                            // open chat with this user
                            // Get.toNamed('/chat', arguments: {'chatWithId': user.id});
                          },
                        ),
                      );
                    },
                  ),
                  Text("Invite to Chatify",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                  ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 80),
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: userController.notRegisteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = userController.notRegisteredUsers[index];
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
                            // open chat with this user
                            // Get.to(()=> ChatScreen(chatUser: chatUser, chatType: chatType))
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
