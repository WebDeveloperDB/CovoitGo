import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PassagerReservationScreen extends StatefulWidget {
  final Map<String, dynamic> trajet;

  const PassagerReservationScreen({super.key, required this.trajet});

  @override
  State<PassagerReservationScreen> createState() => _PassagerReservationScreenState();
}

class _PassagerReservationScreenState extends State<PassagerReservationScreen> {
  bool isSubmitting = false;

  void _confirmerReservation() async {
    setState(() {
      isSubmitting = true;
    });

    // Envoi de la demande de réservation
    // L'identifiant "passager_001" est un faux ID pour l'instant (le login n'étant pas actif)
    final success = await ApiService.envoyerDemande(
      widget.trajet['idTrajet'] ?? '66f1a8c9e4b0123456789abc',
      {
        'idPassager': 'passager_001',
        'placesDemandees': 1,
      },
      'dummy_token' // Remplacé plus tard par le vrai token
    );

    setState(() {
      isSubmitting = false;
    });

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Réservation confirmée avec succès !'), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Retour à la page d'accueil
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la réservation.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = const Color(0xFFF4F2EC);
    final headerColor = const Color(0xFF1E463D);
    final btnColor = const Color(0xFFE29E4A);

    // Récupération des données du trajet (avec valeurs par défaut si nulles)
    final departLabel = widget.trajet['depart']?['label'] ?? 'Mulhouse';
    final destinationLabel = widget.trajet['destination']?['label'] ?? 'Colmar';
    
    // Nettoyage et formatage simple de l'heure (ex: 2026-09-15T08:30:00Z -> 08:30)
    String heureDepartStr = widget.trajet['heureDepart'] ?? '08:10';
    if (heureDepartStr.contains('T')) {
      heureDepartStr = heureDepartStr.split('T')[1].substring(0, 5);
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
                        Text("Départ prévu : $heureDepartStr", style: const TextStyle(fontSize: 16)),
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
                    const Row(
                      children: [
                        Icon(Icons.event_seat, color: Colors.grey),
                        SizedBox(width: 8),
                        Text("Vous demandez : 1 place", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
