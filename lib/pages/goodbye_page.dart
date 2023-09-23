import 'package:flutter/material.dart';
import 'package:Zizz/pages/start_page.dart';

class GoodbyePage extends StatelessWidget {
  const GoodbyePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/animal_mark_hiyoko.png'),
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
                      builder: (BuildContext context) => StartPage()),
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
