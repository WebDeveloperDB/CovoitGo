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

  factory Demande.fromMap(Map<String, dynamic> map) {
    return Demande(
      id: map['id'],
      idTrajet: map['idTrajet'],
      idPassager: map['idPassager'],
      placesDemandees: map['placesDemandees'],
      statut: map['statut'],
      motif: map['motif'],
      synced: map['synced'],
      lastModified: map['lastModified'],
    );
  }
}
