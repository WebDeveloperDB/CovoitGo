import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../database/database_helper.dart';
import '../models/demande.dart';


class PassagerReservationScreen extends StatefulWidget {
  final Map<String, dynamic> trajet;
  final int placesDemandees;

  const PassagerReservationScreen({
    super.key,
    required this.trajet,
    this.placesDemandees = 1,
  });

  @override
  State<PassagerReservationScreen> createState() => _PassagerReservationScreenState();
}

class _PassagerReservationScreenState extends State<PassagerReservationScreen> {
  bool isSubmitting = false;

  void _confirmerReservation() async {
    setState(() {
      isSubmitting = true;
    });

    final trajetId = widget.trajet['idTrajet']?.toString() ?? 
                     widget.trajet['id']?.toString() ?? 
                     '66f1a8c9e4b0123456789abc';

    // 0. Prüfen, ob lokal bereits eine Reservierung für diese Fahrt existiert
    final existantes = await DatabaseHelper.instance.getAllDemandes();
    final dejaReserve = existantes.any((d) => 
      d.idTrajet == trajetId && 
      (d.statut == 'PENDING' || d.statut == 'ACCEPTE' || d.statut == 'EN_ATTENTE' || d.statut == 'ACCEPTED')
    );

    if (dejaReserve) {
      setState(() => isSubmitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vous avez déjà une demande en cours ou validée pour ce trajet !"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }


    // Ermittlung der Städtenamen für Speicherung und Anzeige
    String depNom = widget.trajet['depart']?['label'] ?? '';
    if (depNom.isEmpty || depNom == 'Départ' || depNom == 'Inconnu') {
      final lat = widget.trajet['depart']?['latitude'] ?? widget.trajet['depart_latitude'];
      final lon = widget.trajet['depart']?['longitude'] ?? widget.trajet['depart_longitude'];
      if (lat != null && lon != null) {
        depNom = ApiService.getCityName((lat as num).toDouble(), (lon as num).toDouble());
      }
    }
    if (depNom.isEmpty) depNom = 'Départ';

    String destNom = widget.trajet['destination']?['label'] ?? '';
    if (destNom.isEmpty || destNom == 'Destination' || destNom == 'Inconnu') {
      final lat = widget.trajet['destination']?['latitude'] ?? widget.trajet['destination_latitude'];
      final lon = widget.trajet['destination']?['longitude'] ?? widget.trajet['destination_longitude'];
      if (lat != null && lon != null) {
        destNom = ApiService.getCityName((lat as num).toDouble(), (lon as num).toDouble());
      }
    }
    if (destNom.isEmpty) destNom = 'Destination';

    final routeInfo = "$depNom → $destNom";

    // 2. Lokales Demande-Objekt für SQLite erstellen
    final nouvelleDemande = Demande(
      id: "temp_${DateTime.now().millisecondsSinceEpoch}",
      idTrajet: trajetId,
      idPassager: 'passager_001',
      placesDemandees: widget.placesDemandees,
      statut: 'PENDING',
      motif: routeInfo, // Speichert den Namen der Fahrt für die Liste "Mes réservations"
      synced: isOnlineSuccess ? 1 : 0, // 1 = online übertragen, 0 = offline ausstehend
      lastModified: DateTime.now().toUtc().toIso8601String(),
    );

    // 3. In lokaler SQLite-Datenbank speichern (damit der Passagier seine Reservierungen sieht)
    await DatabaseHelper.instance.insertDemande(nouvelleDemande);
    print('SQLite: Réservation enregistrée localement (synced: ${nouvelleDemande.synced})');

    setState(() {
      isSubmitting = false;
    });

    if (!mounted) return;

    // 4. Passende Rückmeldung an den Nutzer (Klarstellung: wartet auf Fahrer-Bestätigung)
    if (isOnlineSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Demande envoyée avec succès ! En attente de confirmation par le conducteur."),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Mode hors-ligne : demande enregistrée. En attente de confirmation par le conducteur dès reconnexion."),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
    }

    Navigator.pop(context, true);
  }


  @override
  Widget build(BuildContext context) {
    final bgColor = const Color(0xFFF4F2EC);
    final headerColor = const Color(0xFF1E463D);
    final btnColor = const Color(0xFFE29E4A);

    // Récupération dynamique des noms de villes avec résolution de coordonnées
    String departLabel = widget.trajet['depart']?['label'] ?? '';
    if (departLabel.isEmpty || departLabel == 'Départ' || departLabel == 'Inconnu') {
      final lat = widget.trajet['depart']?['latitude'] ?? widget.trajet['depart_latitude'];
      final lon = widget.trajet['depart']?['longitude'] ?? widget.trajet['depart_longitude'];
      if (lat != null && lon != null) {
        departLabel = ApiService.getCityName((lat as num).toDouble(), (lon as num).toDouble());
      }
    }
    if (departLabel.isEmpty) departLabel = 'Départ';

    String destinationLabel = widget.trajet['destination']?['label'] ?? '';
    if (destinationLabel.isEmpty || destinationLabel == 'Destination' || destinationLabel == 'Inconnu') {
      final lat = widget.trajet['destination']?['latitude'] ?? widget.trajet['destination_latitude'];
      final lon = widget.trajet['destination']?['longitude'] ?? widget.trajet['destination_longitude'];
      if (lat != null && lon != null) {
        destinationLabel = ApiService.getCityName((lat as num).toDouble(), (lon as num).toDouble());
      }
    }
    if (destinationLabel.isEmpty) destinationLabel = 'Destination';
    
    // Formatage complet Date et Heure (ex: 15/10/2026 à 11:00)
    String dateHeureStr = widget.trajet['heureDepart'] ?? '08:10';
    if (dateHeureStr.contains('T')) {
      try {
        final dt = DateTime.parse(dateHeureStr).toLocal();
        dateHeureStr = "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} à ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
      } catch (e) {
        // En cas d'erreur
      }
    }
    
    final score = widget.trajet['score'] ?? '92';
    final places = widget.trajet['placesDisponibles'] ?? 4;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: headerColor,
        title: const Text('Détails du trajet', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$departLabel → $destinationLabel",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E463D)),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text("Départ prévu : $dateHeureStr", style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text("Score de compatibilité : $score%", style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.directions_car, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text("Places disponibles : $places", style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.event_seat, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          "Vous demandez : ${widget.placesDemandees} place${widget.placesDemandees > 1 ? 's' : ''}",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: btnColor,
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: isSubmitting ? null : _confirmerReservation,
                child: isSubmitting 
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text('Confirmer la réservation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
