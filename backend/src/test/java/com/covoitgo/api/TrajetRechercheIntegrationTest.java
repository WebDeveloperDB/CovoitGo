package com.covoitgo.api;

import com.covoitgo.api.models.Coordonnees;
import com.covoitgo.api.models.Trajet;
import com.covoitgo.api.repositories.TrajetRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Instant;

import static org.hamcrest.Matchers.*;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * INTEGRATIONSTESTS OHNE MOCK FÜR US1 (Recherche de trajets)
 * Entspricht Ticket FR403-854 und Confluence Seite 8.
 * 
 * Verwendet den echten Spring ApplicationContext (@SpringBootTest)
 * und echte MongoDB-Verbindung in Docker (trajetRepository) - OHNE MOCK!
 * Simuliert HTTP-Requests über MockMvc (Standard des Lehrplans).
 */
@SpringBootTest
@AutoConfigureMockMvc
public class TrajetRechercheIntegrationTest {

        @Autowired
        private MockMvc mockMvc;

        @Autowired
        private TrajetRepository trajetRepository;

        private static final String TRAJET_STRASBOURG_1_ID = "6ac4f5ffec2032127f4b5851";
        private static final String TRAJET_STRASBOURG_2_ID = "6ac4f5ffec2032127f4b5852";
        private static final String TRAJET_COLMAR_ID = "6ac4f5ffec2032127f4b5853";
        private static final String TRAJET_COMPLET_ID = "6ac4f5ffec2032127f4b5854";

        /**
         * VORBEDINGUNG / FIXTURES (@BeforeEach)
         * Wird VOR JEDEM EINZELNEN TEST automatisch ausgeführt.
         * Löscht alte Testdaten und setzt definierte Fahrten in die echte MongoDB ein.
         */
        @BeforeEach
        void preparerJeuDeDonnees() {
                trajetRepository.deleteAll();

                // 1. Fahrt 1: Strasbourg -> Mulhouse (09:00 UTC, 3 Plätze frei, aktiv) -> Score
                // 100% bei Suche um 09:00
                Trajet t1 = new Trajet();
                t1.setId(TRAJET_STRASBOURG_1_ID);
                t1.setIdConducteur("conducteur_001");
                t1.setDepart(new Coordonnees("Strasbourg", 48.5734, 7.7521));
                t1.setDestination(new Coordonnees("Mulhouse", 47.7508, 7.3359));
                t1.setHeureDepart(Instant.parse("2026-10-15T09:00:00Z"));
                t1.setCapacite(3);
                t1.setPlacesDisponibles(3);
                t1.setStatut("ACTIF");
                t1.setCreeLe(Instant.now());
                t1.setMisAJourLe(Instant.now());
                trajetRepository.save(t1);

                // 2. Fahrt 2: Strasbourg -> Mulhouse (09:30 UTC, 2 Plätze frei, aktiv) -> Score
                // 95% bei Suche um 09:00 (30 min Differenz = -5%)
                Trajet t2 = new Trajet();
                t2.setId(TRAJET_STRASBOURG_2_ID);
                t2.setIdConducteur("conducteur_002");
                t2.setDepart(new Coordonnees("Strasbourg", 48.5734, 7.7521));
                t2.setDestination(new Coordonnees("Mulhouse", 47.7508, 7.3359));
                t2.setHeureDepart(Instant.parse("2026-10-15T09:30:00Z"));
                t2.setCapacite(4);
                t2.setPlacesDisponibles(2);
                t2.setStatut("ACTIF");
                t2.setCreeLe(Instant.now());
                t2.setMisAJourLe(Instant.now());
                trajetRepository.save(t2);

                // 3. Fahrt 3: Colmar -> Mulhouse (09:30 UTC, 1 Platz frei, aktiv)
                Trajet t3 = new Trajet();
                t3.setId(TRAJET_COLMAR_ID);
                t3.setIdConducteur("conducteur_003");
                t3.setDepart(new Coordonnees("Colmar", 48.0794, 7.3585));
                t3.setDestination(new Coordonnees("Mulhouse", 47.7508, 7.3359));
                t3.setHeureDepart(Instant.parse("2026-10-15T09:30:00Z"));
                t3.setCapacite(2);
                t3.setPlacesDisponibles(1);
                t3.setStatut("ACTIF");
                t3.setCreeLe(Instant.now());
                t3.setMisAJourLe(Instant.now());
                trajetRepository.save(t3);

                // 4. Fahrt 4: Strasbourg -> Mulhouse (KOMPLETT BESETZT: 0 Plätze frei)
                Trajet t4 = new Trajet();
                t4.setId(TRAJET_COMPLET_ID);
                t4.setIdConducteur("conducteur_004");
                t4.setDepart(new Coordonnees("Strasbourg", 48.5734, 7.7521));
                t4.setDestination(new Coordonnees("Mulhouse", 47.7508, 7.3359));
                t4.setHeureDepart(Instant.parse("2026-10-15T09:00:00Z"));
                t4.setCapacite(3);
                t4.setPlacesDisponibles(0); // Voll!
                t4.setStatut("ACTIF");
                t4.setCreeLe(Instant.now());
                t4.setMisAJourLe(Instant.now());
                trajetRepository.save(t4);
        }

