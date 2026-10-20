package com.covoitgo.api;

import com.covoitgo.api.dto.ConnexionRequete;
import com.covoitgo.api.dto.InscriptionRequete;
import com.covoitgo.api.models.Utilisateur;
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
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.notNullValue;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * INTEGRATIONSTESTS FÜR DIE AUTHENTIFIZIERUNGS-API
 * 
 * Testet alle Akzeptanzkriterien:
 * - Registrierung mit BCrypt-Passworthash in MongoDB
 * - Token-Ausstellung mit Rolle (PASSAGER / CONDUCTEUR)
 * - Erfolgreicher Login
 * - HTTP 401 bei falschem Passwort oder unbekannter E-Mail
 * - HTTP 400 bei doppelter E-Mail oder ungültigen Eingaben
 */
@SpringBootTest
@AutoConfigureMockMvc
public class AuthIntegrationTest {

        @Autowired
        private MockMvc mockMvc;

        private final ObjectMapper objectMapper = new ObjectMapper().findAndRegisterModules();

        @Autowired
        private UtilisateurRepository utilisateurRepository;

        @Autowired
        private PasswordEncoder passwordEncoder;

        @Autowired
        private JwtService jwtService;

        @BeforeEach
        void preparerJeuDeDonnees() {
                // Bereinigt die MongoDB-Collection "utilisateurs" vor jedem Testlauf
                utilisateurRepository.deleteAll();
        }

        // 1. TESTS POUR L'INSCRIPTION (POST /api/auth/register)

        @Test
        @DisplayName("Cas nominal (201) : Inscription réussie, mot de passe haché par BCrypt et JWT généré")
        void testInscriptionNominale() throws Exception {
                // Arrange
                InscriptionRequete requete = new InscriptionRequete(
                                "Dupont",
                                "Jean",
                                "jean.dupont@covoitgo.fr",
                                "MonSuperMotDePasse123",
                                "PASSAGER");

                // Act & Assert HTTP
                mockMvc.perform(post("/api/auth/register")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(objectMapper.writeValueAsString(requete)))
                                .andExpect(status().isCreated())
                                .andExpect(jsonPath("$.token", notNullValue()))
                                .andExpect(jsonPath("$.type").value("Bearer"))
                                .andExpect(jsonPath("$.email").value("jean.dupont@covoitgo.fr"))
                                .andExpect(jsonPath("$.nom").value("Dupont"))
                                .andExpect(jsonPath("$.prenom").value("Jean"))
                                .andExpect(jsonPath("$.role").value("PASSAGER"));

                // Assert BDD MongoDB : Prüfen, dass das Passwort in der BDD sicher gehasht ist
                Utilisateur userEnBdd = utilisateurRepository.findByEmail("jean.dupont@covoitgo.fr").orElse(null);
                assertNotNull(userEnBdd, "L'utilisateur doit être persisté en base MongoDB");

                // Das Passwort darf NIEMALS im Klartext vorliegen!
                assertNotEquals("MonSuperMotDePasse123", userEnBdd.getMotDePasse());
                // BCrypt-Hashes beginnen immer mit $2a$ oder $2b$
                assertTrue(userEnBdd.getMotDePasse().startsWith("$2a$")
                                || userEnBdd.getMotDePasse().startsWith("$2b$"));
                // BCrypt-Matches prüft, ob der Hash mit dem Originalpasswort übereinstimmt
                assertTrue(passwordEncoder.matches("MonSuperMotDePasse123", userEnBdd.getMotDePasse()));
        }

        @Test
        @DisplayName("Cas d'erreur (400) : Inscription refusée si l'email existe déjà")
        void testInscriptionEmailDejaExistant() throws Exception {
                // Arrange : Ersten Benutzer anlegen
                InscriptionRequete requete1 = new InscriptionRequete(
                                "Martin",
                                "Sophie",
                                "sophie.martin@covoitgo.fr",
                                "password123",
                                "CONDUCTEUR");
                mockMvc.perform(post("/api/auth/register")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(objectMapper.writeValueAsString(requete1)))
                                .andExpect(status().isCreated());

                // Act & Assert : Zweite Registrierung mit derselben E-Mail versuchen
                InscriptionRequete requete2 = new InscriptionRequete(
                                "Autre",
                                "Personne",
                                "sophie.martin@covoitgo.fr",
                                "autrePassword123",
                                "PASSAGER");

                mockMvc.perform(post("/api/auth/register")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(objectMapper.writeValueAsString(requete2)))
                                .andExpect(status().isBadRequest())
                                .andExpect(jsonPath("$.erreur").value("Cet email est déjà utilisé"));
        }

