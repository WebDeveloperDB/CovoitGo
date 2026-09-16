package com.covoitgo.api.models;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import java.time.Instant;

/**
 * ENTITY: Das ist unsere zweite Datenbank-Tabelle (Collection) in MongoDB.
 * Hier speichern wir die Anfragen der Passagiere, wenn sie bei einer Fahrt mitfahren wollen.
 * 
 * @Document(collection = "demandes") bedeutet, dass diese Objekte in MongoDB
 * in der Collection "demandes" gespeichert werden.
 */
@Document(collection = "demandes")
public class DemandeTrajet {

    // Die eindeutige ID der Anfrage in MongoDB
    @Id
    private String id;

    // Zu welcher Fahrt (Trajet) gehört diese Anfrage? (Fremdschlüssel-artig)
    private String idTrajet;

    // Welcher Passagier hat diese Anfrage gestellt?
    private String idPassager;

    // Wie viele Plätze möchte der Passagier buchen?
    private int placesDemandees;

    // Status der Anfrage: z.B. "EN_ATTENTE" (Wartend), "ACCEPTÉ" (Akzeptiert), "REFUSÉ" (Abgelehnt)
    private String statut;

    // Wenn der Fahrer ablehnt, kann er hier den Grund eintragen
    private String raison;

    // Wann hat der Fahrer die Entscheidung getroffen?
    private Instant decideLe;

    // Wann wurde die Anfrage vom Passagier gestellt?
    private Instant creeLe;

    // Wann wurde der Datensatz zuletzt geändert?
    private Instant misAJourLe;

    // Leerer Konstruktor für MongoDB
    public DemandeTrajet() {
    }

    // ==========================================
    // GETTERS UND SETTERS
    // ==========================================

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getIdTrajet() {
        return idTrajet;
    }

    public void setIdTrajet(String idTrajet) {
        this.idTrajet = idTrajet;
    }

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

    public Instant getDecideLe() {
        return decideLe;
    }

    public void setDecideLe(Instant decideLe) {
        this.decideLe = decideLe;
    }

    public Instant getCreeLe() {
        return creeLe;
    }

    public void setCreeLe(Instant creeLe) {
        this.creeLe = creeLe;
    }

    public Instant getMisAJourLe() {
        return misAJourLe;
    }

    public void setMisAJourLe(Instant misAJourLe) {
        this.misAJourLe = misAJourLe;
    }
}
