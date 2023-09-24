import 'package:Zizz/pages/create_new_room_page.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'join_existing_room_page.dart';

class StartPage extends StatelessWidget {
  final CameraDescription cameraDescription;

  StartPage({super.key, required this.cameraDescription});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/illust1.png'),
            Container(
              width: 150,
              margin: EdgeInsets.only(top: 24),
              child: GestureDetector(
                  child: Image.asset('assets/images/heyabango@3x.png'),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => JoinExistingRoomPage(
                                cameraDescription: cameraDescription,
                              )))),
            ),
            Container(
              width: 150,
              margin: EdgeInsets.all(16),
              child: GestureDetector(
                child: Image.asset('assets/images/heyatsukuru@3x.png'),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => CreateNewRoomPage(
                            cameraDescription: cameraDescription))),
              ),
            )
          ],
        ),
      ),
    );
  }
}