        // CAS NOMINAUX (CODE 200 OK)

        @Test
        @DisplayName("Cas nominal (200) : Recherche avec plusieurs résultats triés par score")
        void testRechercheAvecPlusieursResultatsTriesParScore() throws Exception {
                // Phase 1 : Echter HTTP-Aufruf der API via MockMvc
                mockMvc.perform(get("/api/trajets/recherche")
                                .param("latitudeDepart", "48.5734")
                                .param("longitudeDepart", "7.7521")
                                .param("latitudeArrivee", "47.7508")
                                .param("longitudeArrivee", "7.3359")
                                .param("places", "1")
                                .param("heureDepart", "2026-10-15T09:00:00Z"))
                                // Assertions HTTP
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$", hasSize(2)))
                                // 1. Ergebnis muss Fahrt 1 sein mit Score 100.0 (exakte Uhrzeit 09:00)
                                .andExpect(jsonPath("$[0].idTrajet").value(TRAJET_STRASBOURG_1_ID))
                                .andExpect(jsonPath("$[0].score").value(100.0))
                                // 2. Ergebnis muss Fahrt 2 sein mit Score 95.0 (30 min Differenz)
                                .andExpect(jsonPath("$[1].idTrajet").value(TRAJET_STRASBOURG_2_ID))
                                .andExpect(jsonPath("$[1].score").value(95.0));

                // Phase 2 : BDD-Prüfung (Lesen ändert niemals die Datenbank)
                assertEquals(4, trajetRepository.count(),
                                "La recherche en lecture seule ne doit altérer aucun document en BDD");
        }

        @Test
        @DisplayName("Cas nominal (200) : Dégressivité du score selon l'heure (-10% par heure d'écart)")
        void testDegressiviteScoreHoraire() throws Exception {
                // Suche um 10:00 Uhr:
                // - Fahrt 2 (09:30) hat 30 min Differenz -> -5% -> Score 95.0% (1. Platz)
                // - Fahrt 1 (09:00) hat 60 min Differenz -> -10% -> Score 90.0% (2. Platz)
                mockMvc.perform(get("/api/trajets/recherche")
                                .param("latitudeDepart", "48.5734")
                                .param("longitudeDepart", "7.7521")
                                .param("latitudeArrivee", "47.7508")
                                .param("longitudeArrivee", "7.3359")
                                .param("places", "1")
                                .param("heureDepart", "2026-10-15T10:00:00Z"))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$[0].idTrajet").value(TRAJET_STRASBOURG_2_ID))
                                .andExpect(jsonPath("$[0].score").value(95.0))
                                .andExpect(jsonPath("$[1].idTrajet").value(TRAJET_STRASBOURG_1_ID))
                                .andExpect(jsonPath("$[1].score").value(90.0));

                // Suche um 11:00 Uhr:
                // - Fahrt 2 (09:30) hat 90 min Differenz -> -15% -> Score 85.0% (1. Platz)
                // - Fahrt 1 (09:00) hat 120 min Differenz -> -20% -> Score 80.0% (2. Platz)
                mockMvc.perform(get("/api/trajets/recherche")
                                .param("latitudeDepart", "48.5734")
                                .param("longitudeDepart", "7.7521")
                                .param("latitudeArrivee", "47.7508")
                                .param("longitudeArrivee", "7.3359")
                                .param("places", "1")
                                .param("heureDepart", "2026-10-15T11:00:00Z"))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$[0].idTrajet").value(TRAJET_STRASBOURG_2_ID))
                                .andExpect(jsonPath("$[0].score").value(85.0))
                                .andExpect(jsonPath("$[1].idTrajet").value(TRAJET_STRASBOURG_1_ID))
                                .andExpect(jsonPath("$[1].score").value(80.0));
        }

