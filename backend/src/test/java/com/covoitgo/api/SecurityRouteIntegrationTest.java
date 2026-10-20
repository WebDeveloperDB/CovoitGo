package com.covoitgo.api;

import com.covoitgo.api.dto.CoordonneesDto;
import com.covoitgo.api.dto.CreerTrajetRequete;
import com.covoitgo.api.models.Utilisateur;
import com.covoitgo.api.repositories.TrajetRepository;
import com.covoitgo.api.repositories.UtilisateurRepository;
import com.covoitgo.api.services.JwtService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Instant;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * INTEGRATIONSTESTS FÜR DIE ROUTEN-SICHERHEIT (Ticket FR403-886)
 * 
 * Überprüft die Kriterien aus Jira:
 * 1. Ungeschützte Anfragen auf geschützten Routen geben HTTP 401 zurück.
 * 2. Anfragen mit gefälschtem/ungültigem Token geben HTTP 401 zurück.
 * 3. Authentifizierte Anfragen mit gültigem Bearer-Token haben Zugriff auf geschützte Routen.
 * 4. Öffentliche Routen (z. B. Suche, Register, Login) bleiben ohne Token zugänglich.
 */
@SpringBootTest
@AutoConfigureMockMvc
public class SecurityRouteIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    private final ObjectMapper objectMapper = new ObjectMapper().findAndRegisterModules();

    @Autowired
    private UtilisateurRepository utilisateurRepository;

    @Autowired
    private TrajetRepository trajetRepository;

    @Autowired
    private JwtService jwtService;

    private String validToken;

    @BeforeEach
    void preparerDonnees() {
        trajetRepository.deleteAll();
        utilisateurRepository.deleteAll();

        // Test-Benutzer anlegen und echtes JWT-Token erzeugen
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

    // 1. TESTS D'ACCÈS REFUSÉ SANS TOKEN (HTTP 401)

    @Test
    @DisplayName("Sécurité (401) : Refus de création d'un trajet sans token Authorization")
    void testCreationTrajetSansTokenRefusee() throws Exception {
        CreerTrajetRequete requete = new CreerTrajetRequete();
        requete.setDepart(new CoordonneesDto("Strasbourg", 48.5734, 7.7521));
        requete.setDestination(new CoordonneesDto("Mulhouse", 47.7508, 7.3359));
        requete.setHeureDepart(Instant.parse("2026-10-25T10:00:00Z"));
        requete.setCapacite(3);

        // POST /api/trajets OHNE Authorization Header
        mockMvc.perform(post("/api/trajets")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requete)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.erreur").value("Non authentifié. Token JWT manquant ou invalide."));
    }

    @Test
    @DisplayName("Sécurité (401) : Refus d'accès à mes-trajets sans token")
    void testAccesMesTrajetsSansTokenRefuse() throws Exception {
        mockMvc.perform(get("/api/trajets/mes-trajets")
                        .param("idConducteur", "conducteur_001"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.erreur").value("Non authentifié. Token JWT manquant ou invalide."));
    }

    @Test
    @DisplayName("Sécurité (401) : Refus de création d'une demande de réservation sans token")
    void testCreationDemandeSansTokenRefusee() throws Exception {
        mockMvc.perform(post("/api/trajets/6ac4f5ffec2032127f4b5851/demandes")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"idPassager\":\"passager_001\",\"placesDemandees\":1}"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.erreur").value("Non authentifié. Token JWT manquant ou invalide."));
    }

    // 2. TESTS AVEC TOKEN INVALIDE OU CORROMPU (HTTP 401)

    @Test
    @DisplayName("Sécurité (401) : Refus avec un faux token JWT corrompu")
    void testAccesAvecFauxTokenRefuse() throws Exception {
        mockMvc.perform(get("/api/trajets/mes-trajets")
                        .header("Authorization", "Bearer fauxTokenTotalementInvalideEtCorrompu123")
                        .param("idConducteur", "conducteur_001"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.erreur").value("Non authentifié. Token JWT manquant ou invalide."));
    }

    // 3. TESTS D'ACCÈS AUTORISÉ AVEC TOKEN VALIDE (HTTP 200 / 201)

    @Test
    @DisplayName("Sécurité (201) : Création de trajet autorisée avec un token Bearer JWT valide")
    void testCreationTrajetAvecTokenValideAutorisee() throws Exception {
        CreerTrajetRequete requete = new CreerTrajetRequete();
        requete.setDepart(new CoordonneesDto("Strasbourg", 48.5734, 7.7521));
        requete.setDestination(new CoordonneesDto("Colmar", 48.0794, 7.3585));
        requete.setHeureDepart(Instant.parse("2026-10-25T14:00:00Z"));
        requete.setCapacite(2);

        // POST /api/trajets MIT Authorization Header
        mockMvc.perform(post("/api/trajets")
                        .header("Authorization", "Bearer " + validToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requete)))
                .andExpect(status().isCreated());
    }

    @Test
    @DisplayName("Sécurité (200) : Consultation de mes-trajets autorisée avec un token Bearer JWT valide")
    void testAccesMesTrajetsAvecTokenValideAutorise() throws Exception {
        mockMvc.perform(get("/api/trajets/mes-trajets")
                        .header("Authorization", "Bearer " + validToken)
                        .param("idConducteur", "conducteur.test@covoitgo.fr"))
                .andExpect(status().isOk());
    }

    // 4. TESTS DES ROUTES PUBLIQUES (ACCESSIBLE SANS TOKEN)

    @Test
    @DisplayName("Sécurité (Public) : Recherche de trajet accessible sans aucun token")
    void testRechercheTrajetAccessibleSansToken() throws Exception {
        mockMvc.perform(get("/api/trajets/recherche")
                        .param("latitudeDepart", "48.5734")
                        .param("longitudeDepart", "7.7521")
                        .param("latitudeArrivee", "47.7508")
                        .param("longitudeArrivee", "7.3359")
                        .param("heureDepart", "2026-10-25T09:00:00Z")
                        .param("places", "1"))
                .andExpect(status().isOk());
    }
}
