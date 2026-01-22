import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/controllers/group_controller.dart';
import 'package:chatify/controllers/tabBar_controller.dart';
import 'package:chatify/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class CreateGroupScreen extends StatelessWidget {
  final int currentUserId;

  const CreateGroupScreen({super.key, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController();

    final groupController = Get.put(GroupController());

    final tabController = Get.find<TabBarController>();

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
              Obx(
                () => groupController.pickedImage.value != null
                    ? CircleAvatar(
                        radius: 56,
                        backgroundImage:
                            FileImage(groupController.pickedImage.value!),
                      )
                    : CircleAvatar(
                        radius: 56,
                        backgroundImage:
                            NetworkImage("https://i.sstatic.net/l60Hf.png"),
                      ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    groupController.pickImage(ImageSource.gallery);
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
          CustomTextfield(controller: nameController, hintText: "My Group",onChanged: (value) {
            groupController.groupName.value = value.trim();
          },),
          SizedBox(
            height: Get.height * 0.02,
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              groupController.selectedContacts.isEmpty
                  ? "Select Members"
                  : "${groupController.selectedContacts.length} selected",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: tabController.registeredUsers.length,
              itemBuilder: (context, index) {
                final contact = tabController.registeredUsers[index];

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
        ]),
      ),
      floatingActionButton: Obx(
        () => groupController.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : FloatingActionButton(
                backgroundColor: AppColors.primary,
                onPressed: (groupController.selectedContacts.isNotEmpty &&
                    groupController.groupName.value.isNotEmpty)
                    ? () async {
                        await groupController.createGroup(
                          name: groupController.groupName.value,
                          groupImageFile: groupController.pickedImage.value,
                          memberIds: groupController.selectedContacts.toList(),
                          // selected member IDs
                          currentUserId: currentUserId,
                        );
                        await tabController.getAllChats();

                        debugPrint("created group ${nameController.text}");
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
