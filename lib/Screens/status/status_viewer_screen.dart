import 'dart:convert';

import 'package:chatify/constants/apis.dart';
import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/constants/custom_snackbar.dart';
import 'package:chatify/controllers/status_controller.dart';
import 'package:chatify/models/status_user.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

class StatusViewerScreen extends StatefulWidget {
  final StatusUser user;
  final VoidCallback onComplete;

  const StatusViewerScreen({
    super.key,
    required this.user,
    required this.onComplete,
  });

  @override
  State<StatusViewerScreen> createState() => _StatusViewerScreenState();
}

class _StatusViewerScreenState extends State<StatusViewerScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {

  AnimationController? _progress;
  VideoPlayerController? _video;

  final TextEditingController _replyController = TextEditingController();
  bool _sendingReply = false;

  final controller = Get.find<StatusController>();

  final FocusNode _replyFocusNode = FocusNode();
  bool _keyboardVisible = false;

  int index = 0;
  bool _isBuffering = false;

  final box = GetStorage();

  String? get token => box.read("accessToken");

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _replyFocusNode.addListener(() {
      if (_replyFocusNode.hasFocus) {
        pause();
      }
    });
    _loadStatus();
    print("-=-=-INIT $_sendingReply");
  }

  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    final isKeyboardNowVisible = bottomInset > 0;

    if (isKeyboardNowVisible != _keyboardVisible) {
      _keyboardVisible = isKeyboardNowVisible;

      if (_keyboardVisible) {
        pause();
      } else {
        resume();
      }
    }
  }

  void _disposeMedia() {
    _progress?.removeStatusListener(_onProgressStatus);
    _progress?.dispose();
    _progress = null;

    _video?.dispose();
    _video = null;
  }

  void _onProgressStatus(AnimationStatus status) {
    if (!mounted) return;

    if (status == AnimationStatus.completed) {
      _next();
    }
  }



  void _loadStatus() async {
    _disposeMedia();

    if (mounted) {
      setState(() {
        _isBuffering = true;
      });
    }

    final item = widget.user.statuses[index];

    if (!item.viewed) {
      markStatusAsViewed(item.id);
    }

    if (item.type == "VIDEO") {
      _video = VideoPlayerController.networkUrl(
        Uri.parse(
          'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
        ),
      );

      await _video!.initialize();
      if (!mounted) return;

      final duration = _video!.value.duration;

      _progress = AnimationController(
        vsync: this,
        duration: duration.inMilliseconds > 0
            ? duration
            : const Duration(seconds: 1),
      );

      _progress!.addStatusListener(_onProgressStatus);

      _video!.addListener(() {
        if (!mounted || _video == null || _progress == null) return;

        final value = _video!.value;

        // TRUE buffering detection
        if (value.isBuffering) {
          if (!_isBuffering) {
            _isBuffering = true;
            _progress!.stop();
            if (mounted) setState(() {});
          }
          return;
        }

        //  Start progress ONLY once
        if (_isBuffering && value.isPlaying) {
          _isBuffering = false;
          if (!_progress!.isAnimating) {
            _progress!.forward();
          }
          if (mounted) setState(() {});
        }
      });

      _video!.play();
    } else {
      _progress = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 5),
      );

      _progress!.addStatusListener(_onProgressStatus);

      _isBuffering = false;
      _progress!.forward();
    }

    if (mounted) setState(() {});
  }


  void pause() {
    _progress?.stop();
    _video?.pause();
  }

  void resume() {
    if (!_isBuffering) {
      _progress?.forward();
    }
    _video?.play();
  }

  void _next() {
    if (!mounted) return;

    if (index < widget.user.statuses.length - 1) {
      index++;
      _loadStatus();
    } else {
      widget.onComplete();
    }
  }

  void _prev() {
    if (index > 0) {
      index--;
      _loadStatus();
    }
  }

  Future<void> deleteCurrentStatus() async {

    final statusId = widget.user.statuses[index].id;

    final success = await controller.deleteStatus(statusId);

    if (!mounted) return;

    if (success) {
      if (widget.user.statuses.isEmpty) {
        Get.back();
      } else if (index >= widget.user.statuses.length) {
        index = widget.user.statuses.length - 1;
        _loadStatus();
      } else {
        _loadStatus();
      }
    } else {
    }
   await controller.loadStatuses();
  }


  @override
  void dispose() {
    _replyController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _replyFocusNode.dispose();
    _progress?.dispose();
    _video?.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    print("-=-=-REply clicked $_sendingReply");
    final text = _replyController.text.trim();
    if (text.isEmpty || _sendingReply) return;

    pause();

    setState(() => _sendingReply = true);

    final statusId = widget.user.statuses[index].id;

    final success = await controller.replyToStatus(
      statusId: statusId,
      content: text,
    );

    if (!mounted) return;

    setState(() => _sendingReply = false);

    if (success) {
      _replyController.clear();
      FocusScope.of(context).unfocus();
      resume();

      CustomSnackbar.success(
        "Sent",
        "Reply sent successfully",
      );
    } else {
      resume();
      CustomSnackbar.error(
        "Error",
        "Failed to send reply",
      );
    }
  }


  Color hexToColor(String hex) {
    hex = hex.replaceAll("#", "");

    if (hex.length == 6) {
      hex = "FF$hex"; // add alpha if missing
    }

    return Color(int.parse(hex, radix: 16));
  }

  Future<void> markStatusAsViewed(int statusId) async {
    await http.post(
      Uri.parse('${APIs.url}/api/statuses/$statusId/view'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );
  }

  Future<List<StatusViewer>> fetchViewers(int statusId) async {
    final res = await http.get(
      Uri.parse('${APIs.url}/api/statuses/$statusId/viewers'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (res.statusCode != 200) return [];

    final List data = jsonDecode(res.body);
    return data.map((e) => StatusViewer.fromJson(e)).toList();
  }

  bool get _isReady {
    final status = widget.user.statuses[index];

    if (status.type == "VIDEO") {
      return _video != null &&
          _video!.value.isInitialized &&
          _progress != null;
    }

    return _progress != null;
  }

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      left: false,
      right: false,
      child: GestureDetector(
        onLongPressStart: (_) => pause(),
        onLongPressEnd: (_) => resume(),
        onVerticalDragUpdate: (d) {
          if (d.primaryDelta! > 12) Get.back();
        },
        onTapUp: (d) {
          final w = MediaQuery.of(context).size.width;
          d.globalPosition.dx < w / 2 ? _prev() : _next();
        },
        child:
        !_isReady
            ? const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ) :
        Stack(
          children: [
            /// Media
            widget.user.statuses[index].type == "VIDEO"
                ? Center(
                    child: (_video?.value.isInitialized ?? false)
                        ? VideoPlayer(_video!)
                        : const SizedBox.shrink(),
                  )
                : widget.user.statuses[index].type == "TEXT"
                    ? Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: hexToColor(
                            '${widget.user.statuses[index].backgroundColor}' ??
                                '#000000'),
                        child: Center(
                            child: Text(widget.user.statuses[index].caption)),
                      )
                    : Image.network(
                        // widget.user.statuses[index].mediaUrl ?? '',
                        "https://picsum.photos/id/1016/600/900",
                        fit: BoxFit.cover,
                        height: double.infinity,
                        width: double.infinity,
                      ),

            if (_isBuffering)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.25),
                  child: const Center(
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

            if (widget.user.statuses[index].caption.trim().isNotEmpty)
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: Colors.black45,
                  child: Text(
                    widget.user.statuses[index].caption,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),

            /// Progress bars
            if (_progress != null)
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: AnimatedBuilder(
                  animation: _progress!,
                  builder: (_, __) {
                    return Row(
                      children: List.generate(
                        widget.user.statuses.length,
                        (i) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: LinearProgressIndicator(
                              value: i < index
                                  ? 1
                                  : i == index
                                      ? (_progress?.value ?? 0)
                                      : 0,
                              backgroundColor: Colors.white30,
                              valueColor:
                                  const AlwaysStoppedAnimation(Colors.white),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            /// User info
            Positioned(
              top: 30,
              left: 10,
              right: 10,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(
                        // widget.user.profilePic
                        "https://picsum.photos/id/1016/600/900"),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    spacing: 4,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.user.firstName} ${widget.user.lastName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatViewedTime(
                            widget.user.statuses[index].createdAt, context),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      // pause();
                      // _progress?.dispose();
                      // _video?.dispose();
                      Get.back();
                    },
                  ),
                  widget.user.statuses[index].isMine ?
                  PopupMenuButton(
                    padding: EdgeInsets.zero,
                    color: AppColors.white,
                    iconColor: AppColors.white,
                    // iconSize: 26,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    onOpened: () {
                      pause();
                    },
                    onCanceled: () {
                      resume();
                    },
                    onSelected: (value) {
                      if (value == 'delete') {
                        Future.microtask(() async {
                          await deleteCurrentStatus();
                        });
                      }
                    },

                    itemBuilder: (context) {
                      return [
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            spacing: 6,
                            children: [
                              Icon(
                                Icons.delete_outline,
                                color: AppColors.primary,
                              ),
                              Text(
                                "Delete",
                                style: TextStyle(color: AppColors.black),
                              ),
                            ],
                          ),
                        ),
                      ];
                    },
                  ) : SizedBox.shrink(),
                ],
              ),
            ),

            /// Reply bar
            widget.user.statuses[index].isMine
                ? Positioned(
                    bottom: 20,
                    left: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () {
                        showViewersSheet(widget.user.statuses[index].id);
                      },
                      child: SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: Row(
                          spacing: 5,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.remove_red_eye_outlined,
                              color: Colors.white,
                            ),
                            Text(
                              widget.user.statuses[index].viewCount.toString(),
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : Positioned(
                    bottom: 20,
                    left: 10,
                    right: 10,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _replyController,
                            focusNode: _replyFocusNode,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: "Reply...",
                              hintStyle: const TextStyle(color: Colors.white70),
                              filled: true,
                              fillColor: Colors.black54,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _sendingReply ? null : _sendReply,
                          child: _sendingReply
                              ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Icon(Icons.send, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  void showViewersSheet(int statusId) async {
    pause();

    final viewers = await fetchViewers(statusId);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),

              /// Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.remove_red_eye, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      viewers.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(color: Colors.white24),

              /// Viewer list
              if (viewers.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    "No views yet",
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: viewers.length,
                  itemBuilder: (_, i) {
                    final v = viewers[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(
                          // v.profileImage,
                          "https://picsum.photos/id/1016/600/900",
                        ),
                      ),
                      title: Text(
                        v.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        _formatViewedTime(v.viewedAt, context),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    ).whenComplete(resume);
  }

  String _formatViewedTime(DateTime time, BuildContext context) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(time.year, time.month, time.day);

    final dayDiff = today.difference(date).inDays;

    if (dayDiff == 0) {
      return TimeOfDay.fromDateTime(time).format(Get.context!);
    }

    if (dayDiff == 1) {
      return "Yesterday, ${TimeOfDay.fromDateTime(time).format(Get.context!)}";
    }

    return "${time.day.toString().padLeft(2, '0')}/"
        "${time.month.toString().padLeft(2, '0')}/"
        "${time.year}, "
        "${TimeOfDay.fromDateTime(time).format(Get.context!)}";
  }
}
