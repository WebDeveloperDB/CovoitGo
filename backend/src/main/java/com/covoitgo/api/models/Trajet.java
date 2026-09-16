package com.covoitgo.api.models;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import java.time.Instant;

/**
 * ENTITY: Das ist eine Datenbank-Tabelle (in MongoDB nennt man das "Collection").
 * Diese Klasse ist NICHT für das Frontend gedacht, sondern nur für die Datenbank.
 * 
 * @Document(collection = "trajets") sagt MongoDB: "Speichere alle Objekte dieser Klasse 
 * in einem Ordner (Collection), der 'trajets' heißt."
 */
@Document(collection = "trajets")
public class Trajet {

    // @Id sagt Spring Data, dass dies der Primärschlüssel (die eindeutige ID) in MongoDB ist (wird meistens _id genannt)
    @Id
    private String id;

    // Die ID des Fahrers, der diese Fahrt erstellt hat
    private String idConducteur;

    // Der Startpunkt der Fahrt (benutzt unsere neue Hilfsklasse Coordonnees)
    private Coordonnees depart;

    // Das Ziel der Fahrt
    private Coordonnees destination;

    // Wann die Fahrt stattfindet
    private Instant heureDepart;

    // Wie viele Plätze das Auto insgesamt hat (z.B. 4)
    private int capacite;

    // Wie viele Plätze im Moment noch frei sind (wird weniger, wenn Anfragen akzeptiert werden)
    private int placesDisponibles;

    // Der aktuelle Status der Fahrt (z.B. "ACTIF" für aktiv, "COMPLET" für voll, "ANNULÉ" für storniert)
    private String statut;

    // Wann dieser Datenbank-Eintrag erstellt wurde
    private Instant creeLe;

    // Wann dieser Eintrag zuletzt verändert wurde
    private Instant misAJourLe;

    // Leerer Konstruktor für MongoDB
    public Trajet() {
    }

    // ==========================================
    // GETTERS UND SETTERS
    // ==========================================

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getIdConducteur() {
        return idConducteur;
    }

    public void setIdConducteur(String idConducteur) {
        this.idConducteur = idConducteur;
    }

    public Coordonnees getDepart() {
        return depart;
    }

    public void setDepart(Coordonnees depart) {
        this.depart = depart;
    }

    public Coordonnees getDestination() {
        return destination;
    }

    public void setDestination(Coordonnees destination) {
        this.destination = destination;
    }

    public Instant getHeureDepart() {
        return heureDepart;
    }

    public void setHeureDepart(Instant heureDepart) {
        this.heureDepart = heureDepart;
    }

    public int getCapacite() {
        return capacite;
    }

    public void setCapacite(int capacite) {
        this.capacite = capacite;
    }

    public int getPlacesDisponibles() {
        return placesDisponibles;
    }

    public void setPlacesDisponibles(int placesDisponibles) {
        this.placesDisponibles = placesDisponibles;
    }

    public String getStatut() {
        return statut;
    }

    public void setStatut(String statut) {
        this.statut = statut;
    }

    public Instant getCreeLe() {
        return creeLe;
    }

    public void setCreeLe(Instant creeLe) {
        this.creeLe = creeLe;
    }

    public Instant getMisAJourLe() {
        return misAJourLe;
    }

    public void setMisAJourLe(Instant misAJourLe) {
        this.misAJourLe = misAJourLe;
    }
}
