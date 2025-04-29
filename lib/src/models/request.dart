import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:SharedJourney/src/models/destiny.dart';
import 'package:SharedJourney/src/models/user.dart';

class Requisicao {
  String? id;
  String? status;
  Usuario? passenger;
  Usuario? driver;
  Destiny? destination;

  Requisicao({
    this.id,
    this.status,
    this.passenger,
    this.driver,
    this.destination,
  }) {
    FirebaseFirestore db = FirebaseFirestore.instance;

    DocumentReference ref = db.collection('requests').doc();
    id = ref.id;
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic>? datapassenger = passenger != null
        ? {
            "name": passenger!.name,
            "email": passenger!.email,
            "userType": passenger!.userType,
            "user_id": passenger!.id,
            "latitude": passenger!.latitude,
            "longitude": passenger!.longitude,
          }
        : null;

    Map<String, dynamic>? dadosdestination = destination != null
        ? {
            "road": destination!.road,
            "number": destination!.number,
            "neighborhood": destination!.neighborhood,
            "cep": destination!.cep,
            "latitude": destination!.latitude,
            "longitude": destination!.longitude,
          }
        : null;

    Map<String, dynamic> dadosRequisicao = {
      "id": id,
      "status": status,
      "passenger": datapassenger,
      "driver": null,
      "destination": dadosdestination,
    };

    return dadosRequisicao;
  }
}
