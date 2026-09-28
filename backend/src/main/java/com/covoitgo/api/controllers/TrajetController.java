package com.covoitgo.api.controllers;

import com.covoitgo.api.dto.CreerTrajetRequete;
import com.covoitgo.api.dto.RechercheTrajetResultat;
import com.covoitgo.api.dto.TraiterDemandeRequete;
import com.covoitgo.api.services.TrajetService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.List;

/**
 * CONTROLLER: Der Einstiegspunkt unserer REST-API.
 * 
 * Vergleiche mit Symfony:
 * - In Symfony: Ein Controller nimmt die Request ($request) entgegen, ruft
 * Services oder Doctrine auf und gibt eine JsonResponse zurück.
 * - In Spring Boot: Genau dasselbe! Der Controller leitet die Daten an den
 * "TrajetService" weiter
 * und liefert das Ergebnis als JSON (ResponseEntity) zurück.
 * 
 * @RestController sagt Spring Boot: Diese Klasse antwortet direkt mit Daten
 *                 (JSON), nicht mit HTML-Seiten.
 *                 @RequestMapping("/api/trajets") definiert das Präfix für alle
 *                 URLs in diesem Controller.
 * @Tag gruppiert diese Endpunkte in der grafischen Swagger-UI-Dokumentation.
 */
@RestController
@RequestMapping("/api/trajets")
@Tag(name = "Trajets", description = "Gestion des trajets (recherche avec algorithme Haversine, création et gestion des demandes)")
public class TrajetController {

        // Referenz auf die Geschäftslogik (unser Gehirn)
        private final TrajetService trajetService;

        /**
         * Dependency Injection (wie der Symfony Service Container):
         * Spring Boot reicht den TrajetService automatisch hier hinein.
         */
        public TrajetController(TrajetService trajetService) {
                this.trajetService = trajetService;
        }

        /**
         * US1 - SUCHE NACH EINER FAHRT (HAVERSINE ALGORITHMUS)
         */
        @Operation(summary = "Rechercher des trajets compatibles", description = "Calcule via la formule de Haversine la distance réelle par rapport aux trajets actifs et retourne les propositions triées par pertinence. Critères : départ à moins de 10 km, arrivée à moins de 10 km, horaire à ±30 minutes. Score = 60% distance + 30% horaire + 10% places.")
        @ApiResponses(value = {
                        @ApiResponse(responseCode = "200", description = "Recherche réussie (liste des trajets compatibles retournée)"),
                        @ApiResponse(responseCode = "400", description = "Paramètres de requête invalides ou manquants (ex: nombre de places inférieur à 1)", content = @Content),
                        @ApiResponse(responseCode = "422", description = "Coordonnées GPS hors limites valides (-90/+90 latitude, -180/+180 longitude)", content = @Content)
        })
        @GetMapping("/recherche") // HTTP GET: /api/trajets/recherche?latitudeDepart=...&...
        public ResponseEntity<List<RechercheTrajetResultat>> rechercherTrajets(
                        @Parameter(description = "Latitude du lieu de départ", example = "48.0794") @RequestParam double latitudeDepart,
                        @Parameter(description = "Longitude du lieu de départ", example = "7.3585") @RequestParam double longitudeDepart,
                        @Parameter(description = "Latitude du lieu d'arrivée souhaité", example = "47.7508") @RequestParam double latitudeArrivee,
                        @Parameter(description = "Longitude du lieu d'arrivée souhaité", example = "7.3359") @RequestParam double longitudeArrivee,
                        @Parameter(description = "Date et heure de départ souhaitées (format ISO-8601)", example = "2026-09-15T08:30:00Z") @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant heureDepart,
                        @Parameter(description = "Nombre de places souhaitées", example = "1") @RequestParam int places) {

                // Wir delegieren die gesamte Berechnung und Filterung an den Service
                List<RechercheTrajetResultat> resultats = trajetService.rechercherTrajets(
                                latitudeDepart,
                                longitudeDepart,
                                latitudeArrivee,
                                longitudeArrivee,
                                heureDepart,
                                places);

                // Rückgabe als HTTP 200 OK mit der berechneten Liste im JSON-Format
                return ResponseEntity.ok(resultats);
        }

