package com.covoitgo.api.dto;

import io.swagger.v3.oas.annotations.media.Schema;

/**
 * Dieses DTO definiert, was der Client an die API senden muss,
 * wenn der Fahrer eine Mitfahranfrage akzeptiert oder ablehnt (US3).
 */
@Schema(description = "Die Entscheidung des Fahrers über eine Mitfahranfrage (US3)")
public class TraiterDemandeRequete {

    @Schema(description = "Die Entscheidung: 'ACCEPTED' (Akzeptiert) oder 'REFUSED' (Abgelehnt)", example = "ACCEPTED")
    private String statut;

    @Schema(description = "Der Grund für die Entscheidung (Pflichtfeld bei einer Ablehnung)", example = "Je n'ai plus de place pour les bagages")
    private String raison;

    public TraiterDemandeRequete() {
    }

    public String getStatut() {
        return statut;
    }

    public void setStatut(String statut) {
        this.statut = statut;
    }

    public String getRaison() {
        return raison;
    }

    public void setRaison(String raison) {
        this.raison = raison;
    }
}
