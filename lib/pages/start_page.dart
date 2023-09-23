import 'package:flutter/material.dart';

class StartPage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Image.asset('assets/images/animal_mark_hiyoko.png'),
          Image.asset('assets/images/heyabango@3x.png'),
          Image.asset('assets/images/heyatsukuru@3x.png'),
        ],
      ),
    );
  }
}