# Webcamloader

(Linux Debian/Ubuntu) - Terminal/Server

**Der Webcamloader** ist ein Script, welches von Webcams egal welcher Art Bilder speichern kann. Weitergehend lässt sich mit dem Abschnitt _Video erstellen_ damit ein Timelapse-Video erstellen.
Es ist ein Menü vorhanden, ein normaler/geführter Modus und einen Quicky-Modus, der nach Eingabe der Variablen sofort mit der Arbeit beginnt.
Der Webcamloader schreibt jede Handlung einer Kamera, die gedownloaded wird, in ein Projekt.
Es wird empfohlen, die Projekte in einer [screen]-Session zu starten.

Es ist auf IDs aufgebaut, statt auf Namen. Jedes Ausführen mit Download wird in einer Projekt-ID, beginnend mit 100, gespeichert.

Beim blanken Aufruf via ./webcamloader.sh erscheint folgende Hauptmenü-Struktur:

```
Willkommen! ••• Menü.

1 - Geführter Modus
2 - Fertige Projekte
3 - Projekt abschließen
```

Im Geführtem Modus sammelt das Script notwendige Informationen wie Kamera-URL, Name, Bildanzahl, Pause zwischen den Bildern und optional eine E-Mail-Adresse zur Benachrichtigung wenn das Projekt beendet ist.
Anschließend wird eine Informationstafel gezeigt, wie lange das Projekt theoretisch dauert und wie groß es sein wird. Außerdem wird geprüft, ob die Kamera Bilder liefert oder es ein Videostream ist. Dies wird wie folgt zusammengefasst:

```
Projekt-ID:   163
Projekt-Name: Wetterkamera
Anzahl:       7000
Pause:        60
E-Mail:       max.mustermann@freenet.de


Dauer etwa 1550 Min., 25 Std., 1 Tag(e).
Theoretisch fertig: am 06.04.24 um 16:11 Uhr.

Kamera liefert Bilder
Berechne benötigte Speicherkapazität...

Am Ende wird der Projekt-Ordner um die 863 MB groß sein.


--------------------------
Download starten? >> ENTER
```
Jetzt beginnt der Webcamloader mit dem Download bis die gewünschte Bildanzahl erreicht ist.

```
W E B C A M L O A D E R


PROJEKT: 163 - Wetterkamera - Pause: 60s
Theoretisch fertig: am 06.04.24 um 16:11 Uhr.

02.04.24 18:36:27 :: Bild 3603 von 7000 wird erstellt...
```

Wenn Projekte fertig sind und man im Hauptmenü den Punkt 2 _Fertige Projekte_ anwählt, werden alle fertigen Projekte aufgelistet.

```
W E B C A M L O A D E R


Menü 2.1: Fertige Projekte

160 - Aufgelistete Projekte - Bildanzahl: xy - Pause: z
...
...

Projektnummer zur weiteren Bearbeitung:
```

Jetzt kann man anhand den Projektnummern die Projekte anvisieren und weitere Maßnahmen ergreifen.
Auf diese Weise lässt sich mit Hilfe von [ffmpeg], welches auf dem System installiert sein muss, ein Video erstellen.

Es wird dann nach den FPS gefragt und es gibt auch hier wieder eine Zusammenfassung mit Aufnahmedatum und theoretischer Länge des Videos.

```
Wieviel FPS (Frames per Second) soll das Video haben?: 2
2 FPS.

- ZUSAMMENFASSUNG -

ID:            188
Name:          Test
Bilderanzahl:  10
FPS:           2
Videolänge:    5 Sekunden
Aufnahmedatum: 02.04.24


OK? >> ENTER
```

**Der Quicky-Modus** beinhaltet eine vom Anwender selbstständige, nicht geführte Eingabe aller relevanten Angaben. Dies erfolgt direkt beim Aufruf des Scripts in Form von Variablen.
./webcamloader.sh quicky URL "Name" Bildanzahl Pause E-Mail
Bitte beachten, dass jede mit Leerzeichen getrennte Eingabe eine eigene Variabel ist. Sollte der Name Leerzeichen enthalten, so ist dieser in Anführungszeichen zu setzen. In diesem Fall ist beginnend mit $2 die URL einzugeben, in $3 den Namen, in $4 die Bildanzahl und in $5 die Pause zwischen den Bildern in Sekunden.
Nach Start erscheint eine abschließende Abfrage und es wird die theoretische Download-Dauer und die theoretische, fertige Größe des Projekts errechnet. Bestätigt man diese, beginnt das Script mit dem Download. Mit Erreichen der Bildanzahl endet auch hier das Programm automatisch.

