package com.covoitgo.api.repositories;

import com.covoitgo.api.models.Trajet;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * REPOSITORY: Das ist die magische Schnittstelle zu MongoDB.
 * 
 * In Java / Spring Boot schreiben wir keine langen SQL- oder NoSQL-Queries per Hand.
 * Wir erstellen einfach ein Interface, das von "MongoRepository" erbt.
 * Spring Boot programmiert den ganzen Datenbank-Code (Speichern, Löschen, Suchen) 
 * automatisch für uns im Hintergrund!
 * 
 * "Trajet" = Die Entity-Klasse, die gespeichert wird.
 * "String" = Der Datentyp der ID (unser Primärschlüssel in Trajet.java).
 */
@Repository // Zeigt Spring Boot, dass dies eine Datenbank-Komponente ist.
public interface TrajetRepository extends MongoRepository<Trajet, String> {

    /**
     * Eigene Such-Methode:
     * Spring Boot versteht diesen Namen automatisch!
     * Weil die Methode "findByStatut" heißt, schreibt Spring Boot automatisch 
     * eine MongoDB-Query, die nach dem Feld "statut" in der Collection sucht.
     * Wir müssen absolut keinen Code dafür schreiben!
     */
    List<Trajet> findByStatut(String statut);

}
