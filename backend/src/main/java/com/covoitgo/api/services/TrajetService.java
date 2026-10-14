package com.covoitgo.api.services;

import com.covoitgo.api.dto.CoordonneesDto;
import com.covoitgo.api.dto.CreerTrajetRequete;
import com.covoitgo.api.dto.RechercheTrajetResultat;
import com.covoitgo.api.dto.TraiterDemandeRequete;
import com.covoitgo.api.models.Coordonnees;
import com.covoitgo.api.models.DemandeTrajet;
import com.covoitgo.api.models.Trajet;
import com.covoitgo.api.repositories.DemandeTrajetRepository;
import com.covoitgo.api.repositories.TrajetRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

/**
 * SERVICE: Hier befindet sich das eigentliche Gehirn unserer Anwendung (die
 * "Règles Métier" / Geschäftslogik).
 * 
 * Im Controller nehmen wir nur die HTTP-Anfrage an und rufen dann diesen
 * Service auf.
 * Hier werden Berechnungen (z.B. Haversine GPS-Kalkulation), Validierungen und
 * Datenbankzugriffe durchgeführt.
 * 
 * @Service sagt Spring Boot: "Erstelle automatisch eine Instanz dieser Klasse
 *          und verwalte sie (Dependency Injection)."
 */
@Service
public class TrajetService {

    // Erdradius in Kilometern (notwendig für die Haversine-Formel auf der Erdkugel)
    private static final double RAYON_TERRE_KM = 6371.0;

    // Maximaler Umkreis in Kilometern, den wir als passend ansehen (Toleranz für
    // Start und Ziel)
    // Ein Passagier akzeptiert einen Umweg von 10km maximal
    private static final double SEUIL_MAX_DISTANCE_KM = 10.0;

    // Referenz auf das TrajetRepository für den Zugriff auf die MongoDB-Sammlung
    // "trajets"
    private final TrajetRepository trajetRepository;

    // Referenz auf das DemandeTrajetRepository für den Zugriff auf die
    // MongoDB-Sammlung "demandes"
    private final DemandeTrajetRepository demandeTrajetRepository;

    /**
     * Konstruktor mit Dependency Injection:
     * Spring Boot übergibt automatisch die beiden Repositories beim Erstellen des
     * Services.
     */
    public TrajetService(TrajetRepository trajetRepository, DemandeTrajetRepository demandeTrajetRepository) {
        this.trajetRepository = trajetRepository;
        this.demandeTrajetRepository = demandeTrajetRepository;
    }

    /**
     * US1 - HAVERSINE MATCHING (Berechnung der GPS-Distanz und Fahrten-Suche)
     * 
     * Diese Methode sucht in der Datenbank nach aktiven Fahrten und prüft mit der
     * Haversine-Formel, ob Start- und Zielkoordinaten des Fahrers nah genug an den
     * Wünschen des Passagiers liegen.
     */
    public List<RechercheTrajetResultat> rechercherTrajets(
            double latitudeDepart,
            double longitudeDepart,
            double latitudeArrivee,
            double longitudeArrivee,
            Instant heureDepart,
            int placesDemandees) {

        // 1. Validierung der GPS-Koordinaten (Breitengrad -90 bis +90, Längengrad -180
        // bis +180)
        if (latitudeDepart < -90.0 || latitudeDepart > 90.0 || latitudeArrivee < -90.0 || latitudeArrivee > 90.0
                || longitudeDepart < -180.0 || longitudeDepart > 180.0 || longitudeArrivee < -180.0
                || longitudeArrivee > 180.0) {
            // Wenn die Koordinaten unmöglich sind, werfen wir einen HTTP 422 Fehler
            throw new ResponseStatusException(HttpStatus.UNPROCESSABLE_CONTENT, "Coordonnées GPS invalides.");
        }

        // 2. Validierung der gewünschten Plätze (muss mindestens 1 Platz sein und max
        // 8)
        if (placesDemandees <= 0 || placesDemandees > 8) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Le nombre de places doit être compris entre 1 et 8.");
        }

        // 3. Alle aktiven Fahrten aus der MongoDB-Datenbank laden

        List<Trajet> trajetsActifs = trajetRepository.findByStatut("ACTIF");

        // Liste vorbereiten, in der wir die passenden Ergebnisse sammeln
        List<RechercheTrajetResultat> resultatsCompatibles = new ArrayList<>();

