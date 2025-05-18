import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';

class CameraWork extends StatefulWidget {
  const CameraWork({super.key});

  @override
  State<CameraWork> createState() => _HomepageState();
}

class _HomepageState extends State<CameraWork> with WidgetsBindingObserver {
  List<CameraDescription> cameras = [];
  CameraController? cameraController;
  Timer? _autoCaptureTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupCameraController();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    cameraController?.dispose();
    _autoCaptureTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController?.dispose();
      _autoCaptureTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      _setupCameraController();
    }
  }

  Future<void> _setupCameraController() async {
    List<CameraDescription> _camera = await availableCameras();
    if (_camera.isNotEmpty) {
      cameraController = CameraController(_camera.last, ResolutionPreset.high);
      await cameraController?.initialize();
      if (!mounted) return;

      setState(() {});

      _autoCaptureTimer = Timer.periodic(Duration(minutes: 1), (_) {
        _autoCaptureImage();
      });
    }
  }

  Future<void> _autoCaptureImage() async {
    if (cameraController != null &&
        cameraController!.value.isInitialized &&
        !cameraController!.value.isTakingPicture) {
      try {
        final XFile file = await cameraController!.takePicture();
        await GallerySaver.saveImage(file.path);
        print("Photo taken and saved automatically.");
      } catch (e) {
        print("Auto-capture failed: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _BuildUI());
  }

  Widget _BuildUI() {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.30,
            width: MediaQuery.sizeOf(context).width * 0.80,
            child: CameraPreview(cameraController!),
          ),
          IconButton(
            onPressed: () async {
              XFile picture = await cameraController!.takePicture();
              await GallerySaver.saveImage(picture.path);
            },
            icon: const Icon(Icons.camera, color: Colors.red, size: 100),
          ),
        ],
      ),
    );
  }
}
