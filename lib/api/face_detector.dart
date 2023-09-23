import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:path_provider/path_provider.dart';

class FacesDetector {
  final FaceDetector _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
      )
  );

  String? testFaceInfo;
  Rect? faceRect;

  @override
  void dispose() {
    _faceDetector.close();
  }

  Future<File> getImageFileFromAssets(String path) async {
    final byteData = await rootBundle.load('assets/$path');

    final file = File('${(await getApplicationDocumentsDirectory()).path}/$path');
    await file.writeAsBytes(byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

    return file;
  }

  void GetFaceInfo(String imagePath) async {
    final File f = await getImageFileFromAssets(imagePath);
    final faces = await _faceDetector.processImage(InputImage.fromFile(f));
    String? faceInfo;
    int faceIndex = 0;
    for(Face oneFace in faces) {
      faceIndex++;
      //faceInfo = '顔の数：${faces.length}\n\n';
      faceInfo = '${faceIndex}顔の領域：${oneFace.boundingBox}\n\n';
      faceRect = oneFace.boundingBox;
      //faceInfo = '${faceIndex}左目の開き具合：${oneFace.leftEyeOpenProbability}\n\n';
      //faceInfo = '${faceIndex}右目の開き具合：${oneFace.rightEyeOpenProbability}\n\n';
    }

    if(faceInfo == null) {
      faceInfo = 'No data';
    }

    testFaceInfo = faceInfo;
  }
}