        // 4. Durch jede aktive Fahrt der Datenbank iterieren (Schleife)
        for (Trajet trajet : trajetsActifs) {

            // Prüfen, ob die Fahrt überhaupt genug freie Plätze hat
            if (trajet.getPlacesDisponibles() < placesDemandees) {
                // Nicht genügend Plätze -> diese Fahrt überspringen
                continue;
            }

            // Sicherstellen, dass die Fahrt Start- und Zielkoordinaten in der DB
            // gespeichert hat
            if (trajet.getDepart() == null || trajet.getDestination() == null) {
                continue;
            }

            // 5. HAVERSINE-KALKULATION: Distanz zwischen Passagier-Start und Fahrer-Start
            // (die Funktion calculerDistanceHaversine ist weiter unten in dieser Datei)
            double distanceDepart = calculerDistanceHaversine(
                    latitudeDepart,
                    longitudeDepart,
                    trajet.getDepart().getLatitude(),
                    trajet.getDepart().getLongitude());

            // 6. HAVERSINE-KALKULATION: Distanz zwischen Passagier-Ziel und Fahrer-Ziel
            double distanceArrivee = calculerDistanceHaversine(
                    latitudeArrivee,
                    longitudeArrivee,
                    trajet.getDestination().getLatitude(),
                    trajet.getDestination().getLongitude());

            // 7. Filterkriterium: Liegen Start UND Ziel innerhalb unseres maximalen
            // Toleranzradius (z.B. 10 km)?
            if (distanceDepart <= SEUIL_MAX_DISTANCE_KM && distanceArrivee <= SEUIL_MAX_DISTANCE_KM) {

                // Gesamtabweichung (Umweg) berechnen
                double detourTotalKm = distanceDepart + distanceArrivee;

                // Relevanz-Score ermitteln: Berücksichtigt Distanz und Uhrzeit
                double score = Math.max(0.0, 100.0 - (detourTotalKm * 5.0));

                if (heureDepart != null && trajet.getHeureDepart() != null) {
                    long diffMinutes = Math
                            .abs(java.time.Duration.between(heureDepart, trajet.getHeureDepart()).toMinutes());
                    // Pro 15 Minuten Zeitdifferenz 1 Punkt Abzug, max. Abzug 80 Punkte
                    double penaliteHoraire = Math.min(80.0, diffMinutes / 15.0);
                    score = Math.max(15.0, score - penaliteHoraire);
                }

                // Neues DTO-Ergebnisobjekt erstellen (genau das, was das Frontend erwartet)
                RechercheTrajetResultat resultat = new RechercheTrajetResultat();
                resultat.setIdTrajet(trajet.getId());
                resultat.setHeureDepart(trajet.getHeureDepart());
                resultat.setPlacesDisponibles(trajet.getPlacesDisponibles());
                resultat.setScore(Math.round(score * 10.0) / 10.0); // Auf 1 Nachkommastelle runden

                // Startpunkt des Fahrers ins DTO mappen
                CoordonneesDto depDto = new CoordonneesDto();
                depDto.setLabel(trajet.getDepart().getLabel());
                depDto.setLatitude(trajet.getDepart().getLatitude());
                depDto.setLongitude(trajet.getDepart().getLongitude());
                resultat.setDepart(depDto);

                // Zielpunkt des Fahrers ins DTO mappen
                CoordonneesDto destDto = new CoordonneesDto();
                destDto.setLabel(trajet.getDestination().getLabel());
                destDto.setLatitude(trajet.getDestination().getLatitude());
                destDto.setLongitude(trajet.getDestination().getLongitude());
                resultat.setDestination(destDto);

                // Zur Ergebnisliste hinzufügen
                resultatsCompatibles.add(resultat);
            }
        }

        // 8. Ergebnisse nach Score sortieren (die beste Fahrt mit dem höchsten Score
        // zuerst)
        resultatsCompatibles.sort(Comparator.comparingDouble(RechercheTrajetResultat::getScore).reversed());

