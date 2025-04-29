// 📄 File: shared_trip_list_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/user.dart';
import '../../utils/firebase_user.dart';
import '../../utils/status_request.dart';

class SharedTripListPage extends StatelessWidget {
  const SharedTripListPage({super.key});

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
                .where('passenger.user_id', isEqualTo: userId)
                .where('status', isEqualTo: StatusRequisicao.trip)
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
                  return ListTile(
                    title: Text(trip['destination']['road']),
                    subtitle: Text("Started: ${trip['start_date'] ?? 'Unknown'}"),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/shared-trip-map',
                        arguments: docs[index]['id'],
                      );
                    },
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
