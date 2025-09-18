import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/widgets/custom_box.dart';
import 'package:chatify/widgets/custom_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GroupProfileScreen extends StatelessWidget {
  const GroupProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            spacing: 20,
            children: [
              SizedBox(height: Get.height * 0.01),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
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
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(
                    "https://media.istockphoto.com/id/1947499352/photo/concentrated-group-of-business-people-planning-strategy-during-team-meeting-at-the-office.jpg?s=2048x2048&w=is&k=20&c=8BqwFYcZW6GRgcXl1eqb2FlEzaad-lWFCwJGnGHqHeQ="),

              ),
              Column(
                children: [
                  Text("Task Group",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500),),
                  Text("21 Members",style: TextStyle(fontSize: 14,fontWeight: FontWeight.w500,color: AppColors.grey),),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomBox(title: "Voice Call",image: "assets/images/profile_voice.png",onTap: (){},),
                  CustomBox(title: "Video Call",image: "assets/images/profile_video.png",onTap: (){},),
                  CustomBox(title: "Add ",image: "assets/images/profile_addUser.png",onTap: (){},),
                ],
              ),
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Media",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500),)),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 10,
                  padding: EdgeInsets.only(left: 10),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Members",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500),),
                  Text("View All",style: TextStyle(fontSize: 14,fontWeight: FontWeight.w500,color: AppColors.grey),),
                ],
              ),
              SizedBox(
                height: 250,
                child: ListView.separated(
                    shrinkWrap: true,
                    scrollDirection: Axis.vertical,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: CircleAvatar(
                          // radius: 25,
                          backgroundImage: NetworkImage(
                              "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d"),
                        ),
                        title: Text("Ankit Patel"),
                        subtitle: Text("Hey, Whats'up",style: TextStyle(fontSize: 12),),
                      );
                    }, separatorBuilder: (context, index) {
                  return Divider(
                    thickness: 0.5,
                    indent: 15,
                    endIndent: 15,
                  );
                }, itemCount: 4),
              ),
              CustomTile(
                title: "Notification",
                image: "assets/images/profile_notification.png",
                onTap: () {},
              ),
              CustomTile(
                title: "Exit Group",
                image: "assets/images/profile_exit.png",
                onTap: () {},
              ),
              CustomTile(
                title: "Report Group",
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
          ),
        ),
      ),
    );
  }
}