        @Test
        @DisplayName("Cas nominal (200) : Un seul résultat compatible (Colmar)")
        void testRechercheUnSeulResultatCompatible() throws Exception {
                // Suche gezielt ab Colmar
                mockMvc.perform(get("/api/trajets/recherche")
                                .param("latitudeDepart", "48.0794")
                                .param("longitudeDepart", "7.3585")
                                .param("latitudeArrivee", "47.7508")
                                .param("longitudeArrivee", "7.3359")
                                .param("places", "1")
                                .param("heureDepart", "2026-10-15T09:30:00Z"))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$", hasSize(1)))
                                .andExpect(jsonPath("$[0].idTrajet").value(TRAJET_COLMAR_ID))
                                .andExpect(jsonPath("$[0].score").value(100.0));
        }

        // CAS LIMITES (CODE 200 AVEC LISTE VIDE OU EXCLUSIONS)

        @Test
        @DisplayName("Cas limite (200) : Aucun trajet à distance (seuil Haversine > 10 km)")
        void testAucunTrajetADistance() throws Exception {
                // Suche ab Paris (weit weg vom Elsass, Distanz > 400 km)
                mockMvc.perform(get("/api/trajets/recherche")
                                .param("latitudeDepart", "48.8566")
                                .param("longitudeDepart", "2.3522")
                                .param("latitudeArrivee", "47.7508")
                                .param("longitudeArrivee", "7.3359")
                                .param("places", "1")
                                .param("heureDepart", "2026-10-15T09:00:00Z"))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$", hasSize(0)));
        }

        @Test
        @DisplayName("Cas limite (200) : Trajet complet (0 place) strictement exclu")
        void testTrajetCompletExclu() throws Exception {
                mockMvc.perform(get("/api/trajets/recherche")
                                .param("latitudeDepart", "48.5734")
                                .param("longitudeDepart", "7.7521")
                                .param("latitudeArrivee", "47.7508")
                                .param("longitudeArrivee", "7.3359")
                                .param("places", "1")
                                .param("heureDepart", "2026-10-15T09:00:00Z"))
                                .andExpect(status().isOk())
                                // Trajet complet (TRAJET_COMPLET_ID) ne doit jamais être présent
                                .andExpect(jsonPath("$[*].idTrajet", not(hasItem(TRAJET_COMPLET_ID))));
        }

        @Test
        @DisplayName("Cas limite (200) : Écart horaire supérieur à 4 heures exclu")
        void testEcartHoraireSuperieurAQuatreHeuresExclu() throws Exception {
                // Suche um 15:00 Uhr (6 Stunden Differenz zu Fahrt 1 von 09:00 Uhr)
                mockMvc.perform(get("/api/trajets/recherche")
                                .param("latitudeDepart", "48.5734")
                                .param("longitudeDepart", "7.7521")
                                .param("latitudeArrivee", "47.7508")
                                .param("longitudeArrivee", "7.3359")
                                .param("places", "1")
                                .param("heureDepart", "2026-10-15T15:00:00Z"))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$", hasSize(0)));
        }

        // CAS D'ERREURS (CODE 400 ET 422)

        @Test
        @DisplayName("Cas d'erreur (400) : Nombre de places invalide (places = 0 ou places = 9)")
        void testNombreDePlacesInvalideRetourne400() throws Exception {
                // 0 Plätze angefragt
                mockMvc.perform(get("/api/trajets/recherche")
                                .param("latitudeDepart", "48.5734")
                                .param("longitudeDepart", "7.7521")
                                .param("latitudeArrivee", "47.7508")
                                .param("longitudeArrivee", "7.3359")
                                .param("places", "0")
                                .param("heureDepart", "2026-10-15T09:00:00Z"))
                                .andExpect(status().isBadRequest());

                // 9 Plätze angefragt (Maximum ist 8)
                mockMvc.perform(get("/api/trajets/recherche")
                                .param("latitudeDepart", "48.5734")
                                .param("longitudeDepart", "7.7521")
                                .param("latitudeArrivee", "47.7508")
                                .param("longitudeArrivee", "7.3359")
                                .param("places", "9")
                                .param("heureDepart", "2026-10-15T09:00:00Z"))
                                .andExpect(status().isBadRequest());
        }

        @Test
        @DisplayName("Cas d'erreur (422) : Coordonnées GPS aberrantes (latitude > 90)")
        void testCoordonneesAberrantesRetourne422() throws Exception {
                // Breitengrad 95.0 existiert auf der Erde nicht (max 90)
                mockMvc.perform(get("/api/trajets/recherche")
                                .param("latitudeDepart", "95.0")
                                .param("longitudeDepart", "7.7521")
                                .param("latitudeArrivee", "47.7508")
                                .param("longitudeArrivee", "7.3359")
                                .param("places", "1")
                                .param("heureDepart", "2026-10-15T09:00:00Z"))
                                .andExpect(status().isUnprocessableEntity());
        }
}
