import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> with WidgetsBindingObserver {
  List<CameraDescription> cameras = [];
  CameraController? cameraController;
  bool isRecording = false;
  bool isBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    await _requestPermissions();
    await _setupCameraController();
  }

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    await Permission.microphone.request();
    await Permission.storage.request();
  }

  @override
  void dispose() {
    cameraController?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (cameraController == null || !cameraController!.value.isInitialized)
      return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _setupCameraController();
    }
  }

  Future<void> _setupCameraController() async {
    final _availableCameras = await availableCameras();
    if (_availableCameras.isNotEmpty) {
      cameraController = CameraController(
        _availableCameras.last,
        ResolutionPreset.high,
        enableAudio: true,
      );

      await cameraController?.initialize();
      if (!mounted) return;
      setState(() {
        cameras = _availableCameras;
      });
    }
  }

  Future<void> _toggleRecording() async {
    if (cameraController == null || !cameraController!.value.isInitialized) return;

    if (isBusy) return;
    isBusy = true;

    try {
      if (isRecording) {
        XFile videoFile = await cameraController!.stopVideoRecording();
        setState(() => isRecording = false);

        print('Video saved to: ${videoFile.path}');
        await Gal.putVideo(videoFile.path);
        _showSnackbar('Video saved to gallery');
      } else {
        await cameraController!.prepareForVideoRecording();
        await cameraController!.startVideoRecording();
        setState(() => isRecording = true);
        _showSnackbar('Recording started...');
      }
    } catch (e) {
      _showSnackbar('Error: ${e.toString()}');
    } finally {
      isBusy = false;
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Widget _buildUI() {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AspectRatio(
            aspectRatio: cameraController!.value.aspectRatio,
            child: CameraPreview(cameraController!),
          ),
          const SizedBox(height: 40),
          IconButton(
            icon: Icon(
              isRecording ? Icons.stop_circle : Icons.videocam,
              color: isRecording ? Colors.red : Colors.green,
              size: 80,
            ),
            onPressed: _toggleRecording,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildUI());
  }
}
