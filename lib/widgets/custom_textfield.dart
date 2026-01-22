import 'package:chatify/constants/app_colors.dart';
import 'package:flutter/material.dart';

class CustomTextfield extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;

  // email & password options
  final bool isEmail;
  final bool isPassword;
  final bool isPhone;

  // icons
  final IconData? prefixIcon;
  final Widget? suffixIcon;

  const CustomTextfield({
    super.key,
    required this.controller,
    required this.hintText,
    this.onTap,
    this.onChanged,
    this.isEmail = false,
    this.isPassword = false,
    this.isPhone = false,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: const Color(0xff959DA5).withAlpha(51),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onTap: onTap,
        onChanged: onChanged,
        obscureText: isPassword,
        maxLength:isPhone ? 10 : null,
        keyboardType:
        isEmail ? TextInputType.emailAddress : TextInputType.text,
        style: TextStyle(color: AppColors.black),
        decoration: InputDecoration(
          fillColor: AppColors.white,
          filled: true,
          hintText: hintText,
          hintStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.grey,
          ),

          // prefix icon
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: AppColors.primary)
              : null,

          // suffix icon (tap support)
          suffixIcon: suffixIcon,

          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
