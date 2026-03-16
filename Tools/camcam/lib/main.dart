import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

List<CameraDescription> _cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    _cameras = await availableCameras();
  } catch (e) {
    debugPrint('Error getting cameras: $e');
  }
  runApp(const CamCamApp());
}

class CamCamApp extends StatelessWidget {
  const CamCamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CamCam',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A1A),
          elevation: 0,
        ),
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const CameraScreen(),
    );
  }
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isRecording = false;
  bool _isInitialized = false;
  bool _permissionDenied = false;
  int _cameraIndex = 0;
  String? _lastSavedPath;
  Duration _elapsed = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestPermissionsAndInit();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera(_cameras[_cameraIndex]);
    }
  }

  Future<void> _requestPermissionsAndInit() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final camera = await Permission.camera.request();
      final mic = await Permission.microphone.request();
      if (camera.isDenied || mic.isDenied) {
        setState(() => _permissionDenied = true);
        return;
      }
    }
    if (_cameras.isNotEmpty) {
      await _initCamera(_cameras[_cameraIndex]);
    }
  }

  Future<void> _initCamera(CameraDescription camera) async {
    setState(() => _isInitialized = false);

    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _controller = controller;

    try {
      await controller.initialize();
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Camera init error: $e');
      if (mounted) {
        _showError('Failed to initialize camera: $e');
      }
    }
  }

  Future<Directory> _getSaveDirectory() async {
    Directory dir;
    if (kIsWeb) {
      // Web: use a temp path (actual save is done via download)
      dir = Directory('/tmp/CamCam');
    } else if (Platform.isAndroid) {
      final ext = await getExternalStorageDirectory();
      dir = Directory('${ext?.path ?? '/sdcard/Movies'}/CamCam');
    } else {
      final docs = await getApplicationDocumentsDirectory();
      dir = Directory('${docs.path}/CamCam');
    }
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  Future<void> _startRecording() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isRecording) return;
    try {
      await _controller!.startVideoRecording();
      _elapsed = Duration.zero;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _elapsed += const Duration(seconds: 1));
      });
      setState(() => _isRecording = true);
    } catch (e) {
      _showError('Could not start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (_controller == null || !_isRecording) return;
    _timer?.cancel();
    try {
      final xfile = await _controller!.stopVideoRecording();
      setState(() => _isRecording = false);

      final saveDir = await _getSaveDirectory();
      final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final savePath = '${saveDir.path}/VID_$ts.mp4';

      await File(xfile.path).copy(savePath);
      try {
        await File(xfile.path).delete();
      } catch (_) {}

      setState(() => _lastSavedPath = savePath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved: $savePath'),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(label: 'OK', onPressed: () {}),
          ),
        );
      }
    } catch (e) {
      setState(() => _isRecording = false);
      _showError('Could not stop recording: $e');
    }
  }

  void _switchCamera() async {
    if (_cameras.length < 2 || _isRecording) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _controller?.dispose();
    await _initCamera(_cameras[_cameraIndex]);
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade800,
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildTitle(),
        actions: _buildActions(),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildTitle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('CamCam', style: TextStyle(fontWeight: FontWeight.bold)),
        if (_isRecording) ...[
          const SizedBox(width: 12),
          _RecordingDot(),
          const SizedBox(width: 4),
          Text(
            _formatDuration(_elapsed),
            style: const TextStyle(
              color: Colors.red,
              fontSize: 14,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildActions() {
    return [
      if (_cameras.length > 1)
        IconButton(
          icon: const Icon(Icons.flip_camera_ios_outlined),
          tooltip: 'Switch camera',
          onPressed: (_isInitialized && !_isRecording) ? _switchCamera : null,
        ),
      const SizedBox(width: 4),
      _RecordButton(
        isRecording: _isRecording,
        enabled: _isInitialized,
        onStart: _startRecording,
        onStop: _stopRecording,
      ),
      const SizedBox(width: 8),
    ];
  }

  Widget _buildBody() {
    if (_permissionDenied) {
      return _CenteredMessage(
        icon: Icons.videocam_off,
        message: 'Camera or microphone permission denied.\n'
            'Please grant access in system settings.',
        action: TextButton(
          onPressed: openAppSettings,
          child: const Text('Open Settings'),
        ),
      );
    }

    if (_cameras.isEmpty) {
      return const _CenteredMessage(
        icon: Icons.videocam_off,
        message: 'No cameras found on this device.',
      );
    }

    if (!_isInitialized || _controller == null) {
      return const _CenteredMessage(
        icon: null,
        message: 'Initializing camera…',
        showSpinner: true,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: CameraPreview(_controller!),
          ),
        ),
        if (_lastSavedPath != null && !_isRecording)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Last saved: $_lastSavedPath',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _RecordButton extends StatelessWidget {
  const _RecordButton({
    required this.isRecording,
    required this.enabled,
    required this.onStart,
    required this.onStop,
  });

  final bool isRecording;
  final bool enabled;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    if (isRecording) {
      return FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: Colors.red),
        icon: const Icon(Icons.stop_rounded),
        label: const Text('Stop'),
        onPressed: onStop,
      );
    }
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: enabled ? Colors.green.shade700 : Colors.grey,
      ),
      icon: const Icon(Icons.fiber_manual_record),
      label: const Text('Record'),
      onPressed: enabled ? onStart : null,
    );
  }
}

class _RecordingDot extends StatefulWidget {
  @override
  State<_RecordingDot> createState() => _RecordingDotState();
}

class _RecordingDotState extends State<_RecordingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: const Icon(Icons.fiber_manual_record, color: Colors.red, size: 14),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.message,
    this.action,
    this.showSpinner = false,
  });

  final IconData? icon;
  final String message;
  final Widget? action;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSpinner)
            const CircularProgressIndicator(color: Colors.white)
          else if (icon != null)
            Icon(icon, size: 64, color: Colors.white38),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          if (action != null) ...[
            const SizedBox(height: 12),
            action!,
          ],
        ],
      ),
    );
  }
}
