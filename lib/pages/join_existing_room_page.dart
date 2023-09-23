import 'package:flutter/material.dart';
import 'package:spajam_2023_hiyokogumi/pages/meeting_page.dart';

class JoinExistingRoomPage extends StatefulWidget {
  const JoinExistingRoomPage({super.key});

  @override
  State<JoinExistingRoomPage> createState() => _JoinExistingRoomPageState();
}

class _JoinExistingRoomPageState extends State<JoinExistingRoomPage> {
  TextEditingController? _roomNameController;
  TextEditingController? _userNameController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          // render sizeを超えるのでcolumnの代わりに使っているだけ
          child: ListView(
        children: [
          _textForms(),
          Column(
            children: [
              SizedBox(
                  width: 120,
                  height: 120,
                  child: Image.asset(
                      'assets/images/animal_mark_hiyoko.png')), // TODO replace
              _buttons(context),
            ],
          )
        ],
      )),
    );
  }

  /// 部屋番号と名前
  Widget _textForms() {
    return Container(
      margin: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "部屋番号",
            style: TextStyle(fontSize: 18),
          ),
          Container(
            width: 350,
            margin: const EdgeInsets.only(bottom: 36),
            child: TextField(
              controller: _roomNameController,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.all(8),
                fillColor: Color.fromARGB(100, 200, 200, 200),
                filled: true,
                enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Color.fromARGB(100, 200, 200, 200)),
                    borderRadius: BorderRadius.all(Radius.circular(16))),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: Color.fromARGB(100, 200, 200, 200)),
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
            ),
          ),
          const Text(
            "名前",
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(
            width: 350,
            child: TextField(
              controller: _userNameController,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.all(8),
                fillColor: Color.fromARGB(100, 200, 200, 200),
                filled: true,
                enabledBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: Color.fromARGB(100, 200, 200, 200)),
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: Color.fromARGB(100, 200, 200, 200)),
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 参加ボタンと閉じるボタン
  Widget _buttons(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 90,
            margin: EdgeInsets.all(8),
            child: GestureDetector(
                child: Image.asset('assets/images/sanka@3x.png'),
                onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MeetingPage()),
                    )),
          ),
          Container(
            width: 90,
            margin: EdgeInsets.all(8),
            child: GestureDetector(
              child: Image.asset('assets/images/tojiru@3x.png'),
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
