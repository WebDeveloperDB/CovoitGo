package com.covoitgo.api.repositories;

import com.covoitgo.api.models.DemandeTrajet;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

/**
 * REPOSITORY für die Mitfahranfragen (Demandes).
 * Genauso wie beim TrajetRepository nimmt uns Spring Boot hier 
 * die gesamte Arbeit für grundlegende Datenbank-Befehle (CRUD) ab.
 */
@Repository
public interface DemandeTrajetRepository extends MongoRepository<DemandeTrajet, String> {
    
    // Wir brauchen hier vorerst keine eigenen Suchmethoden.
    // Methoden wie save(), findById(), findAll() sind automatisch eingebaut!

}
