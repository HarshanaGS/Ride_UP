import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:SharedJourney/src/models/user.dart';

class FirebaseUser {
  static Future<User?> getCurrentUser() async {
    return FirebaseAuth.instance.currentUser;
  }

  static Future<Usuario?> getLoggedUserData() async {
    User? firebaseUser = await getCurrentUser();
    if (firebaseUser == null) return null;

    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentSnapshot<Map<String, dynamic>> userDoc =
        await db.collection('usuarios').doc(firebaseUser.uid).get();

    if (!userDoc.exists) return null;

    return Usuario.fromMap(userDoc.data()!, userDoc.id);
  }

  static Future<void> atualizarDadosLocalizacao(
      String RequestD, double lat, double lon, String tipo) async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    Usuario? usuario = await getLoggedUserData();

    if (usuario != null) {
      usuario.latitude = lat;
      usuario.longitude = lon;

      await db.collection('requests').doc(RequestD).update({
        tipo: usuario.toMap(),
      });
    }
  }
}
