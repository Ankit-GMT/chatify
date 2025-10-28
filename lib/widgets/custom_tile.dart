import 'package:chatify/constants/app_colors.dart';
import 'package:flutter/material.dart';

class CustomTile extends StatelessWidget {
  final String title;
  final String image;
  final Function()? onTap;
  final Widget? icon;
  final bool isTheme;

  const CustomTile(
      {super.key,
      required this.title,
      required this.image,
      required this.onTap,
      this.icon,
      this.isTheme = false});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      minTileHeight: 60,
      tileColor: AppColors.settingTile.withAlpha(45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      leading: SizedBox(
        height: 25,
        width: 25,
        child: Image.asset(
          image,
          scale: 2,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      ),
      trailing: isTheme
          ? icon
          : Icon(Icons.arrow_forward_ios_rounded,
              color: AppColors.primary, size: 15),
    );
  }
}
