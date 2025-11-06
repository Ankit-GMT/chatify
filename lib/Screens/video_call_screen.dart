import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../constants/apis.dart';

class VideoCallScreen extends StatefulWidget {
  final String channelId;
  final String token;
  const VideoCallScreen({super.key, required this.channelId, required this.token});

  @override
  _MainScreenScreenState createState() => _MainScreenScreenState();
}

class _MainScreenScreenState extends State<VideoCallScreen> {
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isConnected = false;
  bool _isCallActive = true;
  bool _isRemoteVideoOff = false;
  bool _isLocalMain = false;
  double _localVideoX = 20;
  double _localVideoY = 50;
  Duration _callDuration = Duration.zero;
  Timer? _timer;

  int? _remoteUid; // Stores remote user ID
  bool _localUserJoined =
  false; // Indicates if local user has joined the channel
  late RtcEngine _engine; // Stores Agora RTC Engine instance
  @override
  void initState() {
    super.initState();
    _startVideoCalling();
  }

  // Initializes Agora SDK
  Future<void> _startVideoCalling() async {
    await _initializeAgoraVideoSDK();
    await _requestPermissions();
    await _setupLocalVideo();
    _setupEventHandlers();
    await _joinChannel();
  }

  // Requests microphone and camera permissions
  Future<void> _requestPermissions() async {
    await [Permission.microphone, Permission.camera].request();
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
          debugPrint("Remote user $remoteUid joined");
          setState(() {
            _remoteUid = remoteUid;
            _isRemoteVideoOff = false;
            _isConnected = true;
          });
          _startTimer();
        },
        onUserOffline: (
            RtcConnection connection,
            int remoteUid,
            UserOfflineReasonType reason,
            ) {
          debugPrint("Remote user $remoteUid left");
          if (remoteUid == _remoteUid) {
            setState(() {
              _remoteUid = null;
              _isRemoteVideoOff = false;
            });
          }
          _endCallForBoth();
        },
        onUserMuteVideo: (RtcConnection connection, int remoteUid, bool muted) {
          if (remoteUid == _remoteUid) {
            setState(() => _isRemoteVideoOff = muted);
          }
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
      uid: 0,
    );
  }

  @override
  void dispose() {
    _cleanupAgoraEngine();
    super.dispose();
  }

  // Leaves the channel and releases resources
  Future<void> _cleanupAgoraEngine() async {
    await _engine.leaveChannel();
    await _engine.release();
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
    final mainVideo = _isLocalMain ? _localVideo() : _remoteVideo();
    final smallVideo = _isLocalMain ? _remoteVideo() : _localVideo();

    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: Colors.white70,
      // appBar: AppBar(
      //   title: const Text('Agora Video Calling'),
      //   automaticallyImplyLeading: false,
      // ),
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            Center(child: mainVideo),

            // Small preview (tappable)
            // if (_localUserJoined || _remoteUid != null)
            //   Positioned(
            //     left: _localVideoX,
            //     top: _localVideoY,
            //     width: size.width*0.3,
            //     height: size.height *0.2,
            //     child: GestureDetector(
            //       onPanUpdate: (details) {
            //         setState(() {
            //           _localVideoX = (_localVideoX + details.delta.dx).clamp(0.0, size.width - size.width*0.3);
            //           _localVideoY = (_localVideoY + details.delta.dy).clamp(0.0, size.height - size.height *0.3);
            //         });
            //       },
            //       onTap: _swapVideos,
            //       child: ClipRRect(
            //         borderRadius: BorderRadius.circular(12),
            //         child: Container(
            //           color: Colors.black54,
            //           child: smallVideo,
            //         ),
            //       ),
            //     ),
            //   ),

            if (_localUserJoined || _remoteUid != null)
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
                      "John Doe",
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
                        color: _isConnected
                            ? Colors.greenAccent
                            : Colors.grey,
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
  Widget _remoteVideo() {
    if (_remoteUid != null) {
      if (_isRemoteVideoOff) {
        // Remote user turned off camera → show placeholder
        return const Center(
          child: Icon(Icons.videocam_off, size: 80),
        );
      }
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: widget.channelId ),
        ),
      );
    } else {
      return const Text(
        'Waiting for remote user to join...',
        textAlign: TextAlign.center,
      );
    }
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