import 'package:chatify/Screens/group_profile_screen.dart';
import 'package:chatify/Screens/profile_screen.dart';
import 'package:chatify/Screens/splash_screen.dart';
import 'package:chatify/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: GetMaterialApp(
        title: 'Chatify',
        debugShowCheckedModeBanner: false,
        theme: AppThemes.lightTheme,
        darkTheme: AppThemes.darkTheme,
        themeMode: ThemeMode.dark,
        home: SplashScreen(),
      ),
    );
  }
}

