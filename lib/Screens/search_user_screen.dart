import 'package:chatify/Screens/chat_screen.dart';
import 'package:chatify/widgets/chat_user_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/user_controller.dart';

class SearchUserScreen extends StatelessWidget {
  final userController = Get.find<UserController>();
  final TextEditingController searchCtrl = TextEditingController();

  SearchUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Search Users")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: searchCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: "Enter Phone Number",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: Text("Search"),
              onPressed: () {
                userController.searchUsers(searchCtrl.text);
              },
            ),
              SizedBox(height: 20),
            Obx(() {
              if (userController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (userController.searchResults.isEmpty) {
                return const Text("No users found");
              }
              return Expanded(
                child: ListView.builder(
                  itemCount: userController.searchResults.length,
                  itemBuilder: (_, i) {
                    final user = userController.searchResults[i];
                    return ChatUserCard(
                      chatUser: user,
                      chatType: null,
                      isSearch: true,
                      index: userController.searchResults.indexOf(user), onTap: () {
                      Get.to(()=> ChatScreen(chatUser: user, chatType: null,));
                    },);
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
