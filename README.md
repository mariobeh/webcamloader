(Linux Debian/Ubuntu) - Terminal/Server

Der Webcamloader ist ein Script, welches von Webcams egal welcher Art Bilder speichert. Weitergehend lässt sich damit ein Timelapse-Video erstellen.
Es ist ein Menü vorhanden, ein normaler/geführter Modus und einen Quicky-Modus, der nach Eingabe der Variablen sofort mit der Arbeit beginnt.
Der Webcamloader schreibt jede Handlung einer Kamera, die gedownloaded wird, in ein Projekt.
Es wird empfohlen, die Projekte in einer [screen]-Session zu starten.

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
