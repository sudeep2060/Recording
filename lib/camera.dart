import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';

class CameraWork extends StatefulWidget {
  const CameraWork({super.key});

  @override
  State<CameraWork> createState() => _HomepageState();
}

class _HomepageState extends State<CameraWork> with WidgetsBindingObserver {
  List<CameraDescription> cameras = [];
  CameraController? cameraController;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (cameraController == null ||
        cameraController?.value.isInitialized == false) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _setupCameraController();
    }
  }

  @override
  void initState() {
    super.initState();
    _setupCameraController();
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
              Gal.putImage(picture.path);
            },
            icon: const Icon(Icons.camera, color: Colors.red, size: 100),
          ),
        ],
      ),
    );
    // return SafeArea(child: CameraPreview(cameraController!));
  }

  Future<void> _setupCameraController() async {
    List<CameraDescription> _camera = await availableCameras();
    if (_camera.isNotEmpty) {
      setState(() {
        cameras = _camera;
        cameraController = CameraController(
          _camera.last,
          ResolutionPreset.high,
        );
      });
      cameraController
          ?.initialize()
          .then((_) {
            if (!mounted) {
              return;
            }
            setState(() {});
          })
          .catchError((Object e) {
            print(e);
          });
    }
  }
}
