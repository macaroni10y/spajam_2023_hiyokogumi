import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class LocationSamplePage extends StatefulWidget {
  const LocationSamplePage({Key? key}) : super(key: key);

  @override
  State<LocationSamplePage> createState() => _LocationSamplePageState();
}

class _LocationSamplePageState extends State<LocationSamplePage> {
  GoogleMapController? _controller;
  CameraPosition? _cameraPosition;
  Set<Marker> _markers = {};
  StreamSubscription? _locationLoadSubscription;
  StreamSubscription? _storeLocationSubscription;
  late bool _loading;

  @override
  void initState() {
    _loading = true;
    _initCurrentLocation().whenComplete(() {
      _loadMarkers();
    });
    super.initState();
  }

  @override
  void dispose() {
    _locationLoadSubscription?.cancel();
    _storeLocationSubscription?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  /// initialize current location and register subscription to location changes
  Future<void> _initCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return;
    }

    if (await Geolocator.checkPermission() == LocationPermission.denied &&
        await Geolocator.requestPermission() == LocationPermission.denied) {
      return;
    }

    Position locationData = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _cameraPosition = CameraPosition(
          target: LatLng(locationData.latitude, locationData.longitude),
          zoom: 14.4746,
        );
        _loading = false;
      });
    }

    /// store current location information when location changed
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
  _loadMarkers() {
    _locationLoadSubscription = FirebaseFirestore.instance
        .collection('locations')
        .snapshots()
        .listen((snapshot) {
      Set<Marker> newMarkers = snapshot.docs
          .where((doc) => doc.id != FirebaseAuth.instance.currentUser?.uid)
          .map((doc) {
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
      }).toSet();

      if (mounted) setState(() => _markers = newMarkers);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text("Google Maps Sample Page"),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : GoogleMap(
                onMapCreated: (controller) => _controller = controller,
                initialCameraPosition: _cameraPosition!,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                markers: _markers,
              ),
      );
}
