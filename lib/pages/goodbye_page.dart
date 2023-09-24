import 'package:Zizz/pages/start_page.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class GoodbyePage extends StatelessWidget {
  const GoodbyePage({super.key, required this.cameraDescription});
  final CameraDescription cameraDescription;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/illust4.png'),
            Container(
              margin: EdgeInsets.all(16),
              child: const Text(
                "おつかれさまでした！",
                style: TextStyle(fontSize: 18),
              ),
            ),
            Container(
              width: 100,
              child: GestureDetector(
                onTap: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (BuildContext context) => StartPage(
                            cameraDescription: cameraDescription,
                          )),
                  (Route<dynamic> route) => false,
                ),
                child: Image.asset('assets/images/ok@3x.png'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
