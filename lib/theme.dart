import 'package:chatify/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppThemes {
  static final ThemeData lightTheme = ThemeData(
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    brightness: Brightness.light,
    appBarTheme: AppBarTheme(
      systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark),
    ),
    textTheme: GoogleFonts.poppinsTextTheme(
      TextTheme(
        bodyMedium: TextStyle(color: AppColors.black),
      ),
    ),
    scaffoldBackgroundColor: AppColors.white,
    // dividerColor: Colors.grey.shade200,
    // inputDecorationTheme: DecorationTheme.lightInputDecorationTheme,
  );

  static final ThemeData darkTheme = ThemeData(
    splashColor: Colors.black,
    highlightColor: Colors.transparent,
    brightness: Brightness.dark,
    appBarTheme: AppBarTheme(
      systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light),
    ),
    textTheme: GoogleFonts.poppinsTextTheme(
      TextTheme(
        bodySmall: TextStyle(color: AppColors.white),
      ),
    ),
    scaffoldBackgroundColor: AppColors.black,

    // dividerColor: Colors.grey.shade900
    // inputDecorationTheme: DecorationTheme.darkInputDecorationTheme,
  );
}
