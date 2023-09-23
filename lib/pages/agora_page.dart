import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

const appId = "e4d343934510484d8d31684f00c35464";
const token =
    "007eJxTYPinUba09qCPgu7PNFOb88v0v7seOyy+5FDLiU8v2J5abe5XYEg1STE2MbY0NjE1NDCxMEmxSDE2NLMwSTMwSDY2NTEzCfrPl9oQyMjAz/CElZEBAkF8LoaMzMr87Pz00txMBgYAU2ch8Q==";
const channel = "hiyokogumi";

class AgoraPage extends StatefulWidget {
  const AgoraPage({super.key});

  @override
  State<AgoraPage> createState() => _AgoraPageState();
}

class _AgoraPageState extends State<AgoraPage> {
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
            _remoteUidList.add(remoteUid);
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          debugPrint("remote user $remoteUid left channel");
          setState(() {
            _remoteUidList.remove(remoteUid);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agora Video Call'),
      ),
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
              })
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

  // Display remote user's videos
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