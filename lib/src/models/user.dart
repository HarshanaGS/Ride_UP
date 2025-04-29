class Usuario {
  String? id;
  String? name;
  String? email;
  String? Password;
  String? userType;
  double? latitude;
  double? longitude;
  String? fotoUrl;
  double? assessment;

  Usuario({
    this.id,
    this.name,
    this.email,
    this.Password,
    this.userType,
    this.latitude,
    this.longitude,
    this.fotoUrl,
    this.assessment,
  });

  factory Usuario.fromMap(Map<String, dynamic> map, String id) {
    return Usuario(
      id: id,
      name: map["name"] as String? ?? '',
      email: map["email"] as String? ?? '',
      userType: map["userType"] as String? ?? '',
      fotoUrl: map["foto_url"] as String?,
      assessment: (map["assessment"] as num?)?.toDouble() ?? 0.0,
      latitude: (map["latitude"] as num?)?.toDouble(),
      longitude: (map["longitude"] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "user_id": id,
      "name": name,
      "email": email,
      "userType": userType,
      "latitude": latitude,
      "longitude": longitude,
      "foto_url": fotoUrl,
      "assessment": assessment,
    };
  }

  static String verificaruserType(bool userType) {
    return userType ? 'driver' : 'passenger';
  }
}
