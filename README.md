# Webcamloader

(Linux Debian/Ubuntu) - Terminal/Server

**Der Webcamloader** ist ein Script, welches von Webcams egal welcher Art Bilder speichert. Weitergehend lässt sich damit ein Timelapse-Video erstellen.
Es ist ein Menü vorhanden, ein normaler/geführter Modus und einen Quicky-Modus, der nach Eingabe der Variablen sofort mit der Arbeit beginnt.
Der Webcamloader schreibt jede Handlung einer Kamera, die gedownloaded wird, in ein Projekt.
Es wird empfohlen, die Projekte in einer [screen]-Session zu starten.

Im Startmenü zum blanken Aufruf via ./webcamloader.sh erscheint folgende Struktur:
>Willkommen! ••• Menü.
>1 - Geführter Modus
>2 - Fertige Projekte
>3 - Projekt abschließen

Im Geführtem Modus sammelt das Script notwendige Informationen wie Kamera-URL, Name, Bildanzahl, Pause zwischen den Bildern und optional eine E-Mail-Adresse zur Benachrichtigung wenn das Projekt beendet ist.
Anschließend wird eine Informationstafel gezeigt, wie lange das Projekt theoretisch dauert und wie groß es sein wird. Außerdem wird geprüft, ob die Kamera Bilder liefert oder es ein Videostream ist. Dies wird wie folgt zusammengefasst:

Projekt-ID:   188
Projekt-Name: Test
Anzahl:       3000
Pause:        30
E-Mail:       max.mustermann@freenet.de


Dauer etwa 1550 Min., 25 Std., 1 Tag(e).
Theoretisch fertig: am 03.04.24 um 20:16 Uhr.

Kamera liefert Bilder
Berechne benötigte Speicherkapazität...

Am Ende wird der Projekt-Ordner um die 233 MB groß sein.


--------------------------
Download starten? >> ENTER















Wird der normale/geführte Modus gestartet, bekommt man eine Projektnummer zugewiesen, dann werden nacheinander die Kamera-URL, Bezeichnung für dieses Projekt, Bildanzahl und Pause zwischen den Bildern abgefragt. Es erscheint eine abschließende Abfrage und es wird die theoretische Download-Dauer und die theoretische, fertige Größe des Projekts errechnet. Bestätigt man diese, beginnt das Script mit dem Download.
Ist die Bildanzahl erreicht, beendet sich das Programm automatisch.

Ist nun ein Projekt erstellt, kann man dieses in ein Timelapse-Video umwandeln. Nach Eingabe der Projektnummer und der 'Frames per second' erscheint nun wieder eine abschließende Abfrage mit theoretischen Errechnungen der Videolänge. Danach erfolgt eine Visualisierung dessen.

Im zuge dessen lassen sich auch Projekte archivieren oder importieren, z. B. zur allgemeinen Weitergabe.


Der Quicky-Modus beinhaltet eine vom Anwender selbstständige, nicht geführte Eingabe aller relevanten Angaben. Dies erfolgt direkt beim Aufruf des Scripts in Form von Variablen.
./webcamloader.sh quicky URL "Name" Bildanzahl Pause
Bitte beachten, dass jede mit Leerzeichen getrennte Eingabe eine eigene Variabel ist. Sollte der Name Leerzeichen enthalten, so ist dieser in Anführungszeichen zu setzen. In diesem Fall ist beginnend mit $2 die URL einzugeben, in $3 den Namen, in $4 die Bildanzahl und in $5 die Pause zwischen den Bildern in Sekunden.
Nach Start erscheint eine abschließende Abfrage und es wird die theoretische Download-Dauer und die theoretische, fertige Größe des Projekts errechnet. Bestätigt man diese, beginnt das Script mit dem Download. Mit Erreichen der Bildanzahl endet auch hier das Programm automatisch.


Mit integriertem Updater, der bei neuerer Version auf dem Server direkt die Bash-File mit der neuen automatisch ersetzt.

Alle mit diesem Bash-File zusammenhängende Config-Files werden ausgelagert nach /home/$Benutzer/script-data/webcamloader.

Garantiert lauffähig auf Debian und Ubuntu und alle Zwischendistributionen (Xubuntu, Kubuntu, ...)

Nur in Deutsch verfügbar, Umbau auf anderen Sprachen auf Anfrage. Only available in German, conversion to other languages on request.


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
