(Linux Debian/Ubuntu)

Der Webcamloader ist ein Script, welches von Webcams egal welcher Art Bilder speichert. Weitergehend lässt sich damit ein Timelapse-Video erstellen.
Es ist ein Menü vorhanden, ein normaler/geführter Modus und einen Quicky-Modus, der nach Eingabe der Variablen sofort mit der Arbeit beginnt.
Der Webcamloader schreibt jede Handlung einer Kamera, die gedownloaded wird, in ein Projekt.
Es wird empfohlen, die Projekte in einer [screen]-Session zu starten.

Wird der normale/geführte Modus gestartet, bekommt man eine Projektnummer zugewiesen, dann werden nacheinander die Kamera-URL, Bezeichnung für dieses Projekt, Bildanzahl und Pause zwischen den Bildern abgefragt. Es wird mit einem einmaligen Bild-Download die URL der Kamera getestet. Dies sollte in der Regel keine Sekunde andauern. Danach erscheint eine abschließende Abfrage und es wird die theoretische Download-Dauer und die theoretische, fertige Größe des Projekts errechnet. Bestätigt man diese, beginnt das Script mit dem Download.
Ist die Bildanzahl erreicht, beendet sich das Programm automatisch.

Alle mit diesem Bash-File zusammenhängende Config-Files werden ausgelagert nach /home/$Benutzer/script-data/webcamloader.

Garantiert lauffähig auf Debian und Ubuntu und alle Zwischendistributionen (Xubuntu, Kubuntu, ...)

Nur in Deutsch verfügbar, Umbau auf anderen Sprachen auf Anfrage. Only available in German, conversion to other languages on request.
