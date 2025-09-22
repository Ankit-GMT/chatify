import 'package:chatify/constants/app_colors.dart';
import 'package:flutter/material.dart';

class CustomTextfield extends StatelessWidget {

  final TextEditingController controller;
  final String hintText;
  final Function()? onTap;

  const CustomTextfield({super.key, required this.controller, required this.hintText, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0xff959DA5).withAlpha(51),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        onTap: onTap,
        controller: controller,
        style: TextStyle(color: AppColors.black),
        decoration: InputDecoration(
          fillColor: AppColors.white,
          filled: true,
          hintText: hintText,
          hintStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.grey
          ),
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(10),
          ),

        ),
      ),
    );
  }
}
