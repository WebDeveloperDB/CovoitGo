package com.covoitgo.api.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;

/**
 * Dieses DTO definiert exakt, was die API als Antwort (Output) zurückgibt, 
 * wenn ein Passagier nach einer Fahrt sucht (US1).
 * Es ist das Endergebnis unseres Haversine-Algorithmus, fertig verpackt für das Frontend.
 */
@Schema(description = "Trajet compatible retourné suite à une recherche de passager avec calcul Haversine (US1)")
public class RechercheTrajetResultat {

    @Schema(description = "Identifiant unique du trajet dans la base MongoDB", example = "60f719...a3b2")
    private String idTrajet;

    @Schema(description = "Point de départ du conducteur (coordonnées et libellé)")
    private CoordonneesDto depart;

    @Schema(description = "Destination finale du conducteur (coordonnées et libellé)")
    private CoordonneesDto destination;

    @Schema(description = "Date et heure de départ prévues (au format ISO-8601 UTC)", example = "2026-09-15T08:30:00Z")
    private Instant heureDepart;

    @Schema(description = "Nombre de places encore disponibles dans le véhicule", example = "2")
    private int placesDisponibles;

    @Schema(description = "Score de pertinence calculé à partir de la distance Haversine (sur 100)", example = "92.5")
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
