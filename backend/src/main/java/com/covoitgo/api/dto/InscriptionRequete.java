package com.covoitgo.api.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * DTO für die Registrierungs-Anfrage (POST /api/auth/register).
 * Enthält Validierungsannotationen für Pflichtfelder.
 */
public class InscriptionRequete {

    @NotBlank(message = "Le nom est obligatoire")
    private String nom;

    @NotBlank(message = "Le prénom est obligatoire")
    private String prenom;

    @NotBlank(message = "L'adresse email est obligatoire")
    @Email(message = "Format d'email invalide")
    private String email;

    @NotBlank(message = "Le mot de passe est obligatoire")
    @Size(min = 6, message = "Le mot de passe doit comporter au moins 6 caractères")
    private String motDePasse;

    // Rolle: standardmäßig PASSAGER, kann auch CONDUCTEUR sein
    private String role = "PASSAGER";

    public InscriptionRequete() {}

    public InscriptionRequete(String nom, String prenom, String email, String motDePasse, String role) {
        this.nom = nom;
        this.prenom = prenom;
        this.email = email;
        this.motDePasse = motDePasse;
        this.role = (role != null && !role.isBlank()) ? role.toUpperCase() : "PASSAGER";
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
        this.role = (role != null && !role.isBlank()) ? role.toUpperCase() : "PASSAGER";
    }
}