        @Test
        @DisplayName("Cas d'erreur (400) : Mot de passe trop court (< 6 caractères)")
        void testInscriptionMotDePasseTropCourt() throws Exception {
                InscriptionRequete requete = new InscriptionRequete(
                                "Test",
                                "Court",
                                "court@test.fr",
                                "12345", // Nur 5 Zeichen
                                "PASSAGER");

                mockMvc.perform(post("/api/auth/register")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(objectMapper.writeValueAsString(requete)))
                                .andExpect(status().isBadRequest())
                                .andExpect(jsonPath("$.motDePasse")
                                                .value("Le mot de passe doit comporter au moins 6 caractères"));
        }

        // 2. TESTS POUR LA CONNEXION (POST /api/auth/login)

        @Test
        @DisplayName("Cas nominal (200) : Connexion réussie avec bons identifiants et token JWT valide")
        void testConnexionReussie() throws Exception {
                // Arrange : Benutzer anlegen
                InscriptionRequete register = new InscriptionRequete(
                                "Leblanc",
                                "Marc",
                                "marc.leblanc@covoitgo.fr",
                                "secretPassword456",
                                "CONDUCTEUR");
                mockMvc.perform(post("/api/auth/register")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(objectMapper.writeValueAsString(register)))
                                .andExpect(status().isCreated());

                // Act & Assert : Login ausführen
                ConnexionRequete login = new ConnexionRequete("marc.leblanc@covoitgo.fr", "secretPassword456");

                String reponseJson = mockMvc.perform(post("/api/auth/login")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(objectMapper.writeValueAsString(login)))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.token", notNullValue()))
                                .andExpect(jsonPath("$.email").value("marc.leblanc@covoitgo.fr"))
                                .andExpect(jsonPath("$.role").value("CONDUCTEUR"))
                                .andReturn().getResponse().getContentAsString();

                // Überprüfe das JWT-Token mit JwtService
                String token = objectMapper.readTree(reponseJson).get("token").asText();
                assertEquals("marc.leblanc@covoitgo.fr", jwtService.extractEmail(token));
                assertTrue(jwtService.isTokenValid(token, "marc.leblanc@covoitgo.fr"));
        }

        @Test
        @DisplayName("Cas d'erreur (401) : Connexion refusée avec mauvais mot de passe")
        void testConnexionMauvaisMotDePasse() throws Exception {
                // Arrange : Benutzer anlegen
                InscriptionRequete register = new InscriptionRequete(
                                "Leblanc",
                                "Marc",
                                "marc.leblanc@covoitgo.fr",
                                "secretPassword456",
                                "PASSAGER");
                mockMvc.perform(post("/api/auth/register")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(objectMapper.writeValueAsString(register)))
                                .andExpect(status().isCreated());

                // Act & Assert : Falsches Passwort eingeben
                ConnexionRequete loginFauxMdp = new ConnexionRequete("marc.leblanc@covoitgo.fr", "mauvaisMotDePasse");

                mockMvc.perform(post("/api/auth/login")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(objectMapper.writeValueAsString(loginFauxMdp)))
                                .andExpect(status().isUnauthorized())
                                .andExpect(jsonPath("$.erreur").value("Email ou mot de passe incorrect"));
        }

        @Test
        @DisplayName("Cas d'erreur (401) : Connexion refusée avec email inconnu")
        void testConnexionEmailInconnu() throws Exception {
                ConnexionRequete loginInconnu = new ConnexionRequete("inconnu@covoitgo.fr", "nimporteQuoi123");

                mockMvc.perform(post("/api/auth/login")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(objectMapper.writeValueAsString(loginInconnu)))
                                .andExpect(status().isUnauthorized())
                                .andExpect(jsonPath("$.erreur").value("Email ou mot de passe incorrect"));
        }
}
