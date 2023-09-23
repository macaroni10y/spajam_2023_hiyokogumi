import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:spajam_2023_hiyokogumi/pages/agora_page.dart';
import 'package:spajam_2023_hiyokogumi/pages/location_with_stream_builder_sample_page.dart';
import 'package:spajam_2023_hiyokogumi/pages/push_and_notify_page.dart';

import 'camera_sample_page.dart';
import 'chat_sample_page.dart';
import 'location_sample_page.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title, required this.camera});

  final String title;
  final CameraDescription camera;

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: Column(
        children: [
          const Text("samples"),
          Card(
              child: ListTile(
                  title: const Text("Chat Sample"),
                  onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ChatSamplePage()),
                      ))),
          Card(
              child: ListTile(
                  title: const Text("Google Maps Sample"),
                  onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LocationSamplePage()),
                      ))),
          Card(
              child: ListTile(
                  title: const Text("Google Maps with StreamBuilder Sample"),
                  onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const LocationWithStreamBuilderSamplePage()),
                      ))),
          Card(
              child: ListTile(
                  title: const Text("Camera Sample"),
                  onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                CameraSamplePage(camera: camera)),
                      ))),
          Card(
              child: ListTile(
                  title: const Text("Agora as Host"),
                  onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AgoraPage()),
                      ))),
          Card(
              child: ListTile(
                  title: const Text("Push Notification Sample"),
                  onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => PushAndNotifyPage()),
                      ))),
        ],
      ));
}
