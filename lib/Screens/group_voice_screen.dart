import 'dart:async';
import 'package:get/get.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import '../constants/apis.dart';
import '../controllers/message_controller.dart';
import '../controllers/profile_controller.dart';

class GroupVoiceCallScreen extends StatefulWidget {
  final String channelId;
  final String token;
  final String callerId;
  final List<String> receiverIds;

  const GroupVoiceCallScreen(
      {super.key,
      required this.channelId,
      required this.token,
      required this.callerId,
      required this.receiverIds});

  @override
  _MainScreenScreenState createState() => _MainScreenScreenState();
}

class _MainScreenScreenState extends State<GroupVoiceCallScreen> {
  bool _isMuted = false;

  // bool _isVideoOff = false;
  bool _isSpeakerOn = false;
  bool _isConnected = false;
  bool _isCallActive = true;

  // final Map<int, bool> _remoteVideoStates = {};
  bool _isLocalMain = false;

  // double _localVideoX = 20;
  // double _localVideoY = 50;
  Duration _callDuration = Duration.zero;
  Timer? _timer;

  final Set<int> _remoteUids = {}; // Stores remote user ID
  bool _localUserJoined = false; // local user has joined or not
  late RtcEngine _engine; // Stores Agora RTC Engine instance

  final messageController = Get.put(MessageController());
  final profileController = Get.find<ProfileController>();

  @override
  void initState() {
    super.initState();
    _startVoiceCalling();
  }

  // Initializes Agora SDK
  Future<void> _startVoiceCalling() async {
    await _initializeAgoraVoiceSDK();
    // await _setupLocalVideo();
    _setupEventHandlers();
    await _joinChannel();
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
      ),
    );
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

  void _toggleSpeaker() async {
    setState(() => _isSpeakerOn = !_isSpeakerOn);
    await _engine.setEnableSpeakerphone(_isSpeakerOn);
  }

  void _endCallForBoth() async {
    if (!_isCallActive) return; // Prevent double pop
    _isCallActive = false;

    await messageController.endGroupCall(
        channelId: widget.channelId,
        callerId: widget.callerId,
        receiverIds: widget.receiverIds);

    _timer?.cancel();
    await _cleanupAgoraEngine();

    if (mounted) {
      Navigator.pop(context);
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
    final size = MediaQuery.sizeOf(context);
    final allUsers = ["You", ..._remoteUids.map((e) => "User $e")];

    return Scaffold(
      backgroundColor: Colors.white70,
      body: Column(
        children: [
          SizedBox(
            height: size.height * 0.07,
          ),
          Text(
            "Group Name",
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
              color: _isConnected ? Colors.greenAccent : Colors.grey.shade400,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: allUsers.length,
              itemBuilder: (context, index) {
                final name = allUsers[index];
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blueGrey.shade700,
                      child: Icon(Icons.person, color: Colors.white, size: 30),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      name,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                );
              },
            ),
          ),
          !_localUserJoined
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
                            icon: _isSpeakerOn
                                ? Icons.volume_up
                                : Icons.volume_off,
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
          SizedBox(
            height: size.height * 0.05,
          ),
        ],
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
