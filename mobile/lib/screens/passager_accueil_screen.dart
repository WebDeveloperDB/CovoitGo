import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'passager_reservation_screen.dart';
import '../database/database_helper.dart';
import '../models/demande.dart';

class PassagerAccueilScreen extends StatefulWidget {
  const PassagerAccueilScreen({super.key});

  @override
  State<PassagerAccueilScreen> createState() => _PassagerAccueilScreenState();
}

class _PassagerAccueilScreenState extends State<PassagerAccueilScreen> {
  // Dummy-Variable für den Namen des eingeloggten Benutzers.
  final String userName = "Passager";
  
  // Zeigt an, ob wir bereits eine Suche durchgeführt haben.
  bool hasSearched = false; 
  String noResultReason = "";

  // Hier speichern wir die Ergebnisse aus dem Backend!
  List<dynamic> resultatsApi = []; 
  List<Demande> _mesReservations = [];

  // Variablen zum Speichern des gewählten Datums und der Uhrzeit
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _departController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _placesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _chargerReservations();
  }

  Future<void> _chargerReservations() async {
    final demandes = await DatabaseHelper.instance.getAllDemandes();
    setState(() {
      _mesReservations = demandes;
    });
  }

  Future<void> _annulerReservation(String demandeId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Annuler la réservation"),
        content: const Text("Voulez-vous vraiment annuler cette réservation ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Non")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Oui, annuler", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteDemande(demandeId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Réservation annulée avec succès")),
      );
      _chargerReservations();
    }
  }

  String _resolveCity(dynamic lieu, String fallback) {
    if (lieu is Map) {
      final label = lieu['label']?.toString();
      if (label != null && label.isNotEmpty && label != 'Départ' && label != 'Destination' && label != 'Inconnu') {
        return label;
      }
      final lat = (lieu['latitude'] as num?)?.toDouble();
      final lon = (lieu['longitude'] as num?)?.toDouble();
      if (lat != null && lon != null) {
        final resolved = ApiService.getCityName(lat, lon);
        if (resolved.isNotEmpty) return resolved;
      }
    }
    return fallback;
  }

  String _formatDateHeure(dynamic heureDepart) {
    if (heureDepart == null) return "Non précisé";
    final str = heureDepart.toString();
    if (str.contains('T')) {
      try {
        final dt = DateTime.parse(str).toLocal();
        final jour = dt.day.toString().padLeft(2, '0');
        final mois = dt.month.toString().padLeft(2, '0');
        final annee = dt.year;
        final heure = dt.hour.toString().padLeft(2, '0');
        final minute = dt.minute.toString().padLeft(2, '0');
        return "$jour/$mois/$annee à $heure:$minute";
      } catch (e) {
        return str;
      }
    }
    return str;
  }

  // Methode, um den Kalender zu öffnen (Date Picker)
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(), // Heute vorausgewählt
      firstDate: DateTime.now(),   // Man kann nicht in der Vergangenheit buchen
      lastDate: DateTime(2030),    // Max. Jahr 2030
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        // Datum formatieren als DD/MM/YYYY
        _dateController.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  // Methode, um die Uhr-Auswahl zu öffnen (Time Picker)
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
        // Uhrzeit formatieren als HH:MM
        _timeController.text = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  // Funktion zum Anzeigen des Pop-ups (Bottom Sheet) mit restlichen Fahrten
  void _afficherTousLesResultats(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Toutes les propositions",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: resultatsApi.isEmpty 
                    ? const Center(child: Text("Aucun trajet trouvé"))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: resultatsApi.length,
                        itemBuilder: (context, index) {
                          final trajet = resultatsApi[index];
                          final depLabel = _resolveCity(trajet['depart'], _departController.text.isNotEmpty ? _departController.text : 'Départ');
                          final destLabel = _resolveCity(trajet['destination'], _destinationController.text.isNotEmpty ? _destinationController.text : 'Destination');
                          final score = trajet['score'] ?? 'N/A';
                          final dateHeure = _formatDateHeure(trajet['heureDepart']);
                          final places = trajet['placesDisponibles'] ?? '?';
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              onTap: () async {
                                final res = await Navigator.push(context, MaterialPageRoute(
                                  builder: (context) => PassagerReservationScreen(
                                    trajet: trajet,
                                    placesDemandees: int.tryParse(_placesController.text) ?? 1,
                                  ),
                                ));
                                if (res == true) {
                                  _chargerReservations();
                                }
                              },
                              title: Text("$depLabel → $destLabel", style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text("$dateHeure • $places place(s) • Score: $score%"),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            ),
                          );
                        },
                      ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Hilfsmethode, um normale Textfelder (Départ, Destination, Places) zu bauen
  Widget _buildTextField(String label, String hint, {TextInputType keyboardType = TextInputType.text, TextEditingController? controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType, 
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade600),
            filled: true,
            fillColor: Colors.transparent, 
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1E463D)), 
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Unsere definierten Farben aus der Maquette
    final Color bgColor = const Color(0xFFF4F2EC); 
    final Color headerColor = const Color(0xFF1E463D); 
    final Color btnColor = const Color(0xFFE29E4A); 

    return Scaffold(
      backgroundColor: bgColor, 
      body: SafeArea(
        child: SingleChildScrollView( // Erlaubt scrollen, falls das Display klein ist
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bonjour, $userName',
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
                          tooltip: 'Se déconnecter',
                          onPressed: () {
                            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Trouver un trajet',
                      style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              // ==========================================
              // 2. DAS SUCH-FORMULAR
              // ==========================================
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Liste der eigenen Reservierungen (falls vorhanden)
                    if (_mesReservations.isNotEmpty) ...[
                      _buildMesReservations(),
                      const SizedBox(height: 24),
                      const Divider(thickness: 1),
                      const SizedBox(height: 16),
                    ],

                    // Startort
                    _buildTextField("Départ", "Ex: Mulhouse", controller: _departController),
                    const SizedBox(height: 16),
                    
                    // Zielort
                    _buildTextField("Destination", "Ex: Colmar", controller: _destinationController),
                    const SizedBox(height: 16),
                    
                    // Datum und Uhrzeit nebeneinander
                    const Text("Date et heure", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // ----- DATUM-FELD -----
                        Expanded(
                          child: TextField(
                            controller: _dateController, // Verbindet das Feld mit unserem Code
                            readOnly: true, // WICHTIG: Erlaubt keine manuelle Tastatureingabe
                            onTap: () => _selectDate(context), // Öffnet den Kalender beim Klicken!
                            decoration: InputDecoration(
                              hintText: "04/09/2026",
                              hintStyle: TextStyle(color: Colors.grey.shade600),
                              suffixIcon: const Icon(Icons.calendar_today, size: 18), // Kleines Kalender-Icon
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade400),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // ----- UHRZEIT-FELD -----
                        Expanded(
                          child: TextField(
                            controller: _timeController, // Verbindet das Feld mit unserem Code
                            readOnly: true, // WICHTIG: Erlaubt keine manuelle Tastatureingabe
                            onTap: () => _selectTime(context), // Öffnet die Uhr beim Klicken!
                            decoration: InputDecoration(
                              hintText: "08:00",
                              hintStyle: TextStyle(color: Colors.grey.shade600),
                              suffixIcon: const Icon(Icons.access_time, size: 18), // Kleines Uhr-Icon
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade400),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Zusatzfeld für "Places", zwingt die Handy-Tastatur auf "Nur Zahlen"
                    _buildTextField("Places", "1", keyboardType: TextInputType.number, controller: _placesController),
                    const SizedBox(height: 24),

                    // Rechercher Button in Orange
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: btnColor,
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () async {
                          // Validation
                          final depText = _departController.text.trim();
                          final destText = _destinationController.text.trim();

                          if (depText.isEmpty || destText.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez remplir le départ et la destination.'), backgroundColor: Colors.red));
                            return;
                          }
                          if (_dateController.text.isEmpty || _timeController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner la date et l\'heure.'), backgroundColor: Colors.red));
                            return;
                          }
                          final places = int.tryParse(_placesController.text) ?? 0;
                          if (places <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Le nombre de places doit être supérieur à zéro.'), backgroundColor: Colors.red));
                            return;
                          }

                          // 1. Detaillierte Prüfung der Städte
                          if (!ApiService.isKnownCity(depText)) {
                            setState(() {
                              hasSearched = true;
                              resultatsApi = [];
                              noResultReason = "Aucun trajet trouvé pour la ville de départ '$depText'.";
                            });
                            return;
                          }
                          if (!ApiService.isKnownCity(destText)) {
                            setState(() {
                              hasSearched = true;
                              resultatsApi = [];
                              noResultReason = "Aucun trajet trouvé pour la destination '$destText'.";
                            });
                            return;
                          }

                          // 2. Datum und Uhrzeit präzise zusammensetzen (ISO-Format für Backend)
                          DateTime searchDateTime = DateTime.now();
                          if (selectedDate != null) {
                            final hour = selectedTime?.hour ?? 8;
                            final minute = selectedTime?.minute ?? 0;
                            searchDateTime = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day, hour, minute);
                          }
                          final isoDate = searchDateTime.toUtc().toIso8601String();

                          final departCoords = ApiService.getCoordinates(depText);
                          final arriveeCoords = ApiService.getCoordinates(destText);

                          final result = await ApiService.rechercherTrajets(
                            latDepart: departCoords['lat']!, 
                            lonDepart: departCoords['lon']!,
                            latArrivee: arriveeCoords['lat']!, 
                            lonArrivee: arriveeCoords['lon']!,
                            heureDepart: isoDate,
                            places: places,
                          );

                          String reason = "";
                          if (result.isEmpty) {
                            // Prüfung auf Ursache (Plätze oder Uhrzeit)
                            final testPlaces1 = await ApiService.rechercherTrajets(
                              latDepart: departCoords['lat']!,
                              lonDepart: departCoords['lon']!,
                              latArrivee: arriveeCoords['lat']!,
                              lonArrivee: arriveeCoords['lon']!,
                              heureDepart: isoDate,
                              places: 1,
                            );
                            if (testPlaces1.isNotEmpty) {
                              reason = "Nombre de places insuffisant pour ce trajet ($places demandée(s)).";
                            } else {
                              reason = "Aucun trajet disponible pour cette date ou cette heure sur cet itinéraire.";
                            }
                          }

                          setState(() {
                            resultatsApi = result;
                            hasSearched = true;
                            noResultReason = reason;
                          });
                        },
                        child: const Text('Rechercher', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Divider(thickness: 1), // Eine dünne graue Trennlinie
                    const SizedBox(height: 16),

                    // ==========================================
                    // 3. ERGEBNIS-ANZEIGE (Meilleur Résultat)
                    // ==========================================
                    if (hasSearched) ...[
                      if (resultatsApi.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              noResultReason.isNotEmpty ? noResultReason : "Aucun trajet trouvé pour ces critères.", 
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        )
                      else ...[
                        const Text(
                          "Meilleur résultat",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        
                        // Kasten für das beste Ergebnis
                        Card(
                          color: Colors.green.shade50, // Sehr heller grüner Hintergrund
                          elevation: 2, // Leichter Schatten
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Colors.green, width: 1.5), // Grüner Rahmen
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Score und Stern-Icon ganz oben rechts
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "${_resolveCity(resultatsApi.first['depart'], _departController.text)} → ${_resolveCity(resultatsApi.first['destination'], _destinationController.text)}", 
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text("Score ${resultatsApi.first['score'] ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                        const Icon(Icons.star, color: Colors.orange, size: 18),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Infos zur Fahrt (Zeit und Plätze) mit kleinen Icons daneben
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 18, color: Colors.black54),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDateHeure(resultatsApi.first['heureDepart']), 
                                      style: TextStyle(color: Colors.grey.shade700, fontSize: 14)
                                    ),
                                    const SizedBox(width: 16),
                                    const Icon(Icons.person, size: 18, color: Colors.black54),
                                    const SizedBox(width: 4),
                                    Text("${resultatsApi.first['placesDisponibles'] ?? '?'} places", style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                                  ],
                                ),
                              const SizedBox(height: 12),
                              // Der Button/Link "Demander une place"
                              GestureDetector(
                                onTap: () async {
                                  final res = await Navigator.push(context, MaterialPageRoute(
                                    builder: (context) => PassagerReservationScreen(
                                      trajet: resultatsApi.isNotEmpty ? resultatsApi.first : {},
                                      placesDemandees: int.tryParse(_placesController.text) ?? 1,
                                    ),
                                  ));
                                  if (res == true) {
                                    _chargerReservations();
                                  }
                                },
                                child: const Row(
                                  children: [
                                    Text("Demander une place", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E463D))),
                                    Icon(Icons.chevron_right, size: 18, color: Color(0xFF1E463D)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      ],
                      const SizedBox(height: 16),
                      
                      // Button für die restlichen Ergebnisse
                      if (resultatsApi.isNotEmpty)
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey.shade400),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => _afficherTousLesResultats(context),
                            child: const Text("Voir les autres propositions", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                          ),
                        )
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMesReservations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Mes réservations",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E463D)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E463D),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "${_mesReservations.length}",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._mesReservations.map((d) {
          Color statusBgColor = Colors.orange.shade100;
          Color statusTextColor = Colors.orange.shade800;
          String statusText = "En attente";

          if (d.statut == 'ACCEPTE' || d.statut == 'ACCEPTED') {
            statusBgColor = Colors.green.shade100;
            statusTextColor = Colors.green.shade800;
            statusText = "Confirmée";
          } else if (d.statut == 'REFUSE' || d.statut == 'REFUSED') {
            statusBgColor = Colors.red.shade100;
            statusTextColor = Colors.red.shade800;
            statusText = "Refusée";
          }

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  const Icon(Icons.bookmark, color: Color(0xFF1E463D), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.motif.isNotEmpty ? d.motif : "Trajet réservé",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E463D)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Demande : ${d.placesDemandees} place(s)",
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusBgColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(color: statusTextColor, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (d.synced == 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.orange, width: 0.8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.cloud_off, size: 10, color: Colors.orange),
                                    SizedBox(width: 2),
                                    Text("Hors-ligne", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: "Annuler cette réservation",
                    onPressed: () => _annulerReservation(d.id),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
