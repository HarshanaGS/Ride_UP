import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirestoreExample extends StatefulWidget {
  final String requestId;
  const FirestoreExample({Key? key, required this.requestId}) : super(key: key);

  @override
  State<FirestoreExample> createState() => _FirestoreExampleState();
}

class _FirestoreExampleState extends State<FirestoreExample> {
  double? driverLat;
  double? driverLng;
  double? destinationLat;
  double? destinationLng;

  @override
  void initState() {
    super.initState();
    _getRequestData(widget.requestId);
  }

  Future<void> _getRequestData(String requestId) async {
    try {
      // 1. Reference the `requests` collection
      DocumentReference docRef =
      FirebaseFirestore.instance.collection('requests').doc(requestId);

      // 2. Get the document snapshot
      DocumentSnapshot snapshot = await docRef.get();

      if (snapshot.exists) {
        // 3. Access the data
        Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;

        if (data != null) {
          // Access driver location
          if (data['driver'] != null) {
            driverLat = data['driver']['latitude'];
            driverLng = data['driver']['longitude'];
          }

          // Access destination location
          if (data['destination'] != null) {
            destinationLat = data['destination']['latitude'];
            destinationLng = data['destination']['longitude'];
          }

          // Update the UI
          setState(() {});
        }
      } else {
        debugPrint("Request with ID $requestId doesn't exist.");
      }
    } catch (e) {
      debugPrint("Error getting request data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver & Destination'),
      ),
      body: Center(
        child: driverLat == null || driverLng == null ||
            destinationLat == null || destinationLng == null
            ? const Text("Loading driver/destination data...")
            : Text(
          "Driver Location: ($driverLat, $driverLng)\n"
              "Destination: ($destinationLat, $destinationLng)",
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
