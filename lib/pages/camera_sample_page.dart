import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraSamplePage extends StatefulWidget {
  const CameraSamplePage({super.key, required this.camera});
  final CameraDescription camera;

  @override
  State<CameraSamplePage> createState() => _CameraSamplePageState();
}

class _CameraSamplePageState extends State<CameraSamplePage> {
  late CameraController _controller;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  _initCamera() async {
    _controller = CameraController(widget.camera, ResolutionPreset.max);
    _controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            // Handle access errors here.
            break;
          default:
            // Handle other errors here.
            break;
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const CircularProgressIndicator();
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Camera Sample Page"),
      ),
      body: Column(
        children: [
          Flexible(
            child: Center(child: CameraPreview(_controller)),
          ),
          ElevatedButton(
              onPressed: () {
                 _controller.setFocusMode(FocusMode.locked);
                 _controller.setExposureMode(ExposureMode.locked);
                _controller.takePicture().then((file) => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              TakenPicturePage(path: file.path)),
                    ));
                 _controller.setFocusMode(FocusMode.auto);
                 _controller.setExposureMode(ExposureMode.auto);
              },
              child: const Icon(Icons.camera_alt))
        ],
      ),
    );
  }
}

class TakenPicturePage extends StatelessWidget {
  const TakenPicturePage({Key? key, required this.path}) : super(key: key);

  final String path;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Camera Sample Page')),
        body: Center(child: Image.file(File(path))),
      );
}
