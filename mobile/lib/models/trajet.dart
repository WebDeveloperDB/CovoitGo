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

  // Wandelt das Objekt in eine Map für die lokale SQLite-Datenbank um
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

  // Erstellt ein Trajet-Objekt aus den Daten einer SQLite-Zeile
  factory Trajet.fromMap(Map<String, dynamic> map) {
    return Trajet(
      id: map['id'],
      idConducteur: map['idConducteur'],
      departLatitude: (map['depart_latitude'] as num).toDouble(),
      departLongitude: (map['depart_longitude'] as num).toDouble(),
      destinationLatitude: (map['destination_latitude'] as num).toDouble(),
      destinationLongitude: (map['destination_longitude'] as num).toDouble(),
      heureDepart: map['heureDepart'],
      capacite: (map['capacite'] as num).toInt(),
      placesDisponibles: (map['placesDisponibles'] as num).toInt(),
      statut: map['statut'],
      synced: (map['synced'] as num).toInt(),
      lastModified: map['lastModified'],
    );
  }

  // Erstellt ein Trajet-Objekt aus der JSON-Antwort des Spring-Boot-Backends (MongoDB)
  factory Trajet.fromJson(Map<String, dynamic> json) {
    double depLat = 0.0;
    double depLon = 0.0;
    if (json['depart'] is Map) {
      depLat = (json['depart']['latitude'] as num?)?.toDouble() ?? 0.0;
      depLon = (json['depart']['longitude'] as num?)?.toDouble() ?? 0.0;
    } else {
      depLat = (json['depart_latitude'] as num?)?.toDouble() ?? 0.0;
      depLon = (json['depart_longitude'] as num?)?.toDouble() ?? 0.0;
    }

    double destLat = 0.0;
    double destLon = 0.0;
    if (json['destination'] is Map) {
      destLat = (json['destination']['latitude'] as num?)?.toDouble() ?? 0.0;
      destLon = (json['destination']['longitude'] as num?)?.toDouble() ?? 0.0;
    } else {
      destLat = (json['destination_latitude'] as num?)?.toDouble() ?? 0.0;
      destLon = (json['destination_longitude'] as num?)?.toDouble() ?? 0.0;
    }

    return Trajet(
      id: json['id']?.toString() ?? '',
      idConducteur: json['idConducteur']?.toString() ?? '',
      departLatitude: depLat,
      departLongitude: depLon,
      destinationLatitude: destLat,
      destinationLongitude: destLon,
      heureDepart: json['heureDepart']?.toString() ?? '',
      capacite: (json['capacite'] as num?)?.toInt() ?? 0,
      placesDisponibles: (json['placesDisponibles'] as num?)?.toInt() ?? 0,
      statut: json['statut']?.toString() ?? 'ACTIVE',
      synced: 1, // Kommt vom Server, ist also bereits synchronisiert
      lastModified: json['misAJourLe']?.toString() ??
          json['creeLe']?.toString() ??
          DateTime.now().toUtc().toIso8601String(),
    );
  }

  // Bereitet das JSON für die Erstellung über die API (POST /api/trajets) vor
  Map<String, dynamic> toApiJson() {
    return {
      'depart': {
        'latitude': departLatitude,
        'longitude': departLongitude,
        'nomLieu': 'Départ',
      },
      'destination': {
        'latitude': destinationLatitude,
        'longitude': destinationLongitude,
        'nomLieu': 'Destination',
      },
      'heureDepart': heureDepart,
      'capacite': capacite,
    };
  }

  // Erlaubt das Kopieren mit einzelnen geänderten Feldern (z. B. um synced auf 1 zu setzen)
  Trajet copyWith({
    String? id,
    String? idConducteur,
    double? departLatitude,
    double? departLongitude,
    double? destinationLatitude,
    double? destinationLongitude,
    String? heureDepart,
    int? capacite,
    int? placesDisponibles,
    String? statut,
    int? synced,
    String? lastModified,
  }) {
    return Trajet(
      id: id ?? this.id,
      idConducteur: idConducteur ?? this.idConducteur,
      departLatitude: departLatitude ?? this.departLatitude,
      departLongitude: departLongitude ?? this.departLongitude,
      destinationLatitude: destinationLatitude ?? this.destinationLatitude,
      destinationLongitude: destinationLongitude ?? this.destinationLongitude,
      heureDepart: heureDepart ?? this.heureDepart,
      capacite: capacite ?? this.capacite,
      placesDisponibles: placesDisponibles ?? this.placesDisponibles,
      statut: statut ?? this.statut,
      synced: synced ?? this.synced,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}
