package com.covoitgo.api.repositories;

import com.covoitgo.api.models.Utilisateur;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

/**
 * Spring Data MongoDB Repository für Benutzerkonten.
 * Ermöglicht das Suchen und Überprüfen von E-Mails direkt in der Collection "utilisateurs".
 */
@Repository
public interface UtilisateurRepository extends MongoRepository<Utilisateur, String> {

    // Sucht einen Benutzer anhand seiner E-Mail-Adresse (für den Login)
    Optional<Utilisateur> findByEmail(String email);

    // Prüft, ob eine E-Mail-Adresse bereits vergeben ist (für die Registrierung)
    boolean existsByEmail(String email);
}
