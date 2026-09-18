package com.covoitgo.api.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;

/**
 * Dieses DTO definiert, was der Client (Browser/App) an die API senden (als Input) muss, 
 * wenn ein Fahrer eine neue Fahrt erstellen möchte (US2).
 */
@Schema(description = "Informations requises pour la publication d'un nouveau trajet par un conducteur (US2)")
public class CreerTrajetRequete {

    @Schema(description = "Point de départ du trajet (coordonnées et nom du lieu)")
    private CoordonneesDto depart;

    @Schema(description = "Point d'arrivée du trajet (destination)")
    private CoordonneesDto destination;

    @Schema(description = "Date et heure prévues pour le départ (au format ISO-8601 UTC)", example = "2026-09-15T08:30:00Z")
    private Instant heureDepart;

    @Schema(description = "Capacité totale de transport (nombre de places disponibles pour les passagers)", example = "3")
    private int capacite;

    public CreerTrajetRequete() {
    }

    public CoordonneesDto getDepart() {
        return depart;
    }

    public void setDepart(CoordonneesDto depart) {
        this.depart = depart;
    }

    public CoordonneesDto getDestination() {
        return destination;
    }

    public void setDestination(CoordonneesDto destination) {
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
}
