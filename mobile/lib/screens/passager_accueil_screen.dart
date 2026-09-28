import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'passager_reservation_screen.dart';

class PassagerAccueilScreen extends StatefulWidget {
  const PassagerAccueilScreen({super.key});

  @override
  State<PassagerAccueilScreen> createState() => _PassagerAccueilScreenState();
}

class _PassagerAccueilScreenState extends State<PassagerAccueilScreen> {
  // Dummy-Variable für den Namen des eingeloggten Benutzers.
  // Später holen wir diesen Namen dynamisch aus der Datenbank.
  final String userName = "Passager";
  
  // Zeigt an, ob wir bereits eine Suche durchgeführt haben.
  bool hasSearched = false; 

  // Hier speichern wir die Ergebnisse aus dem Backend!
  List<dynamic> resultatsApi = []; 

  // Variablen zum Speichern des gewählten Datums und der Uhrzeit
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _departController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _placesController = TextEditingController();

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
                          final departLabel = trajet['depart']?['label'] ?? 'Inconnu';
                          final destinationLabel = trajet['destination']?['label'] ?? 'Inconnu';
                          final score = trajet['score'] ?? 'N/A';
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (context) => PassagerReservationScreen(trajet: trajet),
                                ));
                              },
                              title: Text("$departLabel → $destinationLabel"),
                              subtitle: Text("Score: $score%"),
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
                    Text(
                      'Bonjour, $userName',
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
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
                          if (_departController.text.isEmpty || _destinationController.text.isEmpty) {
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

                          // 1. Koordinaten Demo (In echt würden wir Geocoding verwenden)
                          // Wir tun so, als ob wir Mulhouse -> Colmar anfragen
                          final result = await ApiService.rechercherTrajets(
                            latDepart: 47.7508, 
                            lonDepart: 7.3359,
                            latArrivee: 48.0794, 
                            lonArrivee: 7.3585,
                            heureDepart: "2026-09-15T08:30:00Z", // Demo-Datum (ISO)
                            places: places,
                          );

                          setState(() {
                            resultatsApi = result;
                            hasSearched = true;
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
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: Text("Aucun trajet trouvé pour ces critères.", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
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
                                        "${resultatsApi.first['depart']?['label'] ?? 'Inconnu'} → ${resultatsApi.first['destination']?['label'] ?? 'Inconnu'}", 
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
                                      (resultatsApi.first['heureDepart'] ?? '08:10').toString().contains('T') 
                                        ? (resultatsApi.first['heureDepart'] as String).split('T')[1].substring(0, 5) 
                                        : (resultatsApi.first['heureDepart'] ?? '08:10'), 
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
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(
                                    builder: (context) => PassagerReservationScreen(
                                      trajet: resultatsApi.isNotEmpty ? resultatsApi.first : {}
                                    ),
                                  ));
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
}
