import 'dart:async';
import 'package:get/get.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import '../constants/apis.dart';
import '../controllers/message_controller.dart';
import '../controllers/profile_controller.dart';

class GroupVideoCallScreen extends StatefulWidget {
  final String channelId;
  final String token;
  final String callerId;
  final List<dynamic> receiverIds;

  const GroupVideoCallScreen(
      {super.key,
      required this.channelId,
      required this.token,
      required this.callerId,
      required this.receiverIds});

  @override
  _MainScreenScreenState createState() => _MainScreenScreenState();
}

class _MainScreenScreenState extends State<GroupVideoCallScreen> {
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isConnected = false;
  bool _isCallActive = true;
  final Map<int, bool> _remoteVideoStates = {};
  bool _isLocalMain = false;
  double _localVideoX = 20;
  double _localVideoY = 50;
  Duration _callDuration = Duration.zero;
  Timer? _timer;

  final Set<int> _remoteUids = {}; // Stores remote user ID
  late Map<int, String> participantNames = {};


  bool _localUserJoined =
      false; // local user has joined or not
  late RtcEngine _engine; // Stores Agora RTC Engine instance

  final messageController = Get.put(MessageController());
  final profileController = Get.find<ProfileController>();

  @override
  void initState() {
    super.initState();
    for (var user in widget.receiverIds) {
      participantNames[user['id']] = "${user['firstName']} ${user['lastName']}";
    }

    _startVideoCalling();
  }

  // Initializes Agora SDK
  Future<void> _startVideoCalling() async {
    await _initializeAgoraVideoSDK();
    await _setupLocalVideo();
    _setupEventHandlers();
    await _joinChannel();
  }


  // Set up the Agora RTC engine instance
  Future<void> _initializeAgoraVideoSDK() async {
    _engine = createAgoraRtcEngine();
    await _engine.initialize(
      const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );
  }

  // Enables and starts local video preview
  Future<void> _setupLocalVideo() async {
    await _engine.enableVideo();
    await _engine.startPreview();
  }

