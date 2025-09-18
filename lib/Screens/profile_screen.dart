import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/widgets/custom_box.dart';
import 'package:chatify/widgets/custom_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
                    "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d"),

              ),
              Column(
                children: [
                  Text("Ankit Patel",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500),),
                  Text("+91 9876543210",style: TextStyle(fontSize: 14,fontWeight: FontWeight.w500,color: AppColors.grey),),
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
              Container(
                padding: EdgeInsets.symmetric(vertical: 16,horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("About",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500),),
                    Text("Lorem ipsum dolor sit amet consectetur. Tortor ultricies venenatis adipiscing.",style: TextStyle(fontSize: 12,fontWeight: FontWeight.w400),),
                  ],
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
          ),
        ),
      ),
    );
  }
}
