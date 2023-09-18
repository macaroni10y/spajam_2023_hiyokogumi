import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class LocationWithStreamBuilderSamplePage extends StatefulWidget {
  const LocationWithStreamBuilderSamplePage({Key? key}) : super(key: key);

  @override
  State<LocationWithStreamBuilderSamplePage> createState() =>
      _LocationWithStreamBuilderSamplePageState();
}

class _LocationWithStreamBuilderSamplePageState
    extends State<LocationWithStreamBuilderSamplePage> {
  StreamSubscription? _storeLocationSubscription;

  @override
  void initState() {
    _fetchMakersStream();
    super.initState();
  }

  @override
  void dispose() {
    _storeLocationSubscription?.cancel();
    super.dispose();
  }

  /// attempt to get current location to initialize map
  Future<CameraPosition> _initCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return Future.value(const CameraPosition(target: LatLng(0, 0), zoom: 14));
    }

    if (await Geolocator.checkPermission() == LocationPermission.denied &&
        await Geolocator.requestPermission() == LocationPermission.denied) {
      return Future.value(const CameraPosition(target: LatLng(0, 0), zoom: 14));
    }

    return Geolocator.getCurrentPosition()
        .then((value) => CameraPosition(
            target: LatLng(value.latitude, value.longitude), zoom: 14))
        .onError((error, stackTrace) =>
            const CameraPosition(target: LatLng(0, 0), zoom: 14));
  }

  /// store current location information when location changed
  Future<void> subscribeToLocationChanges() async {
    _storeLocationSubscription = Geolocator.getPositionStream(
            locationSettings: const LocationSettings(distanceFilter: 20))
        .listen((Position? position) {
      if (FirebaseAuth.instance.currentUser == null) {
        _loginAnonymously();
        return;
      }
      FirebaseFirestore.instance
          .collection('locations')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .set({
        'latitude': position?.latitude,
        'longitude': position?.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> _loginAnonymously() async {
    FirebaseAuth.instance.signInAnonymously();
  }

  /// subscribe to location changes from Firestore
  Stream<Set<Marker>> _fetchMakersStream() => FirebaseFirestore.instance
      .collection('locations')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .where((doc) => doc.id != FirebaseAuth.instance.currentUser?.uid)
          .map(_convertToMarker)
          .toSet());

  Marker _convertToMarker(doc) {
    final data = doc.data();
    final user = doc.id;
    double latitude = data['latitude'];
    double longitude = data['longitude'];
    DateTime dateTime = data['timestamp'].toDate();

    double color =
        dateTime.isBefore(DateTime.now().subtract(const Duration(days: 1)))
            ? BitmapDescriptor.hueYellow
            : BitmapDescriptor.hueAzure;
    return Marker(
      markerId: MarkerId(user),
      position: LatLng(latitude, longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(color),
      infoWindow: InfoWindow(
        title: user,
        snippet: 'last login: ${timeago.format(dateTime)}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text("Google Maps Sample Page"),
        ),
        body: StreamBuilder(
          stream: _fetchMakersStream(),
          builder: (BuildContext context, AsyncSnapshot<Set<Marker>> markers) =>
              FutureBuilder<CameraPosition>(
            future: _initCurrentLocation(),
            builder: (BuildContext context,
                    AsyncSnapshot<CameraPosition> cameraPosition) =>
                cameraPosition.connectionState == ConnectionState.waiting
                    ? const Center(child: CircularProgressIndicator())
                    : GoogleMap(
                        initialCameraPosition: cameraPosition.data!,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        markers: markers.data!,
                      ),
          ),
        ),
      );
}
