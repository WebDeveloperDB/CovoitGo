import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'conducteur_creation_trajet_screen.dart';
import '../database/database_helper.dart';
import '../services/sync_service.dart';


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
      // 1. ZUERST aus der lokalen SQLite-Datenbank laden (damit Daten sofort offline da sind!)
      final localTrajets = await DatabaseHelper.instance.getAllTrajets();
      if (mounted) {
        setState(() => _trajets = localTrajets);
      }
      
      // 2. Wenn online: Automatisch im Hintergrund synchronisieren
      try {
        await SyncService().synchroniserTout();
      } catch (e) {
        // Offline-Fall: Fehler ignorieren, wir nutzen einfach die lokalen Daten
        print('Offline-Modus aktiv: Synchronisation übersprungen');
      }

      // 3. Nach dem Sync: Frische Daten aus SQLite holen
      final trajetsApresSync = await DatabaseHelper.instance.getAllTrajets();
      
      // Duplikate bereinigen (nur eine Fahrt pro Abfahrt/Ziel/Uhrzeit behalten)
      final Map<String, dynamic> uniqueTrajets = {};
      for (var t in trajetsApresSync) {
        final key = "${t.departLatitude}_${t.destinationLatitude}_${t.heureDepart}";
        if (!uniqueTrajets.containsKey(key)) {
          uniqueTrajets[key] = t;
        } else {
          // Den doppelten Eintrag aus SQLite löschen
          await DatabaseHelper.instance.deleteTrajet(t.id);
        }
      }

      // Lokale Buchungsanfragen für diese Fahrten aus SQLite holen
      final allDemandes = await DatabaseHelper.instance.getAllDemandes();
      Map<String, List<dynamic>> demandesMap = {};
      for (var d in allDemandes) {
        demandesMap.putIfAbsent(d.idTrajet, () => []).add(d.toMap());
      }

      setState(() {
        _trajets = uniqueTrajets.values.map((t) => t.toMap()).toList();
        _demandesParTrajet = demandesMap;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur de chargement: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _gererDemande(String trajetId, String demandeId, String statut) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // 1. Wenn online: An die API senden
    try {
      await ApiService.gererDemande(trajetId, demandeId, statut, "", "");
    } catch (e) {
      print('Erreur API lors de gererDemande: $e');
    }

    // 2. In lokaler SQLite aktualisieren
    final demande = await DatabaseHelper.instance.getDemandeById(demandeId);
    if (statut == "ACCEPTE") {
      // Bei Annahme: Bleibt in der Liste als ACCEPTE erhalten
      if (demande != null) {
        await DatabaseHelper.instance.updateDemande(demande.copyWith(statut: 'ACCEPTE'));
      }
      // Freie Plätze der Fahrt reduzieren
      final trajet = await DatabaseHelper.instance.getTrajetById(trajetId);
      if (trajet != null && demande != null) {
        final newPlaces = (trajet.placesDisponibles - demande.placesDemandees).clamp(0, 8);
        await DatabaseHelper.instance.updateTrajet(trajet.copyWith(placesDisponibles: newPlaces));
      }
    } else {
      // Bei Ablehnung: Aus lokaler SQLite löschen
      await DatabaseHelper.instance.deleteDemande(demandeId);
    }

    if (!mounted) return;
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(statut == "ACCEPTE" ? 'Demande acceptée avec succès' : 'Demande refusée'),
        backgroundColor: statut == "ACCEPTE" ? Colors.green : Colors.grey,
      ),
    );
    
    _chargerDonnees();
  }

  // Ermöglicht es dem Fahrer, eine bereits angenommene Reservierung wieder zu entfernen
  Future<void> _supprimerDemandeAcceptee(String trajetId, String demandeId, int placesDemandees) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Annuler cette réservation"),
        content: const Text("Voulez-vous retirer ce passager de votre trajet ? Les places seront libérées."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Retirer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteDemande(demandeId);

      // Plätze wieder freigeben
      final trajet = await DatabaseHelper.instance.getTrajetById(trajetId);
      if (trajet != null) {
        await DatabaseHelper.instance.updateTrajet(
          trajet.copyWith(placesDisponibles: (trajet.placesDisponibles + placesDemandees).clamp(0, trajet.capacite)),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Réservation retirée et places libérées")),
      );
      _chargerDonnees();
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
    // Ermittlung der Städtenamen (auch wenn die Fahrt offline aus SQLite geladen wird)
    String depart = trajet['depart']?['label'] ?? '';
    if (depart.isEmpty && trajet['depart_latitude'] != null) {
      final lat = (trajet['depart_latitude'] as num).toDouble();
      if ((lat - 47.75).abs() < 0.1) depart = 'Mulhouse';
      else if ((lat - 48.07).abs() < 0.1) depart = 'Colmar';
      else if ((lat - 48.57).abs() < 0.1) depart = 'Strasbourg';
      else depart = 'Départ (${lat.toStringAsFixed(2)})';
    }
    if (depart.isEmpty) depart = 'Inconnu';

    String destination = trajet['destination']?['label'] ?? '';
    if (destination.isEmpty && trajet['destination_latitude'] != null) {
      final lat = (trajet['destination_latitude'] as num).toDouble();
      if ((lat - 47.75).abs() < 0.1) destination = 'Mulhouse';
      else if ((lat - 48.07).abs() < 0.1) destination = 'Colmar';
      else if ((lat - 48.57).abs() < 0.1) destination = 'Strasbourg';
      else destination = 'Arrivée (${lat.toStringAsFixed(2)})';
    }
    if (destination.isEmpty) destination = 'Inconnu';

    final date = _formatDate(trajet['heureDepart']);
    final places = trajet['placesDisponibles'] ?? 0;
    final id = trajet['id']?.toString() ?? '';
    final toutesDemandes = _demandesParTrajet[id] ?? [];
    final demandesEnAttente = toutesDemandes.where((d) => d['statut'] == 'PENDING' || d['statut'] == 'EN_ATTENTE').toList();
    final demandesAcceptees = toutesDemandes.where((d) => d['statut'] == 'ACCEPTE' || d['statut'] == 'ACCEPTED').toList();

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "$depart → $destination",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        // Confirm deletion
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Supprimer le trajet"),
                            content: const Text("Voulez-vous vraiment supprimer ce trajet ?"),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Supprimer", style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
                        
                        if (confirm == true) {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(child: CircularProgressIndicator()),
                          );

                          // 1. Zuerst aus der lokalen SQLite-Datenbank löschen
                          await DatabaseHelper.instance.deleteTrajet(id.toString());

                          // 2. Wenn online: Auch vom MongoDB-Server löschen
                          try {
                            await ApiService.supprimerTrajet(id.toString());
                          } catch (e) {
                            print('Suppression serveur ignorée ou hors-ligne: $e');
                          }

                          if (!mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Trajet supprimé avec succès")));
                          
                          // 3. Ansicht neu laden -> Karte verschwindet sofort!
                          _chargerDonnees();
                        }
                      },
                    ),
                  ],
                ),
                if (trajet['synced'] == 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_off, size: 14, color: Colors.orange),
                        SizedBox(width: 4),
                        Text(
                          "En attente de synchronisation (hors-ligne)",
                          style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
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
        
        // Ausstehende Anfragen (zum Annehmen oder Ablehnen)
        if (demandesEnAttente.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            "Demandes en attente",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ...demandesEnAttente.map((d) => _buildDemandeCard(d, trajet['id'])).toList(),
        ],

        // Angenommene Passagiere (bleiben sichtbar, bis der Fahrer sie löscht)
        if (demandesAcceptees.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            "Passagers confirmés",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E463D)),
          ),
          const SizedBox(height: 12),
          ...demandesAcceptees.map((d) => _buildDemandeAccepteeCard(d, trajet['id'])).toList(),
        ],

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildDemandeAccepteeCard(dynamic demande, String trajetId) {
    final placesDemandees = demande['placesDemandees'] ?? 1;
    final demandeId = demande['id'];
    final idPassager = demande['idPassager'] ?? 'Passager';

    return Card(
      color: Colors.green.shade50,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Colors.green, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 22),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Passager ($idPassager)",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$placesDemandees place(s) réservée(s)",
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: "Retirer ce passager",
              onPressed: () => _supprimerDemandeAcceptee(trajetId, demandeId, placesDemandees),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemandeCard(dynamic demande, String trajetId) {
    final placesDemandees = demande['placesDemandees'] ?? 1;
    final demandeId = demande['id']?.toString() ?? '';
    final passagerId = demande['idPassager']?.toString() ?? 'passager_001';
    final dateDemande = _formatDate(demande['lastModified'] ?? demande['creeLe']);

    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.orange.shade300, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kopfbereich des divs: Passagier-Info und Status-Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFF1E463D).withOpacity(0.1),
                      child: const Icon(Icons.person, color: Color(0xFF1E463D), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Passager : $passagerId",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange.shade400),
                  ),
                  child: Text(
                    "EN ATTENTE",
                    style: TextStyle(color: Colors.orange.shade800, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Details der Anfrage
            Row(
              children: [
                const Icon(Icons.event_seat, size: 16, color: Colors.black54),
                const SizedBox(width: 6),
                Text(
                  "Places souhaitées : $placesDemandees place(s)",
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.black45),
                const SizedBox(width: 6),
                Text(
                  "Demandé le : $dateDemande",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Eigene Buttons für genau DIESE Anfrage
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E463D),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text("Accepter"),
                    onPressed: () => _gererDemande(trajetId, demandeId, "ACCEPTE"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade400),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text("Refuser"),
                    onPressed: () => _gererDemande(trajetId, demandeId, "REFUSE"),
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
