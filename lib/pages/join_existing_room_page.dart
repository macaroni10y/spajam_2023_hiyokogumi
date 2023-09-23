import 'package:flutter/material.dart';

class JoinExistingRoomPage extends StatelessWidget {
  const JoinExistingRoomPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("部屋番号"),
            Container(
              width: 350,
              child: TextField(
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.all(8),
                  fillColor: Color.fromARGB(100, 200, 200, 200),
                  filled: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16))),
                ),
              ),
            ),
            Text("名前"),
            Container(
              width: 350,
              child: TextField(
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.all(8),
                  fillColor: Color.fromARGB(100, 200, 200, 200),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ),
              ),
            ),
            // TODO 画像と参加、とじるボタン
          ],
        ),
      ),
    );
  }
}