        // Fertige Liste an den Controller zurückgeben
        return resultatsCompatibles;
    }

    /**
     * MATHEMATISCHE HAVERSINE-FORMELs
     * 
     * Berechnet die Luftlinien-Distanz zwischen zwei GPS-Punkten auf einer Kugel
     * (Erde).
     * 
     * @param lat1 Breitengrad Punkt 1
     * @param lon1 Längengrad Punkt 1
     * @param lat2 Breitengrad Punkt 2
     * @param lon2 Längengrad Punkt 2
     * @return Distanz in Kilometern
     */
    public double calculerDistanceHaversine(double lat1, double lon1, double lat2, double lon2) {
        // Differenzen in Bogenmaß (Radiant) umrechnen, da Java Math mit Radiant rechnet
        double deltaLat = Math.toRadians(lat2 - lat1);
        double deltaLon = Math.toRadians(lon2 - lon1);

        // Die beiden Breitengrade ebenfalls in Radiant umwandeln
        double radLat1 = Math.toRadians(lat1);
        double radLat2 = Math.toRadians(lat2);

        // Die Haversine-Gleichung anwenden (Sinus- und Cosinus-Berechnungen)
        double a = Math.sin(deltaLat / 2.0) * Math.sin(deltaLat / 2.0)
                + Math.cos(radLat1) * Math.cos(radLat2)
                        * Math.sin(deltaLon / 2.0) * Math.sin(deltaLon / 2.0);

        // Berechnung des zentralen Winkels c
        double c = 2.0 * Math.atan2(Math.sqrt(a), Math.sqrt(1.0 - a));

        // Distanz = Erdradius (6371 km) * Zentraler Winkel
        return RAYON_TERRE_KM * c;
    }

    /**
     * US2 - NEUE FAHRT ERSTELLEN (Speichern in MongoDB)
     */
    public Trajet creerTrajet(CreerTrajetRequete requete) {

        // Validierung: Kapazität muss mindestens 1 sein
        if (requete.getCapacite() <= 0 || requete.getCapacite() > 8) {
            throw new ResponseStatusException(HttpStatus.UNPROCESSABLE_CONTENT,
                    "La capacité doit être comprise entre 1 et 8 places.");
        }

        // Validierung: Start und Ziel dürfen nicht fehlen
        if (requete.getDepart() == null || requete.getDestination() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Le départ et la destination sont obligatoires.");
        }

        // Validierung: Abfahrtszeit muss angegeben sein
        if (requete.getHeureDepart() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "L'heure de départ est obligatoire.");
        }

        // Neues MongoDB-Entity-Objekt erstellen
        Trajet trajet = new Trajet();

        // Startkoordinaten aus dem DTO in das Entity übertragen
        Coordonnees depart = new Coordonnees();
        depart.setLabel(requete.getDepart().getLabel());
        depart.setLatitude(requete.getDepart().getLatitude());
        depart.setLongitude(requete.getDepart().getLongitude());
        trajet.setDepart(depart);

        // Zielkoordinaten aus dem DTO in das Entity übertragen
        Coordonnees destination = new Coordonnees();
        destination.setLabel(requete.getDestination().getLabel());
        destination.setLatitude(requete.getDestination().getLatitude());
        destination.setLongitude(requete.getDestination().getLongitude());
        trajet.setDestination(destination);

        // Weitere Eigenschaften setzen
        trajet.setHeureDepart(requete.getHeureDepart());
        trajet.setCapacite(requete.getCapacite());
        trajet.setPlacesDisponibles(requete.getCapacite()); // Am Anfang sind alle Plätze frei
        trajet.setStatut("ACTIF"); // Die Fahrt ist ab sofort aktiv für Suchen
        trajet.setCreeLe(Instant.now()); // Aktueller Zeitstempel
        trajet.setMisAJourLe(Instant.now());

        // In der MongoDB speichern und das gespeicherte Dokument zurückgeben
        return trajetRepository.save(trajet);
    }

    /**
     * US3 - NOUVELLE DEMANDE DE COVOITURAGE (Passager)
     */
    public DemandeTrajet creerDemande(String trajetId, com.covoitgo.api.dto.CreerDemandeRequete requete) {
        // 1. Fahrt aus MongoDB suchen
        Trajet trajet = trajetRepository.findById(trajetId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Trajet non trouvé"));

        // 2. Prüfen, ob noch genügend freie Plätze vorhanden sind
        if (trajet.getPlacesDisponibles() < requete.getPlacesDemandees()) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Pas assez de places disponibles dans ce trajet.");
        }

        // Prüfen, ob dieser Passagier bereits eine aktive Buchungsanfrage für diese
        // Fahrt hat
        List<DemandeTrajet> existantes = demandeTrajetRepository.findByIdTrajetAndIdPassager(trajetId,
                requete.getIdPassager());
        boolean dejaReserve = existantes.stream().anyMatch(d ->

        "PENDING".equalsIgnoreCase(d.getStatut()) ||

                "EN_ATTENTE".equalsIgnoreCase(d.getStatut()) ||

                "ACCEPTE".equalsIgnoreCase(d.getStatut()) ||

                "ACCEPTED".equalsIgnoreCase(d.getStatut()));
        if (dejaReserve) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Vous avez déjà une demande en cours ou acceptée pour ce trajet.");
        }

        // 3. Neue Anfrage (Demande) erstellen
        DemandeTrajet demande = new DemandeTrajet();
        demande.setIdTrajet(trajetId);
        demande.setIdPassager(requete.getIdPassager());
        demande.setPlacesDemandees(requete.getPlacesDemandees());
        demande.setStatut("PENDING"); // Standardstatus bei neuer Anfrage
        demande.setCreeLe(Instant.now());
        demande.setMisAJourLe(Instant.now());

        // 4. In MongoDB speichern
        return demandeTrajetRepository.save(demande);
    }

    /**
     * US3 - MITFAHRANFRAGE BEARBEITEN (Akzeptieren / Ablehnen)
     */
    public void traiterDemande(String trajetId, String demandeId, TraiterDemandeRequete requete) {

        // 1. Fahrt aus MongoDB suchen
        Trajet trajet = trajetRepository.findById(trajetId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Trajet non trouvé"));

        // 2. Anfrage aus MongoDB suchen
        DemandeTrajet demande = demandeTrajetRepository.findById(demandeId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Demande non trouvée"));

        // 3. Prüfen, was der Fahrer entschieden hat (ACCEPTE oder REFUSE)
        String decision = requete.getStatut() != null ? requete.getStatut().toUpperCase() : "";

        if ("ACCEPTE".equals(decision) || "ACCEPTED".equals(decision)) {

            // Prüfen, ob noch genügend freie Plätze im Auto vorhanden sind
            if (trajet.getPlacesDisponibles() < demande.getPlacesDemandees()) {
                // Wenn nicht genug Plätze frei sind: HTTP 409 Conflict
                throw new ResponseStatusException(HttpStatus.CONFLICT,
                        "Pas assez de places disponibles dans ce trajet.");
            }

            // Plätze im Auto reduzieren
            int nouvellesPlaces = trajet.getPlacesDisponibles() - demande.getPlacesDemandees();
            trajet.setPlacesDisponibles(nouvellesPlaces);

            // Falls keine Plätze mehr frei sind, Status der Fahrt auf "COMPLET" setzen
            if (nouvellesPlaces == 0) {
                trajet.setStatut("COMPLET");
            }
            trajet.setMisAJourLe(Instant.now());
            trajetRepository.save(trajet); // Aktualisierte Fahrt in MongoDB speichern

            // Status der Anfrage auf ACCEPTE setzen
            demande.setStatut("ACCEPTE");
            demande.setDecideLe(Instant.now());
            demande.setMisAJourLe(Instant.now());
            demandeTrajetRepository.save(demande); // Aktualisierte Anfrage in MongoDB speichern

        } else if ("REFUSE".equals(decision) || "REFUSED".equals(decision)) {

            // Bei Ablehnung: Status auf REFUSE setzen und Grund speichern
            demande.setStatut("REFUSE");
            demande.setRaison(requete.getRaison());
            demande.setDecideLe(Instant.now());
            demande.setMisAJourLe(Instant.now());
            demandeTrajetRepository.save(demande);

        } else {
            // Wenn der Status weder ACCEPTE noch REFUSE ist: HTTP 400 Bad Request
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Statut invalide : doit être ACCEPTE ou REFUSE.");
        }
    }

    /**
     * US2 - MES TRAJETS (Für den MVP geben wir einfach alle aktiven Fahrten zurück)
     */
    public List<Trajet> getMesTrajetsActifs() {
        return trajetRepository.findByStatut("ACTIF");
    }

    /**
     * US3 - DEMANDES FÜR EINE FAHRT ABRUFEN
     */
    public List<DemandeTrajet> getDemandesPourTrajet(String trajetId) {
        return demandeTrajetRepository.findByIdTrajetAndStatut(trajetId, "PENDING");
    }

    public void supprimerTrajet(String trajetId) {
        Trajet trajet = trajetRepository.findById(trajetId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Trajet introuvable"));
        trajet.setStatut("ANNULE");
        trajetRepository.save(trajet);
    }
}
