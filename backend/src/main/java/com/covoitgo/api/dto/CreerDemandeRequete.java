package com.covoitgo.api.dto;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(description = "Requête pour créer une demande de réservation")
public class CreerDemandeRequete {

    @Schema(description = "ID du passager qui fait la demande", example = "pass-001")
    private String idPassager;

    @Schema(description = "Nombre de places souhaitées", example = "1")
    private int placesDemandees;

    public String getIdPassager() {
        return idPassager;
    }

    public void setIdPassager(String idPassager) {
        this.idPassager = idPassager;
    }

    public int getPlacesDemandees() {
        return placesDemandees;
    }

    public void setPlacesDemandees(int placesDemandees) {
        this.placesDemandees = placesDemandees;
    }
}
