import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../models/user.dart';
import '../utils/firebase_user.dart';
import '../utils/status_request.dart';

class SharedTripListPage extends StatelessWidget {
  const SharedTripListPage({super.key});

  Future<Position> _getCurrentLocation() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  void _joinTrip(BuildContext context, String requestId) async {
    try {
      Position position = await _getCurrentLocation();
      FirebaseFirestore db = FirebaseFirestore.instance;

      // Get logged in user data
      Usuario? currentUser = await FirebaseUser.getLoggedUserData();
      if (currentUser == null) {
        throw Exception("User not logged in.");
      }

      // Add the second_passenger field to the document
      await db.collection('requests').doc(requestId).update({
        'count': 2,
        'second_passenger': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'user_id': currentUser.id,
          'email': currentUser.email,

        },
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You joined the shared trip!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to join trip: $e")),
      );
    }
  }


  void _showJoinDialog(BuildContext context, String requestId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Join this trip?"),
        content: const Text("Would you like to join this shared journey?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _joinTrip(context, requestId);
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Shared Trips")),
      body: FutureBuilder<Usuario?>(
        future: FirebaseUser.getLoggedUserData(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          String? userId = userSnapshot.data?.id;

          return FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('requests')
                .where('status', isEqualTo: StatusRequisicao.THE_WAY)
                .get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No shared trips in progress."));
              }

              var docs = snapshot.data!.docs;

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  var trip = docs[index].data() as Map<String, dynamic>;
                  var requestId = docs[index].id;

                  return ListTile(
                    leading: const Icon(Icons.directions_car),
                    title: Text("To: ${trip['destination']['road'] ?? 'Unknown'}"),
                    subtitle: Text("Driver: ${trip['driver']?['name'] ?? 'N/A'}\nStarted: ${trip['start_date'] ?? 'Unknown'}"),
                    trailing: const Icon(Icons.add),
                    onTap: () => _showJoinDialog(context, requestId),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
