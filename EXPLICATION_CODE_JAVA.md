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

## 1b. Entity vs. DTO (Warum gibt es beides?)

Das ist eine der wichtigsten Fragen in der Softwareentwicklung! Warum erstellen wir eine Entity (`Trajet`), wenn wir im DTO (`RechercheTrajetResultat`) fast dasselbe haben? Warum nicht einfach immer die Entity nehmen?

**1. Was ist die Entity (`Trajet.java`)?**
* Die Entity ist der **Spiegel der MongoDB-Datenbank**. Was in der Datenbank steht, steht 1:1 in der Entity.
* Sie enthält interne Daten (z.B. geheime Fahrer-IDs, komplette Passagierlisten etc.), die nicht jeder sehen darf.

**2. Was ist das DTO (`RechercheTrajetResultat.java`)?**
* DTO steht für **Data Transfer Object** (Daten-Transport-Paket).
* Es ist der **Lieferkarton für das Frontend** (Handy-App oder Website). Es enthält **nur das, was der Benutzer sehen darf**.

**Der entscheidende Unterschied:**
In MongoDB ist eine Fahrt abgespeichert. MongoDB weiß aber **nicht**, wie weit der Startpunkt der Fahrt von der Haustür des *suchenden* Passagiers entfernt ist, oder welchen *Score* diese Fahrt für diesen spezifischen Passagier hat! 
* Diese Werte (`distanceDepartKm`, `scoreMatch`) existieren in der Datenbank gar nicht. In der **Entity** (`Trajet`) können sie also nicht stehen.
* Im **DTO** (`RechercheTrajetResultat`) haben wir aber extra Fächer für diese berechneten Werte eingebaut. 

Wenn wir also `resultat.setIdTrajet(trajet.getId())` machen, dann **lesen** wir den Wert aus der Datenbank-Kiste (`trajet`) und **schreiben** ihn in die Liefer-Kiste für den Kunden (`resultat`).

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

* **Objekte erstellen und Daten übergeben (Das DTO "RechercheTrajetResultat")**:
  Wenn der `if`-Test bestanden ist, berechnen wir einen Score. Danach kommt dieser Code, der oft für Anfänger verwirrend ist:
  ```java
  RechercheTrajetResultat resultat = new RechercheTrajetResultat();
  resultat.setIdTrajet(trajet.getId());
  resultat.setHeureDepart(trajet.getHeureDepart());
  resultat.setPlacesDisponibles(trajet.getPlacesDisponibles());
  resultat.setScore(Math.round(score * 10.0) / 10.0);
  ```
  **Was genau passiert hier? (Langsam und detailliert)**
  - **Woher kommt `RechercheTrajetResultat`?** Das ist eine Klasse (ein Bauplan), die wir in einem anderen Ordner (`models` oder `dto`) erstellt haben. Sie ist extra dafür da, genau die Informationen zu halten, die das Frontend am Ende sehen will.
  - **Was macht `new`?** Mit `new RechercheTrajetResultat()` sagen wir zu Java: *"Baue mir jetzt eine frische, leere Kiste basierend auf diesem Bauplan"*. Wir geben dieser Kiste den Namen `resultat`.
  - **Was sind die Eigenschaften?** Diese leere Kiste hat Fächer (Eigenschaften), wie z.B. eine ID, eine Uhrzeit, freie Plätze und einen Score. Am Anfang sind diese Fächer leer.
  - **Wie füllen wir die Fächer? (Die Syntax)**
    - `resultat.setIdTrajet(...)` bedeutet: *"Nimm die Kiste 'resultat' und stecke etwas in das Fach 'IdTrajet'"*.
    - **Aber was stecken wir hinein?** Das, was in den Klammern steht: `trajet.getId()`.
    - `trajet` ist die Fahrt aus unserer Datenbank (die wir gerade in der `for-each`-Schleife prüfen). `getId()` ist der Befehl, der sagt: *"Lies die ID von dieser Fahrt aus"*.
    - Also passiert zusammengefasst Folgendes: Java liest die ID der Datenbank-Fahrt aus und kopiert sie direkt in unsere neue `resultat`-Kiste für das Frontend. Genau das Gleiche passiert mit der Uhrzeit (`getHeureDepart`) und den Plätzen (`getPlacesDisponibles`).
  - **Warum runden wir den Score?** `Math.round(score * 10.0) / 10.0` ist nur ein kleiner Mathe-Trick, damit der Score nur eine Nachkommastelle hat (z.B. 95.5 statt 95.49823). Danach wird dieser Wert mit `setScore(...)` in das Score-Fach unserer `resultat`-Kiste gelegt.

  **Warum machen wir das überhaupt? Warum nicht einfach das Original `trajet` senden?**
  Weil das Original `trajet` aus der Datenbank viel zu viele Infos enthält (z.B. wer das erstellt hat, geheime IDs, etc.), die das Frontend gar nicht braucht. Außerdem hat das Original-Objekt kein Fach für den "Score" (der Score wird ja nur für diesen einen Passagier live berechnet!). Deshalb erstellen wir ein maßgeschneidertes Paket (`RechercheTrajetResultat`), packen nur die nötigen Infos plus den Score hinein und machen am Ende `resultats.add(resultat)`, um diese fertige Kiste auf den Stapel der Gewinner zu legen.

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

## 2b. Wie funktionieren Parameter bei Methoden? (Der Datenfluss)

Wenn eine Methode ausgeführt wird, fragt man sich oft: *Woher kommen die Werte in den Klammern eigentlich?*

Stell dir eine Methode wie einen **Kaffeeautomaten** vor: Der Parameter in den Klammern `( ... )` ist der Einwurfschlitz.

Hier ist der Ablauf von Swagger bis zur Haversine-Formel:

**Schritt 1: Der Controller empfängt das JSON aus dem Browser (Swagger)**
```java
@PostMapping("/rechercher")
public ResponseEntity<List<RechercheTrajetResultat>> rechercher(
       @RequestBody RechercheTrajetRequete requete) {  
    return ResponseEntity.ok(trajetService.rechercherTrajets(requete));
}
```
Der Benutzer tippt in Swagger etwas ein. Spring Boot liest das JSON und packt es automatisch in eine Variable namens `requete`. Dann ruft er den Service auf und wirft diese `requete` hinein.

**Schritt 2: Der Service nimmt die `requete` entgegen**
```java
public List<RechercheTrajetResultat> rechercherTrajets(RechercheTrajetRequete critere) {
```
Im Controller hieß es `requete`, hier im Service heißt es `critere`. Der Name ist egal! Der **Inhalt** wurde übergeben. Jetzt kann der Service die Werte auspacken, z.B. mit `critere.getDepart().getLatitude()`.

**Schritt 3: Der Service ruft die Rechenmethode auf (Haversine)**
```java
double distDepart = calculerDistanceHaversine(
    passagerLatDepart,                  // 1. Wert (z.B. 48.08)
    critere.getDepart().getLongitude(), // 2. Wert (z.B. 7.36)
    trajet.getDepart().getLatitude(),   // 3. Wert (z.B. 48.05)
    trajet.getDepart().getLongitude()   // 4. Wert (z.B. 7.34)
);
```
Die Methode `calculerDistanceHaversine` empfängt diese vier Zahlen exakt in dieser Reihenfolge und speichert sie in ihren eigenen Variablen (`lat1`, `lon1`, `lat2`, `lon2`). Sie rechnet damit und schickt das Ergebnis (Kilometer) mit `return` zurück.

---

## 3. Zusammenfassung der Logik (Für den Dozenten)

> "Die Logik ist sehr sequenziell (Schritt-für-Schritt): Der Controller empfängt die HTTP-Anfrage und gibt sie an den `TrajetService` weiter. Der Service fragt das Repository nach allen aktiven Fahrten (welches die MongoDB-Abfrage macht). Dann macht der Service eine Schleife über jede Fahrt: Er berechnet die Haversine-Entfernung für Start und Ziel. Wenn nicht genug Plätze frei sind oder die Entfernung 10km überschreitet, wird die Fahrt ignoriert. Wenn die Regeln eingehalten werden, berechnen wir einen Score, packen die Fahrt in eine neue Liste, sortieren sie vom besten Score zum schlechtesten und geben diese Liste an den Controller zurück."
