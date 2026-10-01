class Trajet {
  final String id;
  final String idConducteur;
  final double departLatitude;
  final double departLongitude;
  final double destinationLatitude;
  final double destinationLongitude;
  final String heureDepart;
  final int capacite;
  final int placesDisponibles;
  final String statut;
  final int synced; // 0 = pending, 1 = synced
  final String lastModified;

  Trajet({
    required this.id,
    required this.idConducteur,
    required this.departLatitude,
    required this.departLongitude,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.heureDepart,
    required this.capacite,
    required this.placesDisponibles,
    required this.statut,
    this.synced = 1,
    required this.lastModified,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'idConducteur': idConducteur,
      'depart_latitude': departLatitude,
      'depart_longitude': departLongitude,
      'destination_latitude': destinationLatitude,
      'destination_longitude': destinationLongitude,
      'heureDepart': heureDepart,
      'capacite': capacite,
      'placesDisponibles': placesDisponibles,
      'statut': statut,
      'synced': synced,
      'lastModified': lastModified,
    };
  }

  factory Trajet.fromMap(Map<String, dynamic> map) {
    return Trajet(
      id: map['id'],
      idConducteur: map['idConducteur'],
      departLatitude: map['depart_latitude'],
      departLongitude: map['depart_longitude'],
      destinationLatitude: map['destination_latitude'],
      destinationLongitude: map['destination_longitude'],
      heureDepart: map['heureDepart'],
      capacite: map['capacite'],
      placesDisponibles: map['placesDisponibles'],
      statut: map['statut'],
      synced: map['synced'],
      lastModified: map['lastModified'],
    );
  }
}
