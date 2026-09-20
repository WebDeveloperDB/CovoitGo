# Den Code von TrajetService.java verstehen (Leitfaden für die mündliche Prüfung)

Dieser Leitfaden wurde speziell für dich geschrieben, um dir zu helfen, die Logik und die Java-Syntax in unserer Datei `TrajetService.java` zu verstehen. Das Ziel ist es, dass du es dem Dozenten mit deinen eigenen Worten erklären kannst.

---

## 1. Objektorientierung: Woher kommen die Objekte?

In Java (wie in vielen objektorientierten Sprachen) ist alles ein **Objekt**. Ein Objekt ist wie eine "Kiste", die Daten (Variablen) und mögliche Aktionen (Funktionen/Methoden) enthält.

**Die Architektur unseres Codes:**
1. **Frontend / Swagger**: Sendet eine HTTP-Anfrage (JSON-Text).
2. **Controller (`TrajetController.java`)**: Er ist der "Empfangschef". Er nimmt das JSON, wandelt es (dank Spring Boot) in ein Java-Objekt um und gibt es an den Service weiter.
3. **Service (`TrajetService.java`)**: Er ist das "Gehirn". Hier werden die mathematischen Berechnungen (Haversine) durchgeführt und die Geschäftsregeln (Logik) angewendet.
4. **Repository (`TrajetRepository.java`)**: Es ist der "Bibliothekar". Seine einzige Aufgabe ist es, mit MongoDB zu sprechen, um Objekte zu speichern oder abzurufen.

---

## 2. Entschlüsselung von TrajetService.java

### Dependency Injection / Abhängigkeitsinjektion (Der Konstruktor)

Schau dir diesen Code-Abschnitt am Anfang der Datei an:
```java
@Service
public class TrajetService {
    private final TrajetRepository trajetRepository;

    public TrajetService(TrajetRepository trajetRepository) {
        this.trajetRepository = trajetRepository;
    }
    // ...
}
```
**Wie erklärst du das?**
> "Die Klasse `TrajetService` muss auf die Datenbank zugreifen. Anstatt die Verbindung selbst herzustellen, nutzen wir die **Dependency Injection** (Abhängigkeitsinjektion). Das Spring Boot Framework erstellt automatisch ein `TrajetRepository`-Objekt (unseren Bibliothekar) und übergibt (injiziert) es dem `TrajetService` über seinen Konstruktor (`public TrajetService(...)`). Von dort kommt dieses Objekt!"

### Der Such-Algorithmus (`rechercherTrajets`)

Dies ist die Hauptfunktion. Hier ist ihr Ablauf Schritt für Schritt:

**1. Daten aus der Datenbank abrufen:**
```java
List<Trajet> tousLesTrajets = trajetRepository.findByStatus(RideStatus.ACTIVE);
```
> "Wir bitten das Repository, in MongoDB nach allen Fahrten zu suchen, die den Status `ACTIVE` haben. Das gibt uns eine `List` (eine Liste) von `Trajet`-Objekten zurück."

**2. Eine leere Liste für die Ergebnisse vorbereiten:**
```java
List<RechercheTrajetResultat> resultats = new ArrayList<>();
```
> "Wir erstellen eine neue, leere Liste (`new ArrayList<>()`). Diese Liste wird nur die Fahrten enthalten, die unseren Test bestanden haben (die kompatiblen Fahrten). Das Wort `new` in Java wird genau dafür verwendet: um ein neues, leeres Objekt zu erstellen."

**3. Die `for-each`-Schleife (Der Kompatibilitätstest):**
```java
for (Trajet trajet : tousLesTrajets) { ... }
```
> "Das ist eine for-each-Schleife. Sie bedeutet: 'Für jedes `trajet`-Objekt, das sich in der Liste `tousLesTrajets` befindet, mache Folgendes'."

Innerhalb dieser Schleife machen wir 3 Dinge:
* **Entfernungen berechnen**:
  ```java
  double distanceDepart = calculerDistanceHaversine(latitudeDepart, longitudeDepart, trajet.getStartLat(), trajet.getStartLon());
  ```
  Wir nutzen unsere mathematische Haversine-Funktion (siehe unten), um die Entfernung zwischen der Suche des Passagiers und dem Startpunkt der Fahrt zu berechnen. `trajet.getStartLat()` ist die Funktion, die die im Fahrt-Objekt gespeicherte Breite (Latitude) ausliest. Das Gleiche machen wir für das Ziel.

* **Der `if`-Test (Die Geschäftsregeln)**:
  ```java
  if (distanceDepart <= SEUIL_MAX_DISTANCE_KM && distanceArrivee <= SEUIL_MAX_DISTANCE_KM ...) {
  ```
  > "Wenn die Start-Entfernung kleiner oder gleich 10 km ist (unsere Konstante `SEUIL_MAX_DISTANCE_KM`), UND die Ziel-Entfernung auch <= 10 km ist, UND die Uhrzeit passt, UND genug Plätze frei sind... dann ist diese Fahrt kompatibel!"

* **Score berechnen und zur Liste hinzufügen**:
  Wenn der `if`-Test bestanden ist, berechnen wir einen Score (je näher, desto höher der Score). Dann erstellen wir ein "DTO" (ein leichtes Datenübertragungs-Objekt) namens `RechercheTrajetResultat`, packen die Infos dort hinein und machen `resultats.add(le_resultat)`, um es unserer Gewinnerliste hinzuzufügen.

**4. Sortieren und Zurückgeben:**
```java
resultats.sort(Comparator.comparingDouble(RechercheTrajetResultat::getScoreDeCompatibilite).reversed());
return resultats;
```
> "Am Ende der Schleife sortieren wir unsere Ergebnisliste vom höchsten Score zum niedrigsten (`reversed()`) und geben diese Liste an den Controller zurück."

### Die Methode für die mathematische Berechnung (`calculerDistanceHaversine`)

```java
private double calculerDistanceHaversine(double lat1, double lon1, double lat2, double lon2) { ... }
```
**Was bedeutet die Syntax?**
- `private`: Diese Funktion ist privat. Sie kann nur innerhalb dieser Datei `TrajetService` verwendet werden. Der Controller darf sie nicht aufrufen.
- `double`: Das ist der Rückgabetyp. Die Funktion wird eine Kommazahl zurückgeben (in Java nennt man das ein `double`).
- Die Parameter in den Klammern sind die Breiten- und Längengrade (ebenfalls Kommazahlen).

**Was macht sie?**
Sie nutzt die eingebaute mathematische Bibliothek von Java (`Math.toRadians`, `Math.sin`, `Math.cos`, usw.), um die klassische Haversine-Formel anzuwenden. Sie gibt das Ergebnis der Gleichung `RAYON_TERRE_KM * c` zurück (was uns die Entfernung in Kilometern liefert).

---

## 3. Zusammenfassung der Logik (Für den Dozenten)

> "Die Logik ist sehr sequenziell (Schritt-für-Schritt): Der Controller empfängt die HTTP-Anfrage und gibt sie an den `TrajetService` weiter. Der Service fragt das Repository nach allen aktiven Fahrten (welches die MongoDB-Abfrage macht). Dann macht der Service eine Schleife über jede Fahrt: Er berechnet die Haversine-Entfernung für Start und Ziel. Wenn nicht genug Plätze frei sind oder die Entfernung 10km überschreitet, wird die Fahrt ignoriert. Wenn die Regeln eingehalten werden, berechnen wir einen Score, packen die Fahrt in eine neue Liste, sortieren sie vom besten Score zum schlechtesten und geben diese Liste an den Controller zurück."
