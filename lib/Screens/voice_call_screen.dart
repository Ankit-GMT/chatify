import 'dart:async';
import 'dart:ui';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../constants/apis.dart';

class VoiceCallScreen extends StatefulWidget {
  final String channelId;
  final String token;
  const VoiceCallScreen({super.key, required this.channelId, required this.token});

  @override
  _MainScreenScreenState createState() => _MainScreenScreenState();
}

class _MainScreenScreenState extends State<VoiceCallScreen> {
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isConnected = false;
  Duration _callDuration = Duration.zero;
  Timer? _timer;

  // Simulated remote-end flag (use signaling in real app)
  bool _isCallActive = true;

  late RtcEngine _engine; // Stores Agora RTC Engine instance
  int? _remoteUid; // Stores the remote user's UID
  @override
  void initState() {
    super.initState();
    _startVoiceCalling();
  }

  // Initializes Agora SDK
  Future<void> _startVoiceCalling() async {
    await _requestPermissions();
    await _initializeAgoraVoiceSDK();
    _setupEventHandlers();
    await _joinChannel();
  }

  // Requests microphone permission
  Future<void> _requestPermissions() async {
    await [Permission.microphone].request();
  }

  // Set up the Agora RTC engine instance
  Future<void> _initializeAgoraVoiceSDK() async {
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));
  }

  // Register an event handler for Agora RTC
  void _setupEventHandlers() {
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          debugPrint("Local user ${connection.localUid} joined");
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          debugPrint("Remote user $remoteUid joined");
          setState(() {
            _remoteUid = remoteUid;
            _isConnected = true;
          });
          _startTimer();
        },
        onUserOffline: (connection, remoteUid, reason) {
          debugPrint("Remote user $remoteUid left");
          _endCallForBoth();
        },
      ),
    );
  }

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

  // Join a channel
  Future<void> _joinChannel() async {

    await _engine.joinChannel(
      token: widget.token,
      channelId: widget.channelId,
      options: const ChannelMediaOptions(
        autoSubscribeAudio: true,
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

  // for mute audio
  void _toggleMute() async {
    setState(() => _isMuted = !_isMuted);
    await _engine.muteLocalAudioStream(_isMuted);
  }

  // for speaker
  void _toggleSpeaker() async {
    setState(() => _isSpeakerOn = !_isSpeakerOn);
    await _engine.setEnableSpeakerphone(_isSpeakerOn);
  }

  // for call end
  // void _endCall() async {
  //   await _engine.leaveChannel();
  //   // await _engine.release();
  //   if (mounted) Navigator.pop(context);
  // }
  void _endCallForBoth() async {
    if (!_isCallActive) return; // Prevent double pop
    _isCallActive = false;

    _timer?.cancel();
    await _cleanupAgoraEngine();

    if (mounted) {
      Navigator.pop(context);
    }

    // If using backend signaling (e.g. Firebase / Socket)
    // send "call_ended" event to other user so they also pop.
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return; // already popped, nothing to do

        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Are you sure you want to exit?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes'),
              ),
            ],
          ),
        );

        if (shouldExit == true) {
          // Exit app (or you could use Navigator.pop(context) to go back)
          // SystemNavigator.pop();
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        // appBar: AppBar(
        //   title: const Text('Agora Voice Call'),
        // ),
        body: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xff2a2a2a),
                  // gradient:
                ),
              ),
            ),
            Positioned(
              left: size.width * 0.7,
              top: size.height * 0.2,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                    sigmaX: 228.4, sigmaY: 228.4, tileMode: TileMode.decal),
                child: Container(
                  width: size.width * 0.67,
                  height: size.width * 0.67,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC35E31).withAlpha(140),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Positioned(
              right: size.width * 0.7,
              top: size.height * 0.2,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                    sigmaX: 228.4, sigmaY: 228.4, tileMode: TileMode.decal),
                child: Container(
                  width: size.width * 0.67,
                  height: size.width * 0.67,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC35E31).withAlpha(140),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Column(
              children: [
                SizedBox(
                  height: size.height * 0.27,
                ),
                CircleAvatar(
                  radius: size.width * 0.25,
                  backgroundColor: Colors.grey.shade800,
                  // backgroundImage: const AssetImage('assets/profile.jpg'),
                  // Replace with user image
                  child:
                  const Icon(Icons.person, size: 60, color: Colors.white70),
                ),
                const SizedBox(height: 24),
                Text(
                  "John Doe",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isConnected ? _formatDuration(_callDuration) : "Calling…",
                  style: TextStyle(
                    color:
                    _isConnected ? Colors.greenAccent : Colors.grey.shade400,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 100),
                child:
                // !_localUserJoined
                //     ? SizedBox()
                //     :
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                          icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                          onPressed: _toggleSpeaker,
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
                      ],
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