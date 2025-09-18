import 'package:chatify/Screens/chat_screen.dart';
import 'package:chatify/Screens/group_profile_screen.dart';
import 'package:chatify/Screens/settings_screen.dart';
import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/controllers/index_controller.dart';
import 'package:chatify/widgets/chat_user_card.dart';
import 'package:chatify/widgets/tab_box.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final _indexController = Get.put(IndexController());

    final List<String> tabList = ["All Chat", "Groups", "Contacts"];
    return Scaffold(
      // backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 30),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Messages",
                  style: GoogleFonts.poppins(
                      fontSize: 24, fontWeight: FontWeight.w600),
                ),
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
                    Get.to(()=> GroupProfileScreen());
                  },
                  icon: Image.asset(
                    "assets/images/notification_logo.png",
                    scale: 4,
                  ),
                ),
              ],
            ),
            SizedBox(
              height: Get.height * 0.02,
            ),
            SearchBar(
              backgroundColor: WidgetStatePropertyAll(Color(0xfff4f4f4)),
              padding: WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 10),
              ),
              textStyle: WidgetStatePropertyAll(TextStyle(color: AppColors.black),),
              leading: Icon(
                CupertinoIcons.search,
                color: Colors.grey.shade500,
              ),
              hintText: "Search",
              hintStyle: WidgetStatePropertyAll(GoogleFonts.poppins(
                  // color: Colors.grey.shade500,
                  fontSize: 16,
                  fontWeight: FontWeight.w400)),
              elevation: WidgetStatePropertyAll(0),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            SizedBox(
              height: Get.height * 0.02,
            ),
            Align(
              alignment: Alignment.center,
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.secondary,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TabBox(
                      tabName: "All Chat",
                      onTap: () {
                        setState(() {
                          _indexController.index.value=0;
                        });
                      },
                      isSelected: _indexController.index.value == 0 ? true : false,
                    ),
                    TabBox(
                      tabName: "Groups",
                      onTap: () {
                        setState(() {
                          _indexController.index.value = 1;
                        });
                      },
                      isSelected: _indexController.index.value == 1 ? true : false,
                    ),
                    TabBox(
                      tabName: "Contacts",
                      onTap: () {
                        setState(() {
                          _indexController.index.value = 2;
                        });
                      },
                      isSelected: _indexController.index.value == 2 ? true : false,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: Get.height * 0.005,
            ),
            Expanded(
              child: ListView.separated(
                itemBuilder: (context, index) {
                  return ChatUserCard(
                    index: index,
                    onTap: (){
                      Get.to(()=> ChatScreen());
                    },
                  );
                },
                separatorBuilder: (BuildContext context, int index) {
                  return Divider(
                    thickness: 1,
                    indent: 15,
                    endIndent: 15,
                  );
                },
                itemCount: 20,
              ),
            )
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        height: 60,
        width: Get.width * 0.85,
        decoration: BoxDecoration(
          color: AppColors.black,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: () {},
              icon: Image.asset("assets/images/bottom_chat.png",scale: 2,),
            ),
            VerticalDivider(
              color: AppColors.botttomGrey.withAlpha(90),
              thickness: 1,
              indent: 22,
              endIndent: 22,
            ),
            IconButton(
              onPressed: () {},
              icon: Image.asset("assets/images/bottom_call.png",scale: 2,),
            ),
            VerticalDivider(
              color: AppColors.botttomGrey.withAlpha(90),
              thickness: 1,
              indent: 22,
              endIndent: 22,
            ),
            IconButton(
              onPressed: () {},
              icon: Image.asset("assets/images/bottom_videocall.png",scale: 2,),
            ),
            VerticalDivider(
              color: AppColors.botttomGrey.withAlpha(90),
              thickness: 1,
              indent: 22,
              endIndent: 22,
            ),
            IconButton(
              onPressed: () {
                Get.to(()=> SettingsScreen());
              },
              icon: Image.asset("assets/images/bottom_profile.png",scale: 2,),
            ),
          ],
        ),
      ),
    );
  }
}
