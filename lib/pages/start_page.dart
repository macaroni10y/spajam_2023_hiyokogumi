import 'package:flutter/material.dart';
import 'package:spajam_2023_hiyokogumi/pages/create_new_room_page.dart';

import 'join_existing_room_page.dart';

class StartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/animal_mark_hiyoko.png'),
            Container(
              width: 150,
              margin: EdgeInsets.only(top: 24),
              child: GestureDetector(
                  child: Image.asset('assets/images/heyabango@3x.png'),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const JoinExistingRoomPage()))),
            ),
            Container(
              width: 150,
              margin: EdgeInsets.all(16),
              child: GestureDetector(
                child: Image.asset('assets/images/heyatsukuru@3x.png'),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CreateNewRoomPage())),
              ),
            )
          ],
        ),
      ),
    );
  }
}
