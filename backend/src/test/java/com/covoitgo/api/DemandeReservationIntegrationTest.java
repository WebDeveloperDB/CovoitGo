package com.covoitgo.api;

import com.covoitgo.api.dto.CreerDemandeRequete;
import com.covoitgo.api.dto.TraiterDemandeRequete;
import com.covoitgo.api.models.Coordonnees;
import com.covoitgo.api.models.DemandeTrajet;
import com.covoitgo.api.models.Trajet;
import com.covoitgo.api.repositories.DemandeTrajetRepository;
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

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.covoitgo.api.models.Utilisateur;
import com.covoitgo.api.repositories.UtilisateurRepository;
import com.covoitgo.api.services.JwtService;

/**
 * INTEGRATIONSTESTS OHNE MOCK FÜR US3 (Gérer une demande de covoiturage)
 * Entspricht Ticket FR403-856 und Confluence Seite 8.
 *
 * Testet den vollständigen Pfad:
 * Passagier bucht -> Fahrer akzeptiert/lehnt ab -> Atomare BDD-Plätzereduktion in MongoDB
 * Verwendet ein gültiges JWT Bearer Token für die geschützten Routen /api/trajets/{id}/demandes/**.
 */
@SpringBootTest
@AutoConfigureMockMvc
public class DemandeReservationIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    private final ObjectMapper objectMapper = new ObjectMapper().findAndRegisterModules();

    @Autowired
    private TrajetRepository trajetRepository;

    @Autowired
    private DemandeTrajetRepository demandeTrajetRepository;

    @Autowired
    private UtilisateurRepository utilisateurRepository;

    @Autowired
    private JwtService jwtService;

    private String validToken;

    private static final String TRAJET_TEST_ID = "6ac4f5ffec2032127f4b5891";
    private static final String DEMANDE_INITIALE_ID = "6ac4f5ffec2032127f4b5892";

    @BeforeEach
    void preparerJeuDeDonnees() {
        // Echte MongoDB-Collections bereinigen
        trajetRepository.deleteAll();
        demandeTrajetRepository.deleteAll();
        utilisateurRepository.deleteAll();

        // Test-Benutzer anlegen und echtes JWT-Token für autorisierte Tests erzeugen
        Utilisateur user = new Utilisateur(
                "Passager",
                "Test",
                "passager.test@covoitgo.fr",
                "$2a$10$dummyHashPourTestDeSecurite12345678901234567890",
                "PASSAGER"
        );
        user = utilisateurRepository.save(user);
        validToken = jwtService.generateToken(user);

        // 1. Trajet de test (2 places initiales disponibles)
        Trajet trajet = new Trajet();
        trajet.setId(TRAJET_TEST_ID);
        trajet.setIdConducteur("conducteur_001");
        trajet.setDepart(new Coordonnees("Strasbourg", 48.5734, 7.7521));
        trajet.setDestination(new Coordonnees("Mulhouse", 47.7508, 7.3359));
        trajet.setHeureDepart(Instant.parse("2026-10-25T14:00:00Z"));
        trajet.setCapacite(2);
        trajet.setPlacesDisponibles(2);
        trajet.setStatut("ACTIF");
        trajet.setCreeLe(Instant.now());
        trajet.setMisAJourLe(Instant.now());
        trajetRepository.save(trajet);

        // 2. Demande en attente initiale (pour les tests d'acceptation et refus)
        DemandeTrajet demande = new DemandeTrajet();
        demande.setId(DEMANDE_INITIALE_ID);
        demande.setIdTrajet(TRAJET_TEST_ID);
        demande.setIdPassager("passager_001");
        demande.setPlacesDemandees(1);
        demande.setStatut("PENDING");
        demande.setCreeLe(Instant.now());
        demande.setMisAJourLe(Instant.now());
        demandeTrajetRepository.save(demande);
    }

    // CREATION DE DEMANDE (PASSAGER)

    @Test
    @DisplayName("Cas nominal (201) : Création d'une nouvelle demande par un passager")
    void testCreationDemandeNominale() throws Exception {
        CreerDemandeRequete requete = new CreerDemandeRequete();
        requete.setIdPassager("passager_002");
        requete.setPlacesDemandees(1);

        mockMvc.perform(post("/api/trajets/" + TRAJET_TEST_ID + "/demandes")
                .header("Authorization", "Bearer " + validToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(requete)))
                .andExpect(status().isCreated());

        // Validation BDD
        List<DemandeTrajet> demandes = demandeTrajetRepository.findByIdTrajetAndIdPassager(TRAJET_TEST_ID,
                "passager_002");
        assertEquals(1, demandes.size());
        assertEquals("PENDING", demandes.get(0).getStatut());
        assertEquals(1, demandes.get(0).getPlacesDemandees());
    }

    @Test
    @DisplayName("Cas d'erreur (404) : Demande sur un trajet inexistant")
    void testDemandeTrajetInexistantRetourne404() throws Exception {
        CreerDemandeRequete requete = new CreerDemandeRequete();
        requete.setIdPassager("passager_002");
        requete.setPlacesDemandees(1);

        mockMvc.perform(post("/api/trajets/faux_id_inconnu/demandes")
                .header("Authorization", "Bearer " + validToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(requete)))
                .andExpect(status().isNotFound());
    }

    @Test
    @DisplayName("Cas de conflit (409) : Nombre de places insuffisant pour la demande")
    void testDemandeSurcapaciteRetourne409() throws Exception {
        CreerDemandeRequete requete = new CreerDemandeRequete();
        requete.setIdPassager("passager_003");
        requete.setPlacesDemandees(5); // Seulement 2 places libres !

        mockMvc.perform(post("/api/trajets/" + TRAJET_TEST_ID + "/demandes")
                .header("Authorization", "Bearer " + validToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(requete)))
                .andExpect(status().isConflict());
    }

    @Test
    @DisplayName("Cas de conflit (409) : Double réservation par le même passager refusée")
    void testDoubleReservationMemePassagerRetourne409() throws Exception {
        // passager_001 a déjà une demande PENDING dans le @BeforeEach
        CreerDemandeRequete requete = new CreerDemandeRequete();
        requete.setIdPassager("passager_001");
        requete.setPlacesDemandees(1);

        mockMvc.perform(post("/api/trajets/" + TRAJET_TEST_ID + "/demandes")
                .header("Authorization", "Bearer " + validToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(requete)))
                .andExpect(status().isConflict());

        // Validation BDD : Une seule demande doit toujours exister pour ce passager
        List<DemandeTrajet> demandes = demandeTrajetRepository.findByIdTrajetAndIdPassager(TRAJET_TEST_ID,
                "passager_001");
        assertEquals(1, demandes.size(), "Le passager ne doit pas pouvoir dupliquer sa demande");
    }

    // TRAITEMENT PAR LE CONDUCTEUR (ACCEPTER / REFUSER)

    @Test
    @DisplayName("Cas nominal (200) : Acceptation de la demande par le conducteur et décrémentation des places")
    void testAcceptationDemandeParConducteur() throws Exception {
        TraiterDemandeRequete decision = new TraiterDemandeRequete();
        decision.setStatut("ACCEPTE");
        decision.setRaison("Bienvenue à bord !");

        mockMvc.perform(patch("/api/trajets/" + TRAJET_TEST_ID + "/demandes/" + DEMANDE_INITIALE_ID)
                .header("Authorization", "Bearer " + validToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(decision)))
                .andExpect(status().isOk());

        // Validation BDD en 2 points clés :
        // 1. Statut de la demande devient ACCEPTE
        DemandeTrajet demandeMaj = demandeTrajetRepository.findById(DEMANDE_INITIALE_ID).orElseThrow();
        assertEquals("ACCEPTE", demandeMaj.getStatut());

        // 2. Places disponibles du trajet décrémentées de 2 à 1
        Trajet trajetMaj = trajetRepository.findById(TRAJET_TEST_ID).orElseThrow();
        assertEquals(1, trajetMaj.getPlacesDisponibles(), "Les places doivent diminuer de 1 après acceptation");
        assertEquals("ACTIF", trajetMaj.getStatut());
    }

    @Test
    @DisplayName("Cas nominal (200) : Refus de la demande par le conducteur (places inchangées)")
    void testRefusDemandeParConducteur() throws Exception {
        TraiterDemandeRequete decision = new TraiterDemandeRequete();
        decision.setStatut("REFUSE");
        decision.setRaison("Désolé, horaires incompatibles.");

        mockMvc.perform(patch("/api/trajets/" + TRAJET_TEST_ID + "/demandes/" + DEMANDE_INITIALE_ID)
                .header("Authorization", "Bearer " + validToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(decision)))
                .andExpect(status().isOk());

        // Validation BDD :
        DemandeTrajet demandeMaj = demandeTrajetRepository.findById(DEMANDE_INITIALE_ID).orElseThrow();
        assertEquals("REFUSE", demandeMaj.getStatut());

        // Les places du trajet restent intactes à 2
        Trajet trajetMaj = trajetRepository.findById(TRAJET_TEST_ID).orElseThrow();
        assertEquals(2, trajetMaj.getPlacesDisponibles(), "Les places ne doivent pas changer en cas de refus");
    }

    @Test
    @DisplayName("Cas nominal (200) : Trajet devient COMPLET lorsque toutes les places sont réservées")
    void testTrajetDevientCompletSiZeroPlacesRestantes() throws Exception {
        // Demande de 2 places
        DemandeTrajet demandeDeuxPlaces = new DemandeTrajet();
        demandeDeuxPlaces.setId("demande_complete_002");
        demandeDeuxPlaces.setIdTrajet(TRAJET_TEST_ID);
        demandeDeuxPlaces.setIdPassager("passager_famille");
        demandeDeuxPlaces.setPlacesDemandees(2);
        demandeDeuxPlaces.setStatut("PENDING");
        demandeDeuxPlaces.setCreeLe(Instant.now());
        demandeTrajetRepository.save(demandeDeuxPlaces);

        TraiterDemandeRequete decision = new TraiterDemandeRequete();
        decision.setStatut("ACCEPTE");

        mockMvc.perform(patch("/api/trajets/" + TRAJET_TEST_ID + "/demandes/demande_complete_002")
                .header("Authorization", "Bearer " + validToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(decision)))
                .andExpect(status().isOk());

        // Validation BDD : Le trajet doit avoir 0 places et statut COMPLET
        Trajet trajetMaj = trajetRepository.findById(TRAJET_TEST_ID).orElseThrow();
        assertEquals(0, trajetMaj.getPlacesDisponibles());
        assertEquals("COMPLET", trajetMaj.getStatut(), "Le trajet sans places restantes doit passer au statut COMPLET");
    }
}
