package com.covoitgo.api.dto;

/**
 * DTO für die Antwort nach erfolgreicher Authentifizierung (Login oder Register).
 * Gibt das JWT-Token und die wichtigsten Profilinformationen zurück.
 */
public class AuthReponse {

    // Das signierte JWT-Token
    private String token;

    // Token-Typ (Standard: "Bearer")
    private String type = "Bearer";

    private String id;
    private String email;
    private String nom;
    private String prenom;
    private String role;

    public AuthReponse() {}

    public AuthReponse(String token, String id, String email, String nom, String prenom, String role) {
        this.token = token;
        this.type = "Bearer";
        this.id = id;
        this.email = email;
        this.nom = nom;
        this.prenom = prenom;
        this.role = role;
    }

    public String getToken() {
        return token;
    }

    public void setToken(String token) {
        this.token = token;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
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

    public String getRole() {
        return role;
    }

    public void setRole(String role) {
        this.role = role;
    }
}
