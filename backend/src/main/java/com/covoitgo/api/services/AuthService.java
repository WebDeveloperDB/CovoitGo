package com.covoitgo.api.services;

import com.covoitgo.api.dto.AuthReponse;
import com.covoitgo.api.dto.ConnexionRequete;
import com.covoitgo.api.dto.InscriptionRequete;
import com.covoitgo.api.exceptions.EmailDejaUtiliseException;
import com.covoitgo.api.exceptions.MauvaisIdentifiantsException;
import com.covoitgo.api.models.Utilisateur;
import com.covoitgo.api.repositories.UtilisateurRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Optional;

/**
 * Service für Benutzerauthentifizierung.
 * Übernimmt die Registrierung mit BCrypt-Hashing und den Login mit JWT-Token-Ausstellung.
 */
@Service
public class AuthService {

    private final UtilisateurRepository utilisateurRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public AuthService(UtilisateurRepository utilisateurRepository,
                       PasswordEncoder passwordEncoder,
                       JwtService jwtService) {
        this.utilisateurRepository = utilisateurRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
    }

    /**
     * Registriert einen neuen Benutzer.
     * 1. Prüft, ob die E-Mail bereits existiert.
     * 2. Hasht das Passwort mit BCrypt (Salt + Hash).
     * 3. Speichert den Benutzer in MongoDB.
     * 4. Erstellt ein signiertes JWT-Token und gibt die Antwort zurück.
     */
    public AuthReponse inscrire(InscriptionRequete requete) {
        String emailNormalisee = requete.getEmail().trim().toLowerCase();

        if (utilisateurRepository.existsByEmail(emailNormalisee)) {
            throw new EmailDejaUtiliseException("Cet email est déjà utilisé");
        }

        // Passwort sicher mit BCrypt hashen
        String motDePasseHache = passwordEncoder.encode(requete.getMotDePasse());

        // Benutzer-Objekt erstellen
        Utilisateur utilisateur = new Utilisateur(
                requete.getNom().trim(),
                requete.getPrenom().trim(),
                emailNormalisee,
                motDePasseHache,
                requete.getRole()
        );

        // In MongoDB speichern
        Utilisateur utilisateurEnregistre = utilisateurRepository.save(utilisateur);

        // JWT-Token generieren
        String token = jwtService.generateToken(utilisateurEnregistre);

        return new AuthReponse(
                token,
                utilisateurEnregistre.getId(),
                utilisateurEnregistre.getEmail(),
                utilisateurEnregistre.getNom(),
                utilisateurEnregistre.getPrenom(),
                utilisateurEnregistre.getRole()
        );
    }

    /**
     * Authentifiziert einen Benutzer anhand von E-Mail und Passwort.
     * 1. Sucht den Benutzer in MongoDB.
     * 2. Prüft das Passwort mit BCrypt (matches).
     * 3. Wirft MauvaisIdentifiantsException (HTTP 401), wenn E-Mail unbekannt oder Passwort falsch.
     * 4. Erstellt bei Erfolg ein signiertes JWT-Token.
     */
    public AuthReponse connecter(ConnexionRequete requete) {
        String emailNormalisee = requete.getEmail().trim().toLowerCase();

        Optional<Utilisateur> optUtilisateur = utilisateurRepository.findByEmail(emailNormalisee);
        if (optUtilisateur.isEmpty()) {
            throw new MauvaisIdentifiantsException("Email ou mot de passe incorrect");
        }

        Utilisateur utilisateur = optUtilisateur.get();

        // Überprüft, ob das eingegebene Klartext-Passwort zum gespeicherten BCrypt-Hash passt
        if (!passwordEncoder.matches(requete.getMotDePasse(), utilisateur.getMotDePasse())) {
            throw new MauvaisIdentifiantsException("Email ou mot de passe incorrect");
        }

        // JWT-Token generieren
        String token = jwtService.generateToken(utilisateur);

        return new AuthReponse(
                token,
                utilisateur.getId(),
                utilisateur.getEmail(),
                utilisateur.getNom(),
                utilisateur.getPrenom(),
                utilisateur.getRole()
        );
    }
}
