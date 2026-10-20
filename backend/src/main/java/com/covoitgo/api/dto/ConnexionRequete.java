package com.covoitgo.api.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

/**
 * DTO für die Anmelde-Anfrage (POST /api/auth/login).
 */
public class ConnexionRequete {

    @NotBlank(message = "L'adresse email est obligatoire")
    @Email(message = "Format d'email invalide")
    private String email;

    @NotBlank(message = "Le mot de passe est obligatoire")
    private String motDePasse;

    public ConnexionRequete() {}

    public ConnexionRequete(String email, String motDePasse) {
        this.email = email;
        this.motDePasse = motDePasse;
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
}
