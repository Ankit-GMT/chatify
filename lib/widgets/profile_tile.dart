import 'package:chatify/constants/app_colors.dart';

import 'package:flutter/material.dart';

class ProfileTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String image;
  final Function()? onTap;
  final bool edit;

  const ProfileTile(
      {super.key,
      required this.title,
      required this.image,
      required this.onTap,
      required this.subtitle,
      this.edit = true});

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
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: AppColors.grey),
      ),
      trailing: edit
          ? Icon(Icons.arrow_forward_ios_rounded,
              color: AppColors.primary, size: 15)
          : null,
    );
  }
}
