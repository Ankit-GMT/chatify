import 'package:chatify/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppThemes {
  static final ThemeData lightTheme = ThemeData(
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    brightness: Brightness.light,
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
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    textTheme: GoogleFonts.poppinsTextTheme(
      TextTheme(
        bodySmall: TextStyle(color: AppColors.white),
      ),
    ),
    scaffoldBackgroundColor: AppColors.black,
    brightness: Brightness.dark,
    // dividerColor: Colors.grey.shade900
    // inputDecorationTheme: DecorationTheme.darkInputDecorationTheme,
  );
}
