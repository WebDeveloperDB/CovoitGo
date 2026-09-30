import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ConducteurCreationTrajetScreen extends StatefulWidget {
  const ConducteurCreationTrajetScreen({super.key});

  @override
  State<ConducteurCreationTrajetScreen> createState() => _ConducteurCreationTrajetScreenState();
}

class _ConducteurCreationTrajetScreenState extends State<ConducteurCreationTrajetScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _departLabel = "";
  String _destinationLabel = "";
  int _capacite = 3;
  DateTime _dateDepart = DateTime.now().add(const Duration(days: 1)); // Morgen als Standard
  TimeOfDay _heureDepart = const TimeOfDay(hour: 8, minute: 0);

  bool _isLoading = false;

  Future<void> _soumettre() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    // Datum und Uhrzeit kombinieren
    final dateTime = DateTime(
      _dateDepart.year,
      _dateDepart.month,
      _dateDepart.day,
      _heureDepart.hour,
      _heureDepart.minute,
    ).toUtc().toIso8601String();

    // MOCK-Koordinaten für die Demo
    final departCoords = ApiService.getCoordinates(_departLabel);
    final arriveeCoords = ApiService.getCoordinates(_destinationLabel);

    final success = await ApiService.creerTrajet({
      "depart": {
        "label": _departLabel,
        "latitude": departCoords['lat']!,
        "longitude": departCoords['lon']!
      },
      "destination": {
        "label": _destinationLabel,
        "latitude": arriveeCoords['lat']!,
        "longitude": arriveeCoords['lon']!
      },
      "heureDepart": dateTime,
      "capacite": _capacite
    });

    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trajet créé avec succès !')),
      );
      // Gehe zurück zur Übersicht und übergebe "true" als Signal, dass neu geladen werden soll
      Navigator.of(context).pop(true);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la création du trajet.')),
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateDepart,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dateDepart = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _heureDepart,
    );
    if (picked != null) {
      setState(() => _heureDepart = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color bgColor = const Color(0xFFF4F2EC);
    final Color headerColor = const Color(0xFF1E463D);
    final Color btnColor = const Color(0xFFE29E4A);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: headerColor,
        foregroundColor: Colors.white,
        title: const Text('Proposer un trajet'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Détails du trajet",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E463D)),
                    ),
                    const SizedBox(height: 24),

                    // DEPART
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Lieu de départ',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on, color: Colors.green),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Champ requis' : null,
                      onSaved: (value) => _departLabel = value!,
                    ),
                    const SizedBox(height: 16),

                    // DESTINATION
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Destination',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.flag, color: Colors.red),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Champ requis' : null,
                      onSaved: (value) => _destinationLabel = value!,
                    ),
                    const SizedBox(height: 24),

                    // DATE ET HEURE
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _pickDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Date',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text("${_dateDepart.day}/${_dateDepart.month}/${_dateDepart.year}"),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: _pickTime,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Heure',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.access_time),
                              ),
                              child: Text(_heureDepart.format(context)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // CAPACITE
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Places disponibles',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.event_seat),
                      ),
                      value: _capacite,
                      items: [1, 2, 3, 4, 5, 6].map((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text(value.toString()),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _capacite = val);
                      },
                    ),
                    const SizedBox(height: 40),

                    // SUBMIT BUTTON
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: btnColor,
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _soumettre,
                        child: const Text('Publier le trajet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
