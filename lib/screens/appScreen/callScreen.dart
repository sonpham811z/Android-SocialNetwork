import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../config/theme.dart';
import '../../services/agoraService.dart';

class CallScreen extends StatefulWidget {
  final String conversationId;
  final String calleeName;
  final String? calleeAvatarUrl;
  final bool isVideo;

  const CallScreen({
    super.key,
    required this.conversationId,
    required this.calleeName,
    this.calleeAvatarUrl,
    this.isVideo = false,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final _agoraService = AgoraService();
  RtcEngine? _engine;

  bool _joined      = false;
  bool _muted       = false;
  bool _speakerOn   = true;
  bool _cameraOff   = false;
  bool _isLoading   = true;
  String? _error;
  int? _remoteUid;

  @override
  void initState() {
    super.initState();
    _initCall();
  }

  @override
  void dispose() {
    _engine?.leaveChannel(options: const LeaveChannelOptions());
    _engine?.release();
    super.dispose();
  }

  Future<void> _initCall() async {
    try {
      // Xin quyền microphone (và camera nếu là video call)
      final permissions = [Permission.microphone];
      if (widget.isVideo) permissions.add(Permission.camera);
      final statuses = await permissions.request();

      final denied = statuses.values.any((s) => s.isDenied || s.isPermanentlyDenied);
      if (denied) {
        setState(() {
          _error = widget.isVideo
              ? 'Cần quyền truy cập microphone và camera.'
              : 'Cần quyền truy cập microphone.';
          _isLoading = false;
        });
        return;
      }

      // Lấy token từ backend
      final tokenRes = await _agoraService.getCallToken(
        widget.conversationId,
        isVideo: widget.isVideo,
      );

      // Khởi tạo Agora engine
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(appId: tokenRes.appId));

      _engine!.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          if (mounted) setState(() { _joined = true; _isLoading = false; });
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          if (mounted) setState(() => _remoteUid = remoteUid);
        },
        onUserOffline: (connection, remoteUid, reason) {
          if (mounted) setState(() => _remoteUid = null);
          _endCall();
        },
        onError: (err, msg) {
          if (mounted) setState(() { _error = 'Lỗi: $msg'; _isLoading = false; });
        },
      ));

      if (widget.isVideo) {
        await _engine!.enableVideo();
        await _engine!.startPreview();
      }

      await _engine!.setEnableSpeakerphone(_speakerOn);

      await _engine!.joinChannel(
        token:     tokenRes.token,
        channelId: tokenRes.channelName,
        uid:       0,
        options:   const ChannelMediaOptions(
          clientRoleType:   ClientRoleType.clientRoleBroadcaster,
          channelProfile:   ChannelProfileType.channelProfileCommunication,
        ),
      );
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _endCall() {
    _engine?.leaveChannel(options: const LeaveChannelOptions());
    if (mounted) Navigator.pop(context);
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _engine?.muteLocalAudioStream(_muted);
  }

  void _toggleSpeaker() {
    setState(() => _speakerOn = !_speakerOn);
    _engine?.setEnableSpeakerphone(_speakerOn);
  }

  void _toggleCamera() {
    setState(() => _cameraOff = !_cameraOff);
    _engine?.muteLocalVideoStream(_cameraOff);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_error != null) return _buildErrorView();
    if (_isLoading)     return _buildLoadingView();
    return widget.isVideo ? _buildVideoCall() : _buildVoiceCall();
  }

  Widget _buildLoadingView() {
    return const Scaffold(
      backgroundColor: Color(0xFF1A1A2E),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.violetPrimary),
            SizedBox(height: 16),
            Text('Đang kết nối...', style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 56),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.violetPrimary),
                  child: const Text('Quay lại'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Voice Call UI ──────────────────────────────────────────────────────────

  Widget _buildVoiceCall() {
    final statusText = _remoteUid != null
        ? 'Đang kết nối'
        : (_joined ? 'Đang gọi...' : 'Đang kết nối...');

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            _buildCallerInfo(statusText),
            const Spacer(),
            _buildControls(),
            const SizedBox(height: 56),
          ],
        ),
      ),
    );
  }

  // ── Video Call UI ──────────────────────────────────────────────────────────

  Widget _buildVideoCall() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote video — full screen
          if (_remoteUid != null && _engine != null)
            AgoraVideoView(
              controller: VideoViewController.remote(
                rtcEngine:  _engine!,
                canvas:     VideoCanvas(uid: _remoteUid),
                connection: RtcConnection(channelId: widget.conversationId),
              ),
            )
          else
            Container(
              color: const Color(0xFF1A1A2E),
              child: Center(
                child: _buildCallerInfo(_joined ? 'Đang gọi...' : 'Đang kết nối...'),
              ),
            ),

          // Local preview — picture-in-picture (top-right)
          if (widget.isVideo && !_cameraOff && _engine != null)
            Positioned(
              top: 48,
              right: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 96,
                  height: 144,
                  child: AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: _engine!,
                      canvas:    const VideoCanvas(uid: 0),
                    ),
                  ),
                ),
              ),
            ),

          // Controls overlay — bottom
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              padding: const EdgeInsets.only(top: 24, bottom: 48),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end:   Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                ),
              ),
              child: _buildControls(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared widgets ─────────────────────────────────────────────────────────

  Widget _buildCallerInfo(String statusText) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 56,
          backgroundColor: AppTheme.slate800,
          backgroundImage: widget.calleeAvatarUrl != null
              ? NetworkImage(widget.calleeAvatarUrl!)
              : null,
          child: widget.calleeAvatarUrl == null
              ? Text(
                  widget.calleeName.isNotEmpty ? widget.calleeName[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                )
              : null,
        ),
        const SizedBox(height: 20),
        Text(widget.calleeName,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(statusText, style: const TextStyle(color: Colors.white60, fontSize: 15)),
      ],
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ControlBtn(
          icon:  _muted ? Icons.mic_off : Icons.mic,
          label: _muted ? 'Bỏ tắt tiếng' : 'Tắt tiếng',
          color: _muted ? Colors.red : Colors.white,
          onTap: _toggleMute,
        ),
        if (widget.isVideo)
          _ControlBtn(
            icon:  _cameraOff ? Icons.videocam_off : Icons.videocam,
            label: _cameraOff ? 'Bật camera' : 'Tắt camera',
            color: _cameraOff ? Colors.red : Colors.white,
            onTap: _toggleCamera,
          ),
        _ControlBtn(
          icon:    Icons.call_end,
          label:   'Kết thúc',
          color:   Colors.white,
          bgColor: Colors.red,
          large:   true,
          onTap:   _endCall,
        ),
        _ControlBtn(
          icon:  _speakerOn ? Icons.volume_up : Icons.volume_off,
          label: 'Loa',
          color: _speakerOn ? AppTheme.violetPrimary : Colors.white,
          onTap: _toggleSpeaker,
        ),
      ],
    );
  }
}

// ── Control button widget ──────────────────────────────────────────────────────

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color? bgColor;
  final bool large;
  final VoidCallback onTap;

  const _ControlBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.bgColor,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius    = large ? 34.0 : 26.0;
    final iconSize  = large ? 26.0 : 20.0;
    final bg        = bgColor ?? color.withOpacity(0.2);
    final iconColor = bgColor != null ? Colors.white : color;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: CircleAvatar(
            radius:          radius,
            backgroundColor: bg,
            child:           Icon(icon, color: iconColor, size: iconSize),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}
