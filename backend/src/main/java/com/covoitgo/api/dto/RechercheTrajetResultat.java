package com.covoitgo.api.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;

/**
 * Dieses DTO definiert exakt, was die API als Antwort (Output) zurückgibt, 
 * wenn ein Passagier nach einer Fahrt sucht (US1).
 * Es ist das Endergebnis unseres Haversine-Algorithmus, fertig verpackt für das Frontend.
 */
@Schema(description = "Eine kompatible Fahrt, die bei einer Suche zurückgegeben wird (US1)")
public class RechercheTrajetResultat {

    @Schema(description = "Die eindeutige ID der Fahrt aus der Datenbank", example = "60f719...a3b2")
    private String idTrajet;

    @Schema(description = "Der Startpunkt des Fahrers (enthält Koordinaten und Name)")
    private CoordonneesDto depart;

    @Schema(description = "Das Ziel des Fahrers")
    private CoordonneesDto destination;

    @Schema(description = "Geplantes Abfahrtsdatum und -uhrzeit (im ISO-8601 Format)", example = "2026-09-15T08:30:00Z")
    private Instant heureDepart;

    @Schema(description = "Anzahl der noch freien Plätze im Auto", example = "2")
    private int placesDisponibles;

    @Schema(description = "Der Berechnete Relevanz-Score (basierend auf der Haversine-Distanz)", example = "92.5")
    private double score;

    public RechercheTrajetResultat() {
    }

    public String getIdTrajet() {
        return idTrajet;
    }

    public void setIdTrajet(String idTrajet) {
        this.idTrajet = idTrajet;
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

    public int getPlacesDisponibles() {
        return placesDisponibles;
    }

    public void setPlacesDisponibles(int placesDisponibles) {
        this.placesDisponibles = placesDisponibles;
    }

    public double getScore() {
        return score;
    }

    public void setScore(double score) {
        this.score = score;
    }
}
