class Demande {
  final String id;
  final String idTrajet;
  final String idPassager;
  final int placesDemandees;
  final String statut;
  final String motif;
  final int synced;
  final String lastModified;

  Demande({
    required this.id,
    required this.idTrajet,
    required this.idPassager,
    required this.placesDemandees,
    required this.statut,
    required this.motif,
    this.synced = 1,
    required this.lastModified,
  });

  // Wandelt die Anfrage in eine Map für die lokale SQLite-Tabelle um
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'idTrajet': idTrajet,
      'idPassager': idPassager,
      'placesDemandees': placesDemandees,
      'statut': statut,
      'motif': motif,
      'synced': synced,
      'lastModified': lastModified,
    };
  }

  // Erstellt ein Demande-Objekt aus den Daten einer SQLite-Zeile
  factory Demande.fromMap(Map<String, dynamic> map) {
    return Demande(
      id: map['id'],
      idTrajet: map['idTrajet'],
      idPassager: map['idPassager'],
      placesDemandees: (map['placesDemandees'] as num).toInt(),
      statut: map['statut'],
      motif: map['motif'] ?? '',
      synced: (map['synced'] as num).toInt(),
      lastModified: map['lastModified'],
    );
  }

  // Erstellt ein Demande-Objekt aus der JSON-Antwort des Spring-Boot-Backends
  factory Demande.fromJson(Map<String, dynamic> json) {
    return Demande(
      id: json['id']?.toString() ?? '',
      idTrajet: json['idTrajet']?.toString() ?? '',
      idPassager: json['idPassager']?.toString() ?? '',
      placesDemandees: (json['placesDemandees'] as num?)?.toInt() ?? 1,
      statut: json['statut']?.toString() ?? 'PENDING',
      motif: json['motif']?.toString() ?? '',
      synced: 1, // Kommt vom Server, ist also bereits synchronisiert
      lastModified: json['creeLe']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
    );
  }

  // Bereitet das JSON für die Erstellung über die API (POST /api/trajets/{trajetId}/demandes) vor
  Map<String, dynamic> toApiJson() {
    return {
      'placesDemandees': placesDemandees,
      'motif': motif,
    };
  }

  // Erlaubt das Kopieren mit einzelnen geänderten Feldern
  Demande copyWith({
    String? id,
    String? idTrajet,
    String? idPassager,
    int? placesDemandees,
    String? statut,
    String? motif,
    int? synced,
    String? lastModified,
  }) {
    return Demande(
      id: id ?? this.id,
      idTrajet: idTrajet ?? this.idTrajet,
      idPassager: idPassager ?? this.idPassager,
      placesDemandees: placesDemandees ?? this.placesDemandees,
      statut: statut ?? this.statut,
      motif: motif ?? this.motif,
      synced: synced ?? this.synced,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}
