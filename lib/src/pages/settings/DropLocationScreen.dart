import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:SharedJourney/src/utils/firebase_user.dart';

class DropLocationScreen extends StatefulWidget {
  const DropLocationScreen({Key? key}) : super(key: key);

  @override
  _DropLocationScreenState createState() => _DropLocationScreenState();
}

class _DropLocationScreenState extends State<DropLocationScreen> {
  late GoogleMapController _mapController;
  // Initial coordinates can be set to the driver's current location or a default value.
  LatLng _selectedLocation = const LatLng(37.4219999, -122.0840575);
  Marker? _dropMarker;
  String? _driverId;

  @override
  void initState() {
    super.initState();
    _fetchDriverId();
  }

  Future<void> _fetchDriverId() async {
    // Retrieve the logged-in driver data.
    final driver = await FirebaseUser.getLoggedUserData();
    if (driver != null) {
      setState(() {
        _driverId = driver.id;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Driver not logged in")),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onMapTap(LatLng tappedPoint) {
    setState(() {
      _selectedLocation = tappedPoint;
      _dropMarker = Marker(
        markerId: const MarkerId("dropLocation"),
        position: tappedPoint,
        draggable: true,
        onDragEnd: (newPosition) {
          setState(() {
            _selectedLocation = newPosition;
          });
        },
      );
    });
  }

  Future<void> _saveDropLocation() async {
    if (_driverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Driver ID not available")),
      );
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(_driverId)
          .set({
        'drop_location': {
          'lat': _selectedLocation.latitude,
          'lng': _selectedLocation.longitude,
        }
      }, SetOptions(merge: true));
      print("Data saved");
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving drop location: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Set Drop Location"),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _selectedLocation,
              zoom: 15,
            ),
            markers: _dropMarker != null ? {_dropMarker!} : {},
            onTap: _onMapTap,
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: _saveDropLocation,
              child: const Text("Save Drop Location"),
            ),
          ),
        ],
      ),
    );
  }
}
