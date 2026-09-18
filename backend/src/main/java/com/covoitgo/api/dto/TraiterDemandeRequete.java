package com.covoitgo.api.dto;

import io.swagger.v3.oas.annotations.media.Schema;

/**
 * Dieses DTO definiert, was der Client an die API senden muss,
 * wenn der Fahrer eine Mitfahranfrage akzeptiert oder ablehnt (US3).
 */
@Schema(description = "Décision du conducteur concernant une demande de réservation (US3)")
public class TraiterDemandeRequete {

    @Schema(description = "Décision prise par le conducteur : 'ACCEPTE' ou 'REFUSE'", example = "ACCEPTE")
    private String statut;

    @Schema(description = "Motif en cas de refus (obligatoire si la demande est refusée)", example = "Je n'ai plus de place pour les bagages")
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