  // Register an event handler for Agora RTC
  void _setupEventHandlers() {
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("Local user ${connection.localUid} joined");
          setState(() => _localUserJoined = true);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("👤 Remote user $remoteUid joined");

          setState(() {
            _remoteUids.add(remoteUid);
            _isConnected = true;
          });
          if (_callDuration == Duration.zero) _startTimer();
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          debugPrint(" Remote user $remoteUid left");
          setState(() => _remoteUids.remove(remoteUid));

          // End call only if all remote users left
          if (_remoteUids.isEmpty) {
            _endCallForBoth();
          }
        },
        onUserMuteVideo: (RtcConnection connection, int remoteUid, bool muted) {
          setState(() {
            _remoteVideoStates[remoteUid] = muted;
          });
        },
      ),
    );
  }

  // Join a channel
  Future<void> _joinChannel() async {
    await _engine.joinChannel(
      token: widget.token,
      channelId: widget.channelId,
      options: const ChannelMediaOptions(
        autoSubscribeVideo: true,
        autoSubscribeAudio: true,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
      uid: profileController.user.value!.id!,
    );
  }

  @override
  void dispose() {
    _cleanupAgoraEngine();
    super.dispose();
  }

  // Leaves the channel and releases resources
  Future<void> _cleanupAgoraEngine() async {
    try {
      await _engine.leaveChannel();
    } catch (e) {
      debugPrint(" leaveChannel error: $e");
    }

    try {
      await _engine.stopPreview();
    } catch (e) {
      debugPrint("stopPreview error: $e");
    }

    try {
      await _engine.release();
    } catch (e) {
      debugPrint(" release error: $e");
    }

    debugPrint("Agora engine cleaned up safely");
  }

  void _toggleMute() async {
    setState(() => _isMuted = !_isMuted);
    await _engine.muteLocalAudioStream(_isMuted);
  }

  void _toggleVideo() async {
    setState(() => _isVideoOff = !_isVideoOff);
    // await _engine.muteLocalVideoStream(_isVideoOff);
    await _engine.updateChannelMediaOptions(
      ChannelMediaOptions(
        publishCameraTrack: !_isVideoOff,
      ),
    );
  }

  void _switchCamera() async {
    await _engine.switchCamera();
  }

  void _endCallForBoth() async {
    if (!_isCallActive) return; // Prevent double pop
    _isCallActive = false;

    await messageController.endGroupCall(
        channelId: widget.channelId,
        callerId: widget.callerId,
        receiverIds: widget.receiverIds.map((e) => e['id'].toString()).toList());

    _timer?.cancel();
    await _cleanupAgoraEngine();

    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _swapVideos() {
    setState(() {
      _isLocalMain = !_isLocalMain;
    });
  }

  // for slide on-off button-row

  bool _showControls = true;
  Timer? _hideTimer;

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);

    if (_showControls) {
      _startHideTimer();
    } else {
      _hideTimer?.cancel();
    }
  }

  // for call duration

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _callDuration = _callDuration + const Duration(seconds: 1);
      });
    });
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    final mainVideo = _remoteVideoGrid();
    final smallVideo = _localVideo();

    final size = MediaQuery.sizeOf(context);


    return Scaffold(
      backgroundColor: Colors.white70,

      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            Center(child: mainVideo),
            if (_localUserJoined || _remoteUids.isNotEmpty)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                left: _localVideoX,
                top: _localVideoY,
                width: size.width * 0.3,
                height: size.height * 0.2,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _localVideoX = (_localVideoX + details.delta.dx)
                          .clamp(0.0, size.width - size.width * 0.3);
                      _localVideoY = (_localVideoY + details.delta.dy)
                          .clamp(0.0, size.height - size.height * 0.2);
                    });
                  },
                  onPanEnd: (details) {
                    final screenWidth = size.width;
                    final targetX = _localVideoX < screenWidth / 2
                        ? 16.0 // Snap to left with margin
                        : screenWidth -
                            size.width * 0.3 -
                            16.0; // Snap to right with margin

                    // Keep vertical position inside screen bounds
                    final targetY = _localVideoY.clamp(
                      50.0,
                      size.height -
                          size.height * 0.2 -
                          100.0, // keep above bottom controls
                    );

                    setState(() {
                      _localVideoX = targetX;
                      _localVideoY = targetY;
                    });
                  },
                  onTap: _swapVideos,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      color: Colors.black54,
                      child: smallVideo,
                    ),
                  ),
                ),
              ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              top: _showControls ? size.height * 0.06 : -size.height * 0.07,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: _showControls ? 1 : 0,
                child: Column(
                  children: [
                    Text(
                      "Group Video Call",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isConnected
                          ? _formatDuration(_callDuration)
                          : "Calling…",
                      style: TextStyle(
                        color: _isConnected ? Colors.greenAccent : Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              bottom: _showControls ? size.height * 0.06 : -size.height * 0.07,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: _showControls ? 1 : 0,
                child: !_localUserJoined
                    ? SizedBox()
                    : Center(
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 5,
                              // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _controlButton(
                                  icon: _isMuted ? Icons.mic_off : Icons.mic,
                                  onPressed: _toggleMute,
                                ),
                                VerticalDivider(
                                  color: Colors.white38,
                                  thickness: 1,
                                  indent: 15,
                                  endIndent: 15,
                                ),
                                _controlButton(
                                  icon: Icons.call_end,
                                  color: Colors.redAccent,
                                  onPressed: _endCallForBoth,
                                ),
                                VerticalDivider(
                                  color: Colors.white38,
                                  thickness: 1,
                                  indent: 15,
                                  endIndent: 15,
                                ),
                                _controlButton(
                                  icon: Icons.cameraswitch,
                                  onPressed: _switchCamera,
                                ),
                                VerticalDivider(
                                  color: Colors.white38,
                                  thickness: 1,
                                  indent: 15,
                                  endIndent: 15,
                                ),
                                _controlButton(
                                  icon: _isVideoOff
                                      ? Icons.videocam_off
                                      : Icons.videocam,
                                  onPressed: _toggleVideo,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Displays remote video view
  Widget _localVideo() {
    if (_isVideoOff) {
      // Show placeholder or blank view when camera is off
      return const Center(
        child: Icon(Icons.videocam_off, size: 40),
      );
    }
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: _engine,
        canvas: const VideoCanvas(
          uid: 0,
          renderMode: RenderModeType.renderModeHidden,
        ),
      ),
    );
  }

  // Displays remote video view
  Widget _remoteVideoGrid() {
    if (_remoteUids.isEmpty) {
      return const Center(
        child: Text('Waiting for participants...'),
      );
    }

    final remoteViews = _remoteUids.map((uid) {
      final isMuted = _remoteVideoStates[uid] ?? false;
      final name = participantNames[uid] ?? "User $uid";

      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white10),
          borderRadius: BorderRadius.circular(12),
          color: Colors.transparent,
        ),
        child: isMuted
            ? Center(
                child: Text(
                  name,
                  style: const TextStyle(color: Colors.white54, fontSize: 16),
                ),
              )
            : AgoraVideoView(
                controller: VideoViewController.remote(
                  rtcEngine: _engine,
                  canvas: VideoCanvas(uid: uid),
                  connection: RtcConnection(channelId: widget.channelId),
                ),
              ),
      );
    }).toList();

    int count = remoteViews.length + 1; // +1 for local user
    int crossAxisCount = count <= 2 ? 1 : (count <= 4 ? 2 : 3);

    return GridView.count(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: [
        ...remoteViews,
      ],
    );
  }

  Widget _controlButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color color = Colors.white,
  }) {
    return CircleAvatar(
      radius: 28,
      backgroundColor: Colors.transparent,
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: onPressed,
      ),
    );
  }
}
