import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;

  const ProfileAvatar({super.key, required this.imageUrl, required this.radius});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl ?? '',
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) => CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey,
        child: const Icon(Icons.person, color: Colors.white),
      ),
      errorWidget: (context, url, error) =>  CircleAvatar(
        radius: radius,
        backgroundColor: Colors.red,
        child: Icon(Icons.error, color: Colors.white),
      ),
    );
  }
}
