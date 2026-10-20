package com.covoitgo.api.controllers;

import com.covoitgo.api.dto.AuthReponse;
import com.covoitgo.api.dto.ConnexionRequete;
import com.covoitgo.api.dto.InscriptionRequete;
import com.covoitgo.api.exceptions.EmailDejaUtiliseException;
import com.covoitgo.api.exceptions.MauvaisIdentifiantsException;
import com.covoitgo.api.services.AuthService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

/**
 * REST-CONTROLLER FÜR AUTHENTIFIZIERUNG
 * 
 * Stellt die Endpunkte für Benutzer-Registrierung und Login bereit.
 * Alle Benutzer-Passwörter werden via BCrypt gehasht, und bei erfolgreicher
 * Authentifizierung wird ein signiertes JWT-Token ausgestellt.
 */
@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*")
@Tag(name = "Authentification", description = "Endpoints d'inscription, de connexion et d'émission de jetons JWT")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    /**
     * Endpunkt zur Registrierung eines neuen Benutzers.
     * POST /api/auth/register
     */
    @Operation(summary = "Inscription d'un nouvel utilisateur", description = "Crée un nouveau compte (Passager ou Conducteur), hache le mot de passe avec BCrypt et renvoie un token JWT.")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "201", description = "Compte créé avec succès et token JWT généré"),
            @ApiResponse(responseCode = "400", description = "Données invalides ou email déjà utilisé")
    })
    @PostMapping("/register")
    public ResponseEntity<AuthReponse> register(@Valid @RequestBody InscriptionRequete requete) {
        AuthReponse reponse = authService.inscrire(requete);
        return ResponseEntity.status(HttpStatus.CREATED).body(reponse);
    }

    /**
     * Endpunkt zur Anmeldung eines bestehenden Benutzers.
     * POST /api/auth/login
     */
    @Operation(summary = "Connexion utilisateur", description = "Authentifie un utilisateur via son email et mot de passe et renvoie un token JWT.")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Authentification réussie, token JWT renvoyé"),
            @ApiResponse(responseCode = "401", description = "Email ou mot de passe incorrect"),
            @ApiResponse(responseCode = "400", description = "Champs obligatoires manquants ou invalides")
    })
    @PostMapping("/login")
    public ResponseEntity<AuthReponse> login(@Valid @RequestBody ConnexionRequete requete) {
        AuthReponse reponse = authService.connecter(requete);
        return ResponseEntity.ok(reponse);
    }

    // Behandlung von ungültigen Anmeldedaten (HTTP 401 Unauthorized)
    @ExceptionHandler(MauvaisIdentifiantsException.class)
    public ResponseEntity<Map<String, String>> handleMauvaisIdentifiants(MauvaisIdentifiantsException ex) {
        Map<String, String> erreur = new HashMap<>();
        erreur.put("erreur", ex.getMessage());
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(erreur);
    }

    // Behandlung von bereits vergebenen E-Mails (HTTP 400 Bad Request)
    @ExceptionHandler(EmailDejaUtiliseException.class)
    public ResponseEntity<Map<String, String>> handleEmailDejaUtilise(EmailDejaUtiliseException ex) {
        Map<String, String> erreur = new HashMap<>();
        erreur.put("erreur", ex.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(erreur);
    }

    // Behandlung von Validierungsfehlern (z. B. leere Felder, Passwort < 6 Zeichen)
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, String>> handleValidationExceptions(MethodArgumentNotValidException ex) {
        Map<String, String> erreurs = new HashMap<>();
        for (FieldError error : ex.getBindingResult().getFieldErrors()) {
            erreurs.put(error.getField(), error.getDefaultMessage());
        }
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(erreurs);
    }
}
