import 'dart:async';

import 'package:Zizz/pages/goodbye_page.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';

const appId = "e4d343934510484d8d31684f00c35464";
const token =
    "007eJxTYPinUba09qCPgu7PNFOb88v0v7seOyy+5FDLiU8v2J5abe5XYEg1STE2MbY0NjE1NDCxMEmxSDE2NLMwSTMwSDY2NTEzCfrPl9oQyMjAz/CElZEBAkF8LoaMzMr87Pz00txMBgYAU2ch8Q==";
const channel = "hiyokogumi";

class MeetingPage extends StatefulWidget {
  final CameraDescription cameraDescription;
  const MeetingPage({super.key, required this.cameraDescription});

  @override
  State<MeetingPage> createState() => _MeetingPageState();
}

class _MeetingPageState extends State<MeetingPage> {
  final audioPlayer = AudioPlayer();
  List<int> _remoteUidList = List.empty(growable: true);
  int? _remoteUid;
  bool _localUserJoined = false;
  bool _enableSound = false;
  String _sleeping = 'awake'; // awake or sleeping or waken
  late RtcEngine _engine;
  Timer? _timer;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _notificationStreamSubscription;
  Future<void> _loginAnonymously() async {
    FirebaseAuth.instance.signInAnonymously();
  }

  // for camera
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  final FaceDetector _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
    enableClassification: true,
  ));

  String? faceInfo;

  /// start listening to sleep notification from Firestore
  _startListening() {
    _notificationStreamSubscription = FirebaseFirestore.instance
        .collection('sleep_notifications')
        .snapshots()
        .listen((event) {
      if (_enableSound) {
        audioPlayer.play(AssetSource('audio/short_bomb.mp3'));
        Vibration.vibrate();
      }
    });
  }

  _sleepPeriodically() {
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      setState(() {
        _sleeping = 'sleeping';
      });
    });
  }

  _disableSoundOnInitialize() {
    Future.delayed(const Duration(seconds: 5), () {
      setState(() {
        _enableSound = true;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _loginAnonymously();
    _startListening();
    _sleepPeriodically();
    _disableSoundOnInitialize();
    initAgora();
    _controller =
        CameraController(widget.cameraDescription, ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    _engine.release();
    _timer?.cancel();
    _controller.dispose();
    _faceDetector.close();
    _startCameraStreaming();
    _notificationStreamSubscription?.cancel();
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
          ]),
        ),
      );
    }
    return _render1on1Videos();
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
            ),
            Align(
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _sleeping = 'waken';
                  });
                  Future.delayed(const Duration(seconds: 2), () {
                    setState(() {
                      _sleeping = 'awake';
                    });
                  });
                  _sendNotification();
                },
                child: Opacity(
                  opacity: _sleeping == 'awake' ? 0.0 : 1.0,
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: _sleeping == 'waken'
                        ? Image.asset('assets/images/awa2.gif')
                        : Image.asset('assets/images/awa1.gif'),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                margin: const EdgeInsets.all(8),
                width: 120,
                height: 24,
                decoration:
                    BoxDecoration(color: Color.fromARGB(180, 40, 40, 40)),
                child: Center(
                    child: Text(
                  "name",
                  style: TextStyle(color: Colors.white),
                )),
              ),
            ),
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
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "他の人がくるまでちょっと待ってね...",
          style: TextStyle(fontSize: 16),
        ),
        SizedBox(width: 50, height: 50, child: CircularProgressIndicator()),
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
                                      GoodbyePage(
                                        cameraDescription:
                                            widget.cameraDescription,
                                      )),
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

  void _startCameraStreaming() {
    _controller.startImageStream(_processImage);
  }

  Future<void> _processImage(CameraImage cameraImage) async {
    if (mounted) {
      // CameraImageからInputImageを作成する
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in cameraImage.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize =
          Size(cameraImage.width.toDouble(), cameraImage.height.toDouble());

      final InputImageFormat inputImageFormat =
          InputImageFormatValue.fromRawValue(cameraImage.format.raw) ??
              InputImageFormat.nv21;

      final inputImageData = InputImageMetadata(
          size: imageSize,
          rotation: InputImageRotation.rotation0deg,
          format: inputImageFormat,
          bytesPerRow: 1);

      final inputImage =
          InputImage.fromBytes(bytes: bytes, metadata: inputImageData);

      final faces = await _faceDetector.processImage(inputImage);
      int faceIndex = 0;
      for (Face oneFace in faces) {
        faceIndex++;
        faceInfo = '${faceIndex}左目の開き具合：${oneFace.leftEyeOpenProbability}\n\n';
      }
    }
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
