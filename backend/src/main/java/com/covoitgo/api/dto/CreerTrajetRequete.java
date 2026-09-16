package com.covoitgo.api.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;

/**
 * Dieses DTO definiert, was der Client (Browser/App) an die API senden (als Input) muss, 
 * wenn ein Fahrer eine neue Fahrt erstellen möchte (US2).
 */
@Schema(description = "Die notwendigen Informationen, um eine neue Fahrt zu erstellen (US2)")
public class CreerTrajetRequete {

    @Schema(description = "Der Startpunkt (wo die Fahrt beginnt)")
    private CoordonneesDto depart;

    @Schema(description = "Das Ziel der Fahrt")
    private CoordonneesDto destination;

    @Schema(description = "Geplantes Abfahrtsdatum und -uhrzeit", example = "2026-09-15T08:30:00Z")
    private Instant heureDepart;

    @Schema(description = "Die Gesamtkapazität (wie viele Personen maximal mitfahren können)", example = "3")
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
