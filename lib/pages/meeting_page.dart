import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:spajam_2023_hiyokogumi/pages/goodbye_page.dart';

const appId = "e4d343934510484d8d31684f00c35464";
const token =
    "007eJxTYPinUba09qCPgu7PNFOb88v0v7seOyy+5FDLiU8v2J5abe5XYEg1STE2MbY0NjE1NDCxMEmxSDE2NLMwSTMwSDY2NTEzCfrPl9oQyMjAz/CElZEBAkF8LoaMzMr87Pz00txMBgYAU2ch8Q==";
const channel = "hiyokogumi";

class MeetingPage extends StatefulWidget {
  const MeetingPage({super.key});

  @override
  State<MeetingPage> createState() => _MeetingPageState();
}

class _MeetingPageState extends State<MeetingPage> {
  List<int> _remoteUidList = List.empty(growable: true);
  int? _remoteUid;
  bool _localUserJoined = false;
  late RtcEngine _engine;

  // for firestore
  Stream<QuerySnapshot<Map<String, dynamic>>>? _stream;
  Timer? _timer;
  Future<void> _loginAnonymously() async {
    FirebaseAuth.instance.signInAnonymously();
  }

  /// start listening to sleep notification from Firestore
  _startListening() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _stream = FirebaseFirestore.instance
            .collection('sleep_notifications')
            .snapshots();
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _loginAnonymously();
    _startListening();
    initAgora();
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    _engine.release();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> initAgora() async {
    // retrieve permissions
    await [Permission.microphone, Permission.camera].request();

    //create the engine
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("local user ${connection.localUid} joined");
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("remote user $remoteUid joined");
          setState(() {
            // 複数人用、1 on 1用でそれぞれ保持しておく
            _remoteUidList.add(remoteUid);
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          debugPrint("remote user $remoteUid left channel");
          setState(() {
            // 複数人用、1 on 1用でそれぞれ保持しておく
            _remoteUidList.remove(remoteUid);
            _remoteUid = null;
          });
        },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          debugPrint(
              '[onTokenPrivilegeWillExpire] connection: ${connection.toJson()}, token: $token');
        },
      ),
    );

    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine.enableVideo();
    await _engine.startPreview();

    await _engine.joinChannel(
      token: token,
      channelId: channel,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  // Create UI with local view and remote view
  @override
  Widget build(BuildContext context) {
    if (_remoteUid == null) {
      return SafeArea(
        child: Scaffold(
          body: Stack(children: [
            _waitDialog(),
            Align(alignment: Alignment.topRight,
            child: Container(
              margin: const EdgeInsets.all(12),
              width: 90,
              child: GestureDetector(
                onTap: () => _showCustomDialog(context),
                child: Image.asset('assets/images/taishitsu@3x.png'),
              ),
            ),)
          ]),
        ),
      );
    }
    // 1 on 1 のときだけレイアウトが変わる、はず・・・
    // 最終的に3人以上を実装しないかは要相談
    if (true) return _render1on1Videos();
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: _renderVideos(),
          ),
          StreamBuilder(
              stream: _stream,
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
                return ListTile(
                  title: _tapped(snapshot),
                );
              }),
          Align(
            alignment: Alignment.topRight,
            child: Container(
              margin: const EdgeInsets.all(12),
              width: 90,
              child: GestureDetector(
                onTap: () => _showCustomDialog(context),
                child: Image.asset('assets/images/taishitsu@3x.png'),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _localUserVideo() => _localUserJoined
      ? Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: AgoraVideoView(
            controller: VideoViewController(
              rtcEngine: _engine,
              canvas: const VideoCanvas(uid: 0),
            ),
          ),
        )
      : const CircularProgressIndicator();

  /// 全画面とAlignで1 on 1を前提とした画面を返す
  Widget _render1on1Videos() {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: AgoraVideoView(
                controller: VideoViewController.remote(
                  rtcEngine: _engine,
                  canvas: VideoCanvas(uid: _remoteUid),
                  connection: const RtcConnection(channelId: channel),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child:
                  SizedBox(width: 160, height: 240, child: _localUserVideo()),
            ),
            Align(
              alignment: Alignment.topRight,
              child: Container(
                margin: const EdgeInsets.all(12),
                width: 90,
                child: GestureDetector(
                  onTap: () => _showCustomDialog(context),
                  child: Image.asset('assets/images/taishitsu@3x.png'),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  /// gridで3人以上を出す
  Widget _renderVideos() {
    if (_remoteUidList.isNotEmpty) {
      print("length: ${_remoteUidList.length}");
      return GridView.builder(
          itemCount:
              _remoteUidList.length + 1, // gridviewの0番目にlocal userを表示するため
          itemBuilder: (BuildContext context, int index) {
            if (index == 0) {
              return _localUserVideo();
            }
            return GestureDetector(
              onTap: _sendNotification,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: AgoraVideoView(
                  controller: VideoViewController.remote(
                    rtcEngine: _engine,
                    canvas: VideoCanvas(uid: _remoteUidList[index - 1]),
                    connection: const RtcConnection(channelId: channel),
                  ),
                ),
              ),
            );
          },
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
          ));
    } else {
      return const Text(
        'Please wait for remote user to join',
        textAlign: TextAlign.center,
      );
    }
  }

  Widget _tapped(AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
    List<Notification>? list = snapshot.data?.docs
        .map(_convertToNotification)
        .where((e) => e.timestamp
            .toDate()
            .isAfter(DateTime.now().subtract(const Duration(seconds: 3))))
        .toList();
    return list == null || list.isEmpty
        ? const Text('no notification')
        : Column(
            children: list
                .map((e) => Text(
                      e.message,
                      style: const TextStyle(fontSize: 10),
                    ))
                .toList(),
          );
  }

  Widget _waitDialog() {
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("他の人がくるまでちょっと待ってね...", style: TextStyle(fontSize: 16),),
        SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator()),
      ],
    ));
  }

  Notification _convertToNotification(
          QueryDocumentSnapshot<Map<String, dynamic>> e) =>
      Notification(
        fromId: e.data()['fromId'],
        toId: e.data()['toId'],
        timestamp: e.data()['timestamp'] ??
            Timestamp.fromDate(
                DateTime.now().subtract(const Duration(seconds: 10))),
        message: e.data()['message'],
      );

  // TODO 今は自分自身に通知することになってます 本来は相手のIDを通知する
  void _sendNotification() {
    FirebaseFirestore.instance.collection('sleep_notifications').add({
      'fromId': FirebaseAuth.instance.currentUser?.uid,
      'toId': FirebaseAuth.instance.currentUser?.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'message': '${FirebaseAuth.instance.currentUser?.uid} tapped you',
    });
  }

  void _showCustomDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            height: 170,
            width: 250,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Column(
              children: [
                Flexible(
                  flex: 2,
                  child: Container(
                    margin: EdgeInsets.all(20),
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      '退室しますか？',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                Flexible(
                  flex: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        margin: EdgeInsets.all(8),
                        width: 80,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (BuildContext context) =>
                                      const GoodbyePage()),
                              (Route<dynamic> route) => false,
                            );
                          },
                          child: Image.asset('assets/images/hai@3x.png'),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.all(8),
                        width: 80,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Image.asset('assets/images/iie@3x.png'),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
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
