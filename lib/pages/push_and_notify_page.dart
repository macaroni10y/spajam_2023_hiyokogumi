import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

class PushAndNotifyPage extends StatefulWidget {
  @override
  State<PushAndNotifyPage> createState() => _PushAndNotifyPageState();
}

class _PushAndNotifyPageState extends State<PushAndNotifyPage> {
  Stream<List<Notification>>? _stream;
  Timer? _timer;
  Future<void> _loginAnonymously() async {
    FirebaseAuth.instance.signInAnonymously();
  }

  @override
  void initState() {
    _loginAnonymously();
    _startListening();
    super.initState();
  }

  /// start listening to sleep notification from Firestore
  _startListening() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        _stream = FirebaseFirestore.instance
            .collection('sleep_notifications')
            .snapshots()
            .map((snapshot) => snapshot.docs
                .where((doc) =>
                    doc.data()['toId'] ==
                    FirebaseAuth.instance.currentUser?.uid)
                .where((element) =>
                    element.data()['timestamp'] >
                    Timestamp.fromDate(
                        DateTime.now().subtract(const Duration(seconds: 10))))
                .map(_convertToNotification)
                .toList());
      });
    });
  }

  Notification _convertToNotification(
          QueryDocumentSnapshot<Map<String, dynamic>> e) =>
      Notification(
        fromId: e.data()['fromId'],
        toId: e.data()['toId'],
        timestamp: e.data()['timestamp'],
        message: e.data()['message'],
      );

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        child: StreamBuilder(
      stream: _stream,
      builder:
          (BuildContext context, AsyncSnapshot<List<Notification>> snapshot) {
        return Column(
          children: [
            Center(
              child: CupertinoListTile(
                title: Text(snapshot.data?.first.message ?? 'no message'),
              ),
            ),
            Center(
              child: CupertinoListTile(
                title: const Text('sample: notify to myself'),
                onTap: () {
                  FirebaseFirestore.instance
                      .collection('sleep_notifications')
                      .add({
                    'fromId': FirebaseAuth.instance.currentUser?.uid,
                    'toId': FirebaseAuth.instance.currentUser?.uid,
                    'timestamp': FieldValue.serverTimestamp(),
                    'message':
                        '${FirebaseAuth.instance.currentUser?.uid} tapped you',
                  });
                },
              ),
            ),
          ],
        );
      },
    ));
  }
}

class Notification {
  final String fromId;
  final String toId;
  final Timestamp timestamp;
  final String message;
  Notification(
      {required this.fromId,
      required this.toId,
      required this.timestamp,
      required this.message});
}