        /**
         * US2 - EINE NEUE FAHRT ERSTELLEN (FAHRER)
         */
        @Operation(summary = "Proposer un nouveau trajet", description = "Permet à un conducteur de publier une nouvelle offre de covoiturage enregistrée comme active dans MongoDB.")
        @ApiResponses(value = {
                        @ApiResponse(responseCode = "201", description = "Trajet créé et enregistré avec succès dans MongoDB"),
                        @ApiResponse(responseCode = "400", description = "Données obligatoires manquantes dans le corps de la requête", content = @Content),
                        @ApiResponse(responseCode = "422", description = "Capacité du véhicule invalide (doit être au moins de 1 place)", content = @Content)
        })
        @PostMapping // HTTP POST: /api/trajets
        public ResponseEntity<Void> creerTrajet(
                        // @RequestBody: Spring Boot wandelt das empfangene JSON automatisch in das
                        // DTO-Objekt um
                        @RequestBody CreerTrajetRequete requete) {

                // Service aufrufen, um die Daten zu validieren und in MongoDB zu speichern
                trajetService.creerTrajet(requete);

                // HTTP 201 CREATED zurückgeben (Signal für erfolgreiche Erstellung)
                return ResponseEntity.status(HttpStatus.CREATED).build();
        }

        /**
         * US3 - EINE MITFAHRANFRAGE STELLEN (PASSAGIER)
         */
        @Operation(summary = "Envoyer une demande de réservation", description = "Permet à un passager de demander une place pour un trajet actif.")
        @ApiResponses(value = {
                        @ApiResponse(responseCode = "201", description = "Demande envoyée avec succès"),
                        @ApiResponse(responseCode = "404", description = "Trajet introuvable", content = @Content),
                        @ApiResponse(responseCode = "409", description = "Pas assez de places disponibles", content = @Content)
        })
        @PostMapping("/{trajetId}/demandes") // HTTP POST: /api/trajets/{trajetId}/demandes
        public ResponseEntity<Void> creerDemande(
                        @Parameter(description = "Identifiant unique du trajet", example = "60f719...a3b2") @PathVariable String trajetId,
                        @RequestBody com.covoitgo.api.dto.CreerDemandeRequete requete) {

                trajetService.creerDemande(trajetId, requete);
                return ResponseEntity.status(HttpStatus.CREATED).build();
        }

        /**
         * US3 - EINE MITFAHRANFRAGE BEARBEITEN (FAHRER)
         */
        @Operation(summary = "Traiter une demande de réservation", description = "Permet au conducteur d'accepter (décrémente les places disponibles) ou de refuser une demande de réservation pour son trajet.")
        @ApiResponses(value = {
                        @ApiResponse(responseCode = "200", description = "Décision enregistrée avec succès"),
                        @ApiResponse(responseCode = "400", description = "Statut de décision invalide (doit être ACCEPTE ou REFUSE)", content = @Content),
                        @ApiResponse(responseCode = "404", description = "Trajet ou demande de réservation introuvable", content = @Content),
                        @ApiResponse(responseCode = "409", description = "Conflit : nombre de places disponibles insuffisant pour accepter la demande", content = @Content)
        })
        @PatchMapping("/{trajetId}/demandes/{demandeId}") // HTTP PATCH: /api/trajets/{trajetId}/demandes/{demandeId}
        public ResponseEntity<Void> traiterDemande(
                        @Parameter(description = "Identifiant unique du trajet", example = "60f719...a3b2") @PathVariable String trajetId,
                        @Parameter(description = "Identifiant unique de la demande de réservation", example = "60f719...c4d5") @PathVariable String demandeId,
                        @RequestBody TraiterDemandeRequete requete) {

                // Service aufrufen, um Plätze zu prüfen und Status in MongoDB zu aktualisieren
                trajetService.traiterDemande(trajetId, demandeId, requete);

                // HTTP 200 OK zurückgeben
                return ResponseEntity.ok().build();
        }
}
