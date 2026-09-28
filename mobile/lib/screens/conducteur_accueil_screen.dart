import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'conducteur_creation_trajet_screen.dart';

class ConducteurAccueilScreen extends StatefulWidget {
  const ConducteurAccueilScreen({super.key});

  @override
  State<ConducteurAccueilScreen> createState() => _ConducteurAccueilScreenState();
}

class _ConducteurAccueilScreenState extends State<ConducteurAccueilScreen> {
  // Dummy-Variable für den Namen des eingeloggten Fahrers.
  final String userName = "Conducteur";

  List<dynamic> _trajets = [];
  Map<String, List<dynamic>> _demandesParTrajet = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    setState(() => _isLoading = true);

    try {
      final trajets = await ApiService.getMesTrajetsActifs();
      Map<String, List<dynamic>> demandes = {};
      
      // Fetch requests for each active trip
      for (var trajet in trajets) {
        if (trajet['id'] != null) {
          final reqs = await ApiService.getDemandesPourTrajet(trajet['id']);
          demandes[trajet['id']] = reqs;
        }
      }

      setState(() {
        _trajets = trajets;
        _demandesParTrajet = demandes;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur de chargement: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _gererDemande(String trajetId, String demandeId, String statut) async {
    // Show a loading indicator dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // "" as token since auth isn't implemented
    final success = await ApiService.gererDemande(trajetId, demandeId, statut, "", "");
    
    // Close the loading dialog
    Navigator.of(context).pop();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Demande $statut avec succès')),
      );
      // Reload data to refresh UI (update seats available and remove request)
      _chargerDonnees();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors du traitement')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Farben exakt aus dem Maquette kopiert
    final Color bgColor = const Color(0xFFF4F2EC); // Heller Beige-Hintergrund
    final Color headerColor = const Color(0xFF1E463D); // Dunkelgrüner Header
    final Color btnColor = const Color(0xFFE29E4A); // Orangener Button

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ==========================================
                    // 1. DER DUNKELGRÜNE HEADER-BEREICH OBEN
                    // ==========================================
                    Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: headerColor,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bonjour, $userName',
                            style: const TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Mon activité',
                            style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                    // ==========================================
                    // 2. HAUPT-INHALT
                    // ==========================================
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Button "Proposer un trajet" in Orange ---
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: btnColor,
                                foregroundColor: Colors.black87, // Dunkler Text für Lesbarkeit
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ConducteurCreationTrajetScreen(),
                                  ),
                                );
                                
                                // Wenn Fahrt erstellt wurde, lade Liste neu
                                if (result == true) {
                                  _chargerDonnees();
                                }
                              },
                              child: const Text('Proposer un trajet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),

                          const SizedBox(height: 32),

                          if (_trajets.isEmpty)
                            const Center(
                              child: Text(
                                "Vous n'avez aucun trajet actif.",
                                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                              ),
                            )
                          else
                            ..._trajets.map((trajet) => _buildTrajetCard(trajet)).toList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTrajetCard(dynamic trajet) {
    final depart = trajet['depart']?['label'] ?? 'Inconnu';
    final destination = trajet['destination']?['label'] ?? 'Inconnu';
    final date = _formatDate(trajet['heureDepart']);
    final places = trajet['placesDisponibles'] ?? 0;
    final id = trajet['id'];
    final demandes = _demandesParTrajet[id] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Mon trajet actif",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        // Kasten für die aktuelle Fahrt
        Card(
          color: Colors.green.shade50,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Colors.green, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("$depart → $destination", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 18, color: Colors.black54),
                    const SizedBox(width: 4),
                    Text(date, style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.event_seat, size: 18, color: Colors.black54),
                    const SizedBox(width: 4),
                    Text("Places disponibles : $places", style: TextStyle(color: Colors.grey.shade800, fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        if (demandes.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            "Demande en attente",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ...demandes.map((d) => _buildDemandeCard(d, trajet['id'])).toList(),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildDemandeCard(dynamic demande, String trajetId) {
    final placesDemandees = demande['placesDemandees'] ?? 1;
    final demandeId = demande['id'];

    return Card(
      color: Colors.white,
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person_add, color: Color(0xFF1E463D)),
                SizedBox(width: 8),
                Text("Demande de Passager", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            Text("$placesDemandees place(s) demandée(s)", style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
            const SizedBox(height: 16),
            // Zwei Buttons nebeneinander (Accepter / Refuser)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E463D),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _gererDemande(trajetId, demandeId, "ACCEPTE"),
                    child: const Text("Accepter"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade700),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _gererDemande(trajetId, demandeId, "REFUSE"),
                    child: const Text("Refuser"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return "Date inconnue";
    try {
      final date = DateTime.parse(isoString).toLocal();
      // Simple format: DD/MM/YYYY HH:MM
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return "Date invalide";
    }
  }
}
