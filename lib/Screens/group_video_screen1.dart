
import 'package:android_pip/android_pip.dart';
import 'package:chatify/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../controllers/group_video_call_controller.dart';

class GroupVideoCallScreen1 extends StatefulWidget {
  final String channelId;
  final String token;
  final String callerId;
  final List<dynamic> receiverIds;

  const GroupVideoCallScreen1({
    super.key,
    required this.channelId,
    required this.token,
    required this.callerId,
    required this.receiverIds,
  });

  @override
  State<GroupVideoCallScreen1> createState() => _GroupVideoCallScreen1State();
}

class _GroupVideoCallScreen1State extends State<GroupVideoCallScreen1> with WidgetsBindingObserver {

  static const pipChannel = MethodChannel("chatify/pip");

  void enablePipMode() async {
    await pipChannel.invokeMethod("enablePip");
  }

  void disablePipMode() async {
    await pipChannel.invokeMethod("disablePip");
  }


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    enablePipMode(); // allow PiP

    // Listen to pip status from MainActivity
    pipChannel.setMethodCallHandler((call) async {
      if (call.method == "pipStatus") {
        bool isPip = call.arguments as bool;
        isPipMode.value = isPip;
        return;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    disablePipMode(); // stop PiP
    super.dispose();
  }

  // bool pipTriggered = false;
  var isPipMode = false.obs;

  Future<void> enterPiP() async {
    final pip = AndroidPIP();

    await pip.enterPipMode(
      aspectRatio: const [9, 16],
      autoEnter: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.put(
      GroupVideoCallController(
        channelId: widget.channelId,
        token: widget.token,
        callerId: widget.callerId,
        receiverIds: widget.receiverIds,
      ),
        permanent: true
    );

    final size = MediaQuery.sizeOf(context);
    c.screenSize = size;


    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if(!didPop){
          enterPiP();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Obx(() {
          return GestureDetector(
            onTap: c.toggleControls,
            child: Stack(
              children: [
                 Center(child: _remoteGrid(c)),

                if (c.localUserJoined.value || c.remoteUids.isNotEmpty)
                  Obx(() => AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    left: c.localVideoX.value,
                    top: c.localVideoY.value,
                    width: size.width * 0.3,
                    height: size.height * 0.2,
                    child: GestureDetector(
                      onPanUpdate: c.onLocalPanUpdate,
                      onPanEnd: (_) => c.onLocalPanEnd(),
                      // onTap: c.swapVideos,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          color: Colors.black54,
                          child: _localVideo(c),
                        ),
                      ),
                    ),
                  )),
                Obx(() {
                  if (c.isScreenSharing.value) {
                    return Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.9),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cast_connected, size: 80, color: Colors.blue),
                            const SizedBox(height: 20),
                            const Text("You're sharing your screen",
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () => c.stopScreenShare(),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              child: const Text("Stop Sharing",style: TextStyle(color: Colors.white),),
                            )
                          ],
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),

                !isPipMode.value ? _topBar(c): SizedBox.shrink(),
                // Inside _bottomControls Row
                Positioned(
                  bottom: 150,
                  left: 0,
                  right: 0,
                  child: SizedBox(
                    width: Get.width*0.2,
                    child: IconButton(
                      icon: Icon(
                        c.isScreenSharing.value ? Icons.stop_screen_share : Icons.screen_share,
                        color: c.isScreenSharing.value ? Colors.blueAccent : Colors.white,
                      ),
                      onPressed: () {
                        if (c.isScreenSharing.value) {
                          c.stopScreenShare();
                        } else {
                          c.startScreenShare();
                        }
                      },
                    ),
                  ),
                ),
                !isPipMode.value ? _bottomControls(c): SizedBox.shrink(),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _localVideo(GroupVideoCallController c) {
    return Obx(
      () {
        if (c.isVideoOff.value) {
          return const Center(
            child: Icon(Icons.videocam_off, color: Colors.white),
          );
        }
        return AgoraVideoView(
          controller: VideoViewController(
            rtcEngine: c.engine,
            canvas: const VideoCanvas(uid: 0),
          ),
        );
      },
    );
  }

  Widget _remoteGrid(GroupVideoCallController c) {
    if (c.remoteUids.isEmpty) {
      return const Center(
        child: Text(
          "Waiting for participants...",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    final views = c.remoteUids.map((uid) {
      final muted = c.remoteVideoStates[uid] ?? false;
      final name = c.participantNames[uid] ?? "User $uid";

      return muted
          ? Center(
        child: Text(name,
            style: const TextStyle(color: Colors.white54)),
      )
          : AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: c.engine,
          canvas: VideoCanvas(uid: uid, sourceType: VideoSourceType.videoSourceRemote),
          connection: RtcConnection(channelId: c.channelId),
        ),
      );
    }).toList();

    return GridView.count(
      crossAxisCount: views.length <= 2 ? 1 : 2,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: views,
    );
  }

  Widget _topBar(GroupVideoCallController c) {
    if (!c.showControls.value) return const SizedBox();

    return Positioned(
      top: 50,
      left: 0,
      right: 0,
      child: Column(
        children: [
          const Text("Group Video Call",
              style: TextStyle(color: Colors.white, fontSize: 22)),
          const SizedBox(height: 6),
          Obx(() {
            switch (c.callUIState.value) {
              case CallUIState.calling:
                return Text(
                  "Calling…",
                  style: TextStyle(
                      color: Colors.grey.shade400, fontSize: 16),
                );

              case CallUIState.connected:
                return Text(
                  c.formatDuration(c.callDuration.value),
                  style: const TextStyle(
                      color: Colors.greenAccent, fontSize: 16),
                );

              case CallUIState.timeout:
                return const Text(
                  "No answer",
                  style: TextStyle(color: Colors.redAccent, fontSize: 16),
                );
            }
          }),
        ],
      ),
    );
  }

  Widget _bottomControls(GroupVideoCallController c) {
    if (!c.showControls.value || !c.localUserJoined.value) {
      return const SizedBox();
    }

    return
    c.callUIState.value == CallUIState.connected || c.callUIState.value == CallUIState.calling
        ?
      Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Row(
            // mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  c.isMuted.value ? Icons.mic_off : Icons.mic,
                  color: Colors.white,
                ),
                onPressed: c.toggleMute,
              ),
              IconButton(
                icon: const Icon(Icons.call_end, color: Colors.red),
                onPressed: c.endCall,
              ),
              IconButton(
                icon: const Icon(Icons.cameraswitch, color: Colors.white),
                onPressed: c.switchCamera,
              ),
              IconButton(
                icon: Icon(
                  c.isVideoOff.value
                      ? Icons.videocam_off
                      : Icons.videocam,
                  color: Colors.white,
                ),
                onPressed: c.toggleVideo,
              ),
            ],
          ),
        ),
      ),
    ): c.callUIState.value == CallUIState.timeout ?

    Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: AppColors.white,
              child:
              IconButton(
                icon: Icon(Icons.close),
                onPressed:() {
                  // NotificationService().localNotifications.cancel(999);

                  Get.delete<GroupVideoCallController>(force: true);
                  Navigator.pop(context,[false]);
                },
                color: AppColors.grey,
              ),
            ),
            const SizedBox(width: 40),
            CircleAvatar(
              backgroundColor: AppColors.white,
              // child:
              // _controlButton(
              //   icon: Icons.refresh,
              //   onPressed: () {
              //     // controller.retryCall();
              //   },
              //   color: AppColors.primary,
              // ),
            ),
          ],
        ),
      ),
    )
        : const SizedBox.shrink();
  }
}
