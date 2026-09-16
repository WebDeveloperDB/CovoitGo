package com.covoitgo.api.dto;

import io.swagger.v3.oas.annotations.media.Schema;

/**
 * DTO steht für "Data Transfer Object". 
 * Das ist eine reine "Transport-Kiste" für Daten. 
 * Wenn das Frontend (z.B. eine App) Daten an unsere API schickt oder empfängt, 
 * geben wir genau hier die Struktur (das JSON-Format) vor.
 * WICHTIG: Das ist NICHT die Datenbank-Tabelle (Entity). Es ist nur für die API!
 */
@Schema(description = "Repräsentiert geografische Koordinaten (Breitengrad und Längengrad)")
public class CoordonneesDto {

    // @Schema hilft Swagger, diese Variable auf der Webseite (Swagger-UI) mit einem Beispiel zu dokumentieren.
    @Schema(description = "Name der Stadt oder des Ortes", example = "Colmar")
    private String label;

    @Schema(description = "Breitengrad (Nord/Süd)", example = "48.0794")
    private double latitude;

    @Schema(description = "Längengrad (Ost/West)", example = "7.3585")
    private double longitude;

    // Leerer Konstruktor: Spring Boot braucht diesen zwingend, 
    // um diesen Objekt-Typ aus einem JSON-Text automatisch erstellen zu können.
    public CoordonneesDto() {
    }

    // Getters und Setters: In Java sind Variablen oft "private" (geschützt). 
    // Mit getLabel() und setLabel() kann man diese Variablen von außen sicher lesen und verändern.
    public String getLabel() {
        return label;
    }

    public void setLabel(String label) {
        this.label = label;
    }

    public double getLatitude() {
        return latitude;
    }

    public void setLatitude(double latitude) {
        this.latitude = latitude;
    }

    public double getLongitude() {
        return longitude;
    }

    public void setLongitude(double longitude) {
        this.longitude = longitude;
    }
}
