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

  @override
  void initState() {
    super.initState();
    _initCurrentLocation();
    _locationSubscription();
    _loadMarkers();
  }

  @override
  void dispose() {
    super.dispose();
    _controller?.dispose();
  }

  _initCurrentLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return null;
      }
    }

    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return null;
      }
    }

    // avoid redundant location change event
    _location.changeSettings(distanceFilter: 20);

    _location
        .getLocation()
        .then((locationData) => setState(() => _cameraPosition = CameraPosition(
              target: LatLng(locationData.latitude!, locationData.longitude!),
              zoom: 14,
            )));
  }

  Future<void> _loginAnonymously() async {
    FirebaseAuth.instance.signInAnonymously();
  }

  /// store current location information when location changed
  _locationSubscription() {
    _location.onLocationChanged.listen((LocationData currentLocation) {
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

  _loadMarkers() {
    FirebaseFirestore.instance
        .collection('locations')
        .snapshots()
        .listen((snapshot) {
      Set<Marker> newMarkers = snapshot.docs
          .map((doc) {
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
          .where((element) =>
              element.markerId.value != FirebaseAuth.instance.currentUser?.uid)
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
        body: _cameraPosition == null
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
