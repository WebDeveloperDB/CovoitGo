package com.covoitgo.api.repositories;

import com.covoitgo.api.models.DemandeTrajet;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

/**
 * REPOSITORY für die Mitfahranfragen (Demandes).
 * Genauso wie beim TrajetRepository nimmt uns Spring Boot hier 
 * die gesamte Arbeit für grundlegende Datenbank-Befehle (CRUD) ab.
 */
@Repository
public interface DemandeTrajetRepository extends MongoRepository<DemandeTrajet, String> {
    
    // Find all requests for a specific trip
    List<DemandeTrajet> findByIdTrajet(String idTrajet);
    
    // Find requests for a specific trip by their status
    List<DemandeTrajet> findByIdTrajetAndStatut(String idTrajet, String statut);

}
