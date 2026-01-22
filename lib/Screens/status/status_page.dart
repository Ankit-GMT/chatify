import 'package:chatify/Screens/status/status_viewer_screen.dart';
import 'package:chatify/models/status_user.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StatusPage extends StatefulWidget {
  final List<StatusUser> users;
  final int initialUserIndex;

  const StatusPage({
    super.key,
    required this.users,
    required this.initialUserIndex,
  });

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  late PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        PageController(initialPage: widget.initialUserIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.users.length,
        itemBuilder: (_, index) {
          return StatusViewerScreen(
            user: widget.users[index],
            onComplete: () {
              if (index < widget.users.length - 1) {
                _controller.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } else {
                Get.back();
              }
            },
          );
        },
      ),
    );
  }
}
