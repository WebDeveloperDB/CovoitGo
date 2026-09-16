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
@Tag(name = "Trajets", description = "Verwaltung der Fahrten (Suche mit Haversine, Erstellung und Anfragen)")
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
         * =========================================================================
         * US1 - SUCHE NACH EINER FAHRT (HAVERSINE ALGORITHMUS)
         * =========================================================================
         */
        @Operation(summary = "Kompatible Fahrten suchen", description = "Kalkuliert mit der Haversine-Formel die Distanz zu aktiven Fahrten und liefert passende Treffer sortiert nach Relevanz zurück.")
        @ApiResponses(value = {
                        @ApiResponse(responseCode = "200", description = "Suche erfolgreich (Liste kompatibler Fahrten)"),
                        @ApiResponse(responseCode = "400", description = "Fehlende oder unlogische Parameter (z.B. 0 Plätze)", content = @Content),
                        @ApiResponse(responseCode = "422", description = "Ungültige GPS-Koordinaten (außerhalb des Wertebereichs)", content = @Content)
        })
        @GetMapping("/recherche") // HTTP GET: /api/trajets/recherche?latitudeDepart=...&...
        public ResponseEntity<List<RechercheTrajetResultat>> rechercherTrajets(
                        @Parameter(description = "Breitengrad Start (z.B. Colmar)", example = "48.0794") @RequestParam double latitudeDepart,
                        @Parameter(description = "Längengrad Start (z.B. Colmar)", example = "7.3585") @RequestParam double longitudeDepart,
                        @Parameter(description = "Breitengrad Ziel (z.B. Mulhouse)", example = "47.7508") @RequestParam double latitudeArrivee,
                        @Parameter(description = "Längengrad Ziel (z.B. Mulhouse)", example = "7.3359") @RequestParam double longitudeArrivee,
                        @Parameter(description = "Gewünschte Abfahrtszeit (ISO-8601)", example = "2026-09-15T08:30:00Z") @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant heureDepart,
                        @Parameter(description = "Anzahl gewünschter Plätze", example = "1") @RequestParam int places) {

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
         * =========================================================================
         * US2 - EINE NEUE FAHRT ERSTELLEN (FAHRER)
         * =========================================================================
         */
        @Operation(summary = "Eine neue Fahrt vorschlagen", description = "Speichert eine neue Fahrt des Fahrers als aktive Fahrt in der MongoDB.")
        @ApiResponses(value = {
                        @ApiResponse(responseCode = "201", description = "Fahrt erfolgreich erstellt"),
                        @ApiResponse(responseCode = "400", description = "Fehlende Pflichtangaben", content = @Content),
                        @ApiResponse(responseCode = "422", description = "Ungültige Kapazität", content = @Content)
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
         * =========================================================================
         * US3 - EINE MITFAHRANFRAGE BEARBEITEN (FAHRER)
         * =========================================================================
         */
        @Operation(summary = "Eine Anfrage akzeptieren oder ablehnen", description = "Erlaubt dem Fahrer, eine Anfrage zu bestätigen (Plätze werden reduziert) oder abzulehnen.")
        @ApiResponses(value = {
                        @ApiResponse(responseCode = "200", description = "Entscheidung erfolgreich gespeichert"),
                        @ApiResponse(responseCode = "400", description = "Ungültiger Status", content = @Content),
                        @ApiResponse(responseCode = "404", description = "Fahrt oder Anfrage nicht gefunden", content = @Content),
                        @ApiResponse(responseCode = "409", description = "Konflikt: Nicht mehr genügend freie Plätze", content = @Content)
        })
        @PatchMapping("/{trajetId}/demandes/{demandeId}") // HTTP PATCH: /api/trajets/{trajetId}/demandes/{demandeId}
        public ResponseEntity<Void> traiterDemande(
                        @Parameter(description = "Eindeutige ID der Fahrt", example = "60f719...a3b2") @PathVariable String trajetId,
                        @Parameter(description = "Eindeutige ID der Anfrage", example = "60f719...c4d5") @PathVariable String demandeId,
                        @RequestBody TraiterDemandeRequete requete) {

                // Service aufrufen, um Plätze zu prüfen und Status in MongoDB zu aktualisieren
                trajetService.traiterDemande(trajetId, demandeId, requete);

                // HTTP 200 OK zurückgeben
                return ResponseEntity.ok().build();
        }
}
