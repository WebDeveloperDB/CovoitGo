package com.covoitgo.api.models;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.Instant;

/**
 * Modellklasse für einen Benutzer (Passager oder Conducteur).
 * Entspricht dem Dokument in der MongoDB-Collection "utilisateurs".
 */
@Document(collection = "utilisateurs")
public class Utilisateur {

    @Id
    private String id;

    private String nom;
    private String prenom;

    // E-Mail-Adresse ist eindeutig (unique index)
    @Indexed(unique = true)
    private String email;

    // Gespeichert wird hier NIEMALS das Klartext-Passwort, sondern der BCrypt-Hash!
    private String motDePasse;

    // Hauptrolle: "PASSAGER" oder "CONDUCTEUR"
    private String role;

    // Zeitstempel der Registrierung
    private Instant dateCreation;

    // Standard-Konstruktor für Spring Data / Jackson
    public Utilisateur() {
        this.dateCreation = Instant.now();
    }

    public Utilisateur(String nom, String prenom, String email, String motDePasse, String role) {
        this.nom = nom;
        this.prenom = prenom;
        this.email = email;
        this.motDePasse = motDePasse;
        this.role = role;
        this.dateCreation = Instant.now();
    }

    // Getter und Setter
    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getNom() {
        return nom;
    }

    public void setNom(String nom) {
        this.nom = nom;
    }

    public String getPrenom() {
        return prenom;
    }

    public void setPrenom(String prenom) {
        this.prenom = prenom;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getMotDePasse() {
        return motDePasse;
    }

    public void setMotDePasse(String motDePasse) {
        this.motDePasse = motDePasse;
    }

    public String getRole() {
        return role;
    }

    public void setRole(String role) {
        this.role = role;
    }

    public Instant getDateCreation() {
        return dateCreation;
    }

    public void setDateCreation(Instant dateCreation) {
        this.dateCreation = dateCreation;
    }
}
