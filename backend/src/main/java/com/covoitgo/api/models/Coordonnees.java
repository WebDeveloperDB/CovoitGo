package com.covoitgo.api.models;

/**
 * Das ist eine Hilfsklasse für unsere Datenbank-Entity (Trajet).
 * Sie speichert die GPS-Daten in der MongoDB.
 * Im Gegensatz zum DTO hat diese Klasse keine Swagger-Annotationen (@Schema),
 * weil sie nicht direkt ins Internet geschickt wird.
 */
public class Coordonnees {

    // Der Name des Ortes
    private String label;

    // Der Breitengrad
    private double latitude;

    // Der Längengrad
    private double longitude;

    // Leerer Konstruktor für Spring Data MongoDB (wird benötigt, um Daten aus der
    // DB zu lesen)
    public Coordonnees() {
    }

    // Getters und Setters, damit MongoDB die Werte speichern und lesen kann
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
