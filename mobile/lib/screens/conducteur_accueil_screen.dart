import 'package:flutter/material.dart';

class ConducteurAccueilScreen extends StatelessWidget {
  const ConducteurAccueilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy-Variable für den Namen des eingeloggten Fahrers.
    final String userName = "Conducteur";
    
    // Farben exakt aus dem Maquette kopiert
    final Color bgColor = const Color(0xFFF4F2EC); // Heller Beige-Hintergrund
    final Color headerColor = const Color(0xFF1E463D); // Dunkelgrüner Header
    final Color btnColor = const Color(0xFFE29E4A); // Orangener Button

    return Scaffold(
      backgroundColor: bgColor, 
      body: SafeArea(
        child: SingleChildScrollView(
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
                    
                    // --- Mon trajet actif (Aktive Fahrt) ---
                    const Text(
                      "Mon trajet actif",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    
                    // Kasten für die aktuelle Fahrt (jetzt schöner)
                    Card(
                      color: Colors.green.shade50, // Heller grüner Hintergrund wie bei Passager
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Colors.green, width: 1.5), // Grüner Rand
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Colmar → Mulhouse", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 18, color: Colors.black54),
                                const SizedBox(width: 4),
                                Text("Aujourd'hui à 18:00", style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.event_seat, size: 18, color: Colors.black54),
                                const SizedBox(width: 4),
                                Text("Places disponibles : 2", style: TextStyle(color: Colors.grey.shade800, fontSize: 14, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
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
                        onPressed: () {
                          // Später: Wechsel zur Seite, um eine neue Fahrt anzubieten
                        },
                        child: const Text('Proposer un trajet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // --- Demande en attente (Anfragen von Passagieren) ---
                    const Text(
                      "Demande en attente",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    
                    // Kasten für die Anfrage (jetzt schöner)
                    Card(
                      color: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade300, width: 1.5), 
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.person_add, color: Color(0xFF1E463D)),
                                const SizedBox(width: 8),
                                const Text("Demande de Passager", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text("1 place demandée", style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                            const SizedBox(height: 16),
                            
                            // Zwei Buttons nebeneinander (Accepter / Refuser)
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1E463D), // Dunkelgrün
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () {},
                                    child: const Text("Accepter"),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red.shade700,
                                      side: BorderSide(color: Colors.red.shade700), // Roter Rand für Ablehnen
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () {},
                                    child: const Text("Refuser"),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
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
