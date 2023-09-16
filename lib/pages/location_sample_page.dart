import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:timeago/timeago.dart' as timeago;

class LocationSamplePage extends StatefulWidget {
  const LocationSamplePage({Key? key}) : super(key: key);

  @override
  State<LocationSamplePage> createState() => _LocationSamplePageState();
}

class _LocationSamplePageState extends State<LocationSamplePage> {
  GoogleMapController? _controller;
  CameraPosition? _cameraPosition;
  final Location _location = Location();
  Set<Marker> _markers = {};
  StreamSubscription? _locationLoadSubscription;
  StreamSubscription? _storeLocationSubscription;
  late bool _loading;

  @override
  void initState() {
    print("init state called");
    _loading = true;
    _initCurrentLocation().whenComplete(() {
      print("init current location completed");
      _loadMarkers();
    });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    print("did change dependencies called");
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    print("dispose called");
    _locationLoadSubscription?.cancel();
    _storeLocationSubscription?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initCurrentLocation() async {
    print("init current location called");
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    // avoid redundant location change event
    await _location.changeSettings(distanceFilter: 20);
    print("attempt to get location");
    var locationData;
    try {
      locationData = await _location.getLocation();
    } catch (e) {
      print(e.toString());
    }
    print("get location completed");
    if (mounted) {
      setState(() {
      _cameraPosition = CameraPosition(
        target: LatLng(locationData.latitude!, locationData.longitude!),
        zoom: 14.4746,
      );
      _loading = false;
    });
    }
    /// store current location information when location changed
    _storeLocationSubscription = _location.onLocationChanged.listen((LocationData currentLocation) {
      if (FirebaseAuth.instance.currentUser == null) {
        _loginAnonymously();
        return;
      }
      FirebaseFirestore.instance
          .collection('locations')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .set({
        'latitude': currentLocation.latitude,
        'longitude': currentLocation.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> _loginAnonymously() async {
    FirebaseAuth.instance.signInAnonymously();
  }

  _loadMarkers() {
    _locationLoadSubscription = FirebaseFirestore.instance
        .collection('locations')
        .snapshots()
        .listen((snapshot) {
      Set<Marker> newMarkers = snapshot.docs
          .where((doc) => doc.id != FirebaseAuth.instance.currentUser?.uid)
          .map((doc) {
            print(doc.data().toString());
            final data = doc.data();
            final user = doc.id;
            double latitude = data['latitude'];
            double longitude = data['longitude'];
            DateTime dateTime = data['timestamp'].toDate();

            double color = dateTime
                    .isBefore(DateTime.now().subtract(const Duration(days: 1)))
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
          })
          .toSet();

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