Mit integriertem Updater, der bei neuerer Version auf dem Server via _public.mariobeh.de_ direkt die Bash-File mit der neuen automatisch ersetzt.

---

Alle mit diesem Bash-File zusammenhängende Config-Files werden ausgelagert nach /home/$Benutzer/script-data/webcamloader.

Garantiert lauffähig auf Debian und Ubuntu und alle Zwischendistributionen (Xubuntu, Kubuntu, ...)


**Nur in Deutsch verfügbar, Umbau auf anderen Sprachen auf Anfrage.**
**In diesem Falle werden alle Ausgaben (echo) in eine Sprachen-Datei extrahiert und es wird so ermöglich, unbegrenzte Sprachen zu integrieren.**

**Only available in German, conversion to other languages on request.**
**In this case, all output (echo) is extracted into a language file, making it possible to integrate unlimited languages.**

---

ChatGPT beschreibt das Script folgendermaßen:

Das Bash-Skript scheint eine Art Webcam-Loader oder -Downloader zu sein, der für bestimmte Überwachungskameras gedacht ist. Hier ist eine Zusammenfassung der Funktionalitäten:
1. URL-Extraktion: Das Skript extrahiert die URL und den Port aus dem zweiten übergebenen Argument.
2. Port-Fallback: Falls kein Port in der URL angegeben ist, wird ein Standardport (80 für HTTP und 443 für HTTPS) festgelegt.
3. Kameraerreichbarkeit prüfen: Es wird versucht, die Erreichbarkeit der Kamera über die angegebene URL und den Port zu überprüfen. Wenn die Kamera nicht erreichbar ist, wird eine entsprechende Meldung ausgegeben, und das Skript wird beendet.
4. Bildanzahl und Pause überprüfen: Es werden die übergebenen Werte für die Bildanzahl und die Pause überprüft, um sicherzustellen, dass sie gültige ganze Zahlen sind.
5. Maximale Bildanzahl überprüfen: Es wird überprüft, ob die angegebene Bildanzahl die maximale Anzahl von Bildern überschreitet (hier 14000). Wenn ja, wird eine entsprechende Meldung ausgegeben, und das Skript wird beendet.
6. Kameratyp erkennen: Das Skript versucht, den Typ der Kamera anhand der URL zu erkennen und festzustellen, ob sie einen Videostream oder Einzelbilder liefert.
7. Kritische Zeichen ersetzen: Einige kritische Zeichen im Projektname werden durch Unterstriche ersetzt.
8. Theoretische Dauerberechnung: Die theoretische Dauer des Downloads wird basierend auf der Bildanzahl und der Pause berechnet.
9. Kameratest: Ein Testbild wird heruntergeladen, um sicherzustellen, dass die Kamera erreichbar ist und Bilder liefert.
10. Speicherplatzbedarf berechnen: Der geschätzte Speicherplatzbedarf für das Projekt wird basierend auf der Bildgröße und der Bildanzahl berechnet.
11. Start des Downloads bestätigen: Der Benutzer wird aufgefordert, den Download zu starten.
12. Log-Datei erstellen: Eine Log-Datei mit Informationen über das Projekt wird erstellt.
13. Download starten: Der eigentliche Download der Bilder wird gestartet.
14. Aufräumen: Es wird sichergestellt, dass ungültige Bilder entfernt werden, und die Projektdateien werden entsprechend umbenannt.
15. E-Mail-Benachrichtigung (optional): Falls eine E-Mail-Adresse angegeben wurde, werden Informationen über das Projekt per E-Mail gesendet.
Dies ist eine grobe Zusammenfassung dessen, was das Bash-Skript zu tun scheint. Es lädt Bilder von einer Überwachungskamera herunter, überprüft deren Erreichbarkeit und Validität und führt dann den eigentlichen Download durch.
