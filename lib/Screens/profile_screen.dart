import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/controllers/user_controller.dart';
import 'package:chatify/widgets/custom_box.dart';
import 'package:chatify/widgets/custom_tile.dart';
import 'package:chatify/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileScreen extends StatelessWidget {
  final int? id;

   const ProfileScreen({super.key, required this.id});


  @override
  Widget build(BuildContext context) {
    final userController = Get.find<UserController>();
    userController.fetchUserProfile(id!);

    return Scaffold(
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 10),
          child:
          Obx(() => Column(
            spacing: 20,
            children: [
              SizedBox(
                height: Get.height*0.03,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // GestureDetector(
                  //     onTap: () {
                  //       Get.back();
                  //     },
                  //     child: Image.asset("assets/images/back_icon.png",scale: 3,))
                  IconButton(
                    color: AppColors.iconGrey,
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(AppColors.white),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: Colors.grey.shade200)),
                      ),
                    ),
                    onPressed: () {
                      Get.back();
                    },
                    icon: Icon(Icons.arrow_left),
                  ),
                ],
              ),
              ProfileAvatar(imageUrl: '${userController.user.value.profileImageUrl}', radius: 50),
              Column(
                children: [
                  Text("${userController.user.value.firstName} ${userController.user.value.lastName}",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500),),
                  Text("+91 ${userController.user.value.phoneNumber}",style: TextStyle(fontSize: 14,fontWeight: FontWeight.w500,color: AppColors.grey),),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomBox(title: "Message",image: "assets/images/profile_message.png",onTap: (){},),
                  CustomBox(title: "Voice Call",image: "assets/images/profile_voice.png",onTap: (){},),
                  CustomBox(title: "Video Call",image: "assets/images/profile_video.png",onTap: (){},),
                ],
              ),
              Align(
                alignment: Alignment.topLeft,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 0,horizontal: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("About",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500),),
                      Text( userController.user.value.about ?? "No bio",style: TextStyle(fontSize: 12,fontWeight: FontWeight.w400),),
                    ],
                  ),
                ),
              ),
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Media",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500),)),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 10,
                  padding: EdgeInsets.only(left: 0),
                  itemBuilder: (context, index) {
                    return Container(
                      height: 70,
                      width: 70,
                      margin: EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: Image.network("https://picsum.photos/200/300",fit: BoxFit.cover,)),
                    );
                  },),
              ),
              CustomTile(
                title: "Notification",
                image: "assets/images/profile_notification.png",
                onTap: () {},
              ),
              CustomTile(
                title: "Block Number",
                image: "assets/images/profile_block.png",
                onTap: () {},
              ),
              CustomTile(
                title: "Report Number",
                image: "assets/images/profile_report.png",
                onTap: () {},
              ),
              Text(
                "Version 1.0.0",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),),
        ),
      ),
    );
  }
}
