package com.covoitgo.api;

import com.covoitgo.api.dto.CoordonneesDto;
import com.covoitgo.api.dto.CreerTrajetRequete;
import com.covoitgo.api.models.Trajet;
import com.covoitgo.api.repositories.TrajetRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Instant;
import java.util.List;

import static org.hamcrest.Matchers.hasSize;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.covoitgo.api.models.Utilisateur;
import com.covoitgo.api.repositories.UtilisateurRepository;
import com.covoitgo.api.services.JwtService;

/**
 * INTEGRATIONSTESTS OHNE MOCK FÜR US2 (Proposer un trajet)
 * Entspricht Ticket FR403-855 und Confluence Seite 8.
 *
 * Testet den vollständigen Pfad:
 * Client HTTP POST -> TrajetController -> TrajetService -> TrajetRepository -> Echte MongoDB
 * Verwendet ein gültiges JWT Bearer Token für die geschützte Route POST /api/trajets.
 */
@SpringBootTest
@AutoConfigureMockMvc
public class TrajetCreationIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    private final ObjectMapper objectMapper = new ObjectMapper().findAndRegisterModules();

    @Autowired
    private TrajetRepository trajetRepository;

    @Autowired
    private UtilisateurRepository utilisateurRepository;

    @Autowired
    private JwtService jwtService;

    private String validToken;

    @BeforeEach
    void preparerJeuDeDonnees() {
        trajetRepository.deleteAll();
        utilisateurRepository.deleteAll();

        // Test-Benutzer anlegen und echtes JWT-Token für autorisierte Tests erzeugen
        Utilisateur user = new Utilisateur(
                "Testeur",
                "Conducteur",
                "conducteur.test@covoitgo.fr",
                "$2a$10$dummyHashPourTestDeSecurite12345678901234567890",
                "CONDUCTEUR"
        );
        user = utilisateurRepository.save(user);
        validToken = jwtService.generateToken(user);
    }

    // CAS NOMINAL (CODE 201 CREATED)

    @Test
    @DisplayName("Cas nominal (201) : Création valide d'un trajet et persistance en BDD")
    void testCreationValideTrajet() throws Exception {
        // Arrange : Gültiges DTO vorbereiten
        CreerTrajetRequete requete = new CreerTrajetRequete();
        requete.setDepart(new CoordonneesDto("Strasbourg", 48.5734, 7.7521));
        requete.setDestination(new CoordonneesDto("Colmar", 48.0794, 7.3585));
        requete.setHeureDepart(Instant.parse("2026-10-20T08:00:00Z"));
        requete.setCapacite(3);

        // Act (Phase 1) : Echter HTTP POST Request mit JWT Bearer Header & JSON-Body
        mockMvc.perform(post("/api/trajets")
                .header("Authorization", "Bearer " + validToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(requete)))
                .andExpect(status().isCreated());

        // Assert (Phase 2 - BDD) : Echte Prüfung in MongoDB
        List<Trajet> trajetsEnBdd = trajetRepository.findAll();
        assertEquals(1, trajetsEnBdd.size(), "Un seul trajet doit avoir été inséré en base");

        Trajet trajetInsere = trajetsEnBdd.get(0);
        assertEquals("Strasbourg", trajetInsere.getDepart().getLabel());
        assertEquals("Colmar", trajetInsere.getDestination().getLabel());
        assertEquals("ACTIF", trajetInsere.getStatut(), "Le statut initial doit être ACTIF");
        assertEquals(3, trajetInsere.getCapacite());
        assertEquals(3, trajetInsere.getPlacesDisponibles(),
                "Les places disponibles doivent égaler la capacité initiale");
    }

    // CAS D'ERREURS (CODE 400 ET 422)

    @Test
    @DisplayName("Cas d'erreur (400) : Champs obligatoires manquants (départ ou destination absents)")
    void testChampsObligatoiresManquantsRetourne400() throws Exception {
        // Fehlende Destination
        CreerTrajetRequete requete = new CreerTrajetRequete();
        requete.setDepart(new CoordonneesDto("Strasbourg", 48.5734, 7.7521));
        requete.setDestination(null); // Fehlt!
        requete.setHeureDepart(Instant.parse("2026-10-20T08:00:00Z"));
        requete.setCapacite(3);

        mockMvc.perform(post("/api/trajets")
                .header("Authorization", "Bearer " + validToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(requete)))
                .andExpect(status().isBadRequest());

        // Phase 2 : Sicherstellen, dass kein fehlerhafter Datensatz in MongoDB landet
        assertEquals(0, trajetRepository.count(), "Aucun trajet ne doit être persisté en cas d'erreur 400");
    }

    @Test
    @DisplayName("Cas d'erreur (400) : Heure de départ absente")
    void testHeureDepartAbsenteRetourne400() throws Exception {
        CreerTrajetRequete requete = new CreerTrajetRequete();
        requete.setDepart(new CoordonneesDto("Strasbourg", 48.5734, 7.7521));
        requete.setDestination(new CoordonneesDto("Colmar", 48.0794, 7.3585));
        requete.setHeureDepart(null); // Fehlt!
        requete.setCapacite(3);

        mockMvc.perform(post("/api/trajets")
                .header("Authorization", "Bearer " + validToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(requete)))
                .andExpect(status().isBadRequest());

        assertEquals(0, trajetRepository.count());
    }

    @Test
    @DisplayName("Cas d'erreur (422) : Capacité de véhicule invalide (capacite <= 0 ou > 8)")
    void testCapaciteInvalideRetourne422() throws Exception {
        // Test mit 0 Plätzen
        CreerTrajetRequete requeteZero = new CreerTrajetRequete();
        requeteZero.setDepart(new CoordonneesDto("Strasbourg", 48.5734, 7.7521));
        requeteZero.setDestination(new CoordonneesDto("Colmar", 48.0794, 7.3585));
        requeteZero.setHeureDepart(Instant.parse("2026-10-20T08:00:00Z"));
        requeteZero.setCapacite(0); // Ungültig

        mockMvc.perform(post("/api/trajets")
                .header("Authorization", "Bearer " + validToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(requeteZero)))
                .andExpect(status().isUnprocessableEntity());

        // Test mit 10 Plätzen (Maximal ist 8)
        CreerTrajetRequete requeteDix = new CreerTrajetRequete();
        requeteDix.setDepart(new CoordonneesDto("Strasbourg", 48.5734, 7.7521));
        requeteDix.setDestination(new CoordonneesDto("Colmar", 48.0794, 7.3585));
        requeteDix.setHeureDepart(Instant.parse("2026-10-20T08:00:00Z"));
        requeteDix.setCapacite(10); // Ungültig

        mockMvc.perform(post("/api/trajets")
                .header("Authorization", "Bearer " + validToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(requeteDix)))
                .andExpect(status().isUnprocessableEntity());

        assertEquals(0, trajetRepository.count(), "Aucun trajet avec capacité invalide ne doit être persisté");
    }

    // VALIDATION BDD & CYCLE DE VIE (CREATION -> RECHERCHE)

    @Test
    @DisplayName("Validation BDD : Visibilité immédiate après création (Création -> Recherche)")
    void testVisibiliteImmediateApresCreation() throws Exception {
        // 1. Fahrt anlegen via POST
        CreerTrajetRequete requete = new CreerTrajetRequete();
        requete.setDepart(new CoordonneesDto("Strasbourg", 48.5734, 7.7521));
        requete.setDestination(new CoordonneesDto("Colmar", 48.0794, 7.3585));
        requete.setHeureDepart(Instant.parse("2026-10-20T08:00:00Z"));
        requete.setCapacite(4);

        mockMvc.perform(post("/api/trajets")
                .header("Authorization", "Bearer " + validToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(requete)))
                .andExpect(status().isCreated());

        // 2. Sofortige Suche über die Recherche-API aufrufen
        mockMvc.perform(get("/api/trajets/recherche")
                .param("latitudeDepart", "48.5734")
                .param("longitudeDepart", "7.7521")
                .param("latitudeArrivee", "48.0794")
                .param("longitudeArrivee", "7.3585")
                .param("places", "1")
                .param("heureDepart", "2026-10-20T08:00:00Z"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].score").value(100.0))
                .andExpect(jsonPath("$[0].placesDisponibles").value(4));
    }
}
