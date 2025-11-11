import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/controllers/group_controller.dart';
import 'package:chatify/controllers/tabBar_controller.dart';
import 'package:chatify/controllers/user_controller.dart';
import 'package:chatify/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CreateGroupScreen extends StatefulWidget {
  final int currentUserId;

  const CreateGroupScreen({Key? key, required this.currentUserId})
      : super(key: key);

  @override
  _CreateGroupScreenState createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  Set<int> selectedContacts = {};

  final nameController = TextEditingController();

  final groupController = Get.put(GroupController());
  final userController = Get.find<UserController>();
  final tabController = Get.find<TabBarController>();

  void _onTap(int id) {
    setState(() {
      if (selectedContacts.contains(id)) {
        selectedContacts.remove(id);
      } else {
        selectedContacts.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Create Group",
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(spacing: 10, children: [
          SizedBox(
            height: Get.height * 0.02,
          ),
          Stack(
            children: [
              CircleAvatar(
                radius: 56,
                backgroundImage:
                    NetworkImage("https://i.sstatic.net/l60Hf.png"),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    // profileController.pickImage();
                  },
                  child: CircleAvatar(
                    radius: 13,
                    backgroundColor: AppColors.primary,
                    child: Container(
                      height: 24,
                      width: 24,
                      decoration: BoxDecoration(
                          border: Border.all(
                              width: 1,
                              color: Get.isDarkMode
                                  ? AppColors.black
                                  : AppColors.white),
                          shape: BoxShape.circle),
                      child: Icon(
                        Icons.edit_rounded,
                        size: 14,
                        color:
                            Get.isDarkMode ? AppColors.black : AppColors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: Get.height * 0.01,
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              "Group Name",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
            ),
          ),
          CustomTextfield(controller: nameController, hintText: "My Group"),
          SizedBox(height: Get.height *0.02,),
          Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              selectedContacts.isEmpty
                  ? "Select Members"
                  : "${selectedContacts.length} selected",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: tabController.registeredUsers.length,
              itemBuilder: (context, index) {
                final contact = tabController.registeredUsers[index];
                final isSelected = selectedContacts.contains(contact.userId);

                return ListTile(
                  onTap: () => _onTap(contact.userId!),
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(contact.profileImageUrl!),
                  ),
                  title: Text("${contact.firstName} ${contact.lastName}"),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: Colors.green)
                      : Icon(Icons.radio_button_unchecked, color: Colors.grey),
                  tileColor: isSelected ? Colors.green.withOpacity(0.1) : null,
                );
              },
            ),
          ),
        ]),
      ),
      floatingActionButton:
           FloatingActionButton(
              onPressed: selectedContacts.isNotEmpty && nameController.text.isNotEmpty ? () {
                groupController.createGroup(
                  name: nameController.text.trim(),
                  groupImageUrl: "https://cdn.example.com/work.png",
                  memberIds: selectedContacts.toList(), // selected member IDs
                  currentUserId: widget.currentUserId,
                ).then((value) {
                  tabController.getAllChats();

                },);
                print("created group ${nameController.text}");
                Navigator.pop(context);
              } : null,
              child: Icon(Icons.arrow_forward,color: AppColors.white,),
            ),
    );
  }
}
