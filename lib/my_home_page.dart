import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> with WidgetsBindingObserver {
  List<CameraDescription> cameras = [];
  CameraController? cameraController;
  bool isRecording = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupCameraController();
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
        _availableCameras
            .last, //use first for front camera other wise use last for back camera
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
            onPressed: () async {
              if (isRecording) {
                XFile videoFile = await cameraController!.stopVideoRecording();
                print('Video saved to: ${videoFile.path}');
                Gal.putVideo(videoFile.path);
                setState(() => isRecording = false);
              } else {
                await cameraController!.startVideoRecording();
                setState(() => isRecording = true);
              }
            },
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
