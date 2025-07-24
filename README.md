# Webcamloader (Debian / 07.2025)

# Vorwort
Der Webcamloader ist ein universelles Headless-Bash-Script zur automatisierten Erfassung von Kamerabildern. Es eignet sich ideal für den Einsatz bei Baufortschrittsdokumentationen, Wetter- und Landschaftsbeobachtungen, Langzeitstudien und ähnlichen Zeitraffer-Projekten.

Das Script lädt in regelmäßigen Intervallen Einzelbilder von Bildquellen oder Videostreams herunter und speichert diese lokal. Die Bilder können später zu einem Zeitraffer-Video weiterverarbeitet werden.

Unterstützte Quellen: Bildquellen: z. B. snapshot.jpg, snapshot.cgi und Videostreams: z. B. faststream, motion-jpeg, video.cgi.

Das Script speichert alle Daten zentral unter /home/$USER/script-data/webcamloader/
Darin befinden sich: Projektverzeichnisse, Statusdaten, Logfiles, Konfigurationen. Optional kann ein abweichender Medienordner (z. B. auf einer externen Festplatte) angegeben werden. Falls keiner definiert ist, wird der Medienpfad automatisch unterhalb des script-data-Verzeichnisses angelegt.

Funktionen im Wesentlichen
Das Script prüft zu Beginn, ob die Kamera erreichbar ist, lädt ein Testbild, errechnet anhand diesem den erforderlichen Speicher für die angegebene Gesamtbildanzahl, erstellt im nächsten Schritt Projektordner und nimmt die Arbeit auf.
Falls ein Zeitfenster angegeben wurde, wird dieses berücksichtigt.
Im Fehlerfall wird der Benutzer benachrichtigt per Email, sofern angegeben.

Wenn ein Projekt abgeschlossen wurde, erhält man wahlweise eine Mail. Daraufhin kann man über einen Menüpunkt ein Video erstellen. Hierfür sind die FPS (Frame per second) nötig anzugeben. 

Das Script bietet drei Modi zum Besorgen der Bilder, die weiter unten genauer erklärt werden:
• Menü: Interaktives Menü mit allen Funktionen.
• Quicky: Komplette Steuerung via Argumente, kein Menü.
• Cron: Einmalaufrufe, zeitgesteuert z. B. über Crontab.
Für die Videoerstellung steht ein geführter Ablauf über das Menü zur Verfügung, der Schritt für Schritt und intuitiv durch den Prozess führt.

# Technische Hinweise
• Die Kamera-URL muss direkt auf ein Bild oder einen Videostream verweisen – nicht auf eine HTML-Seite oder Steueroberfläche.
• Für E-Mail-Benachrichtigungen muss der Server mail installiert und korrekt eingerichtet haben.
• Bei dem Funktionsschalter gilt: -f 0 ist Hintergrundmodus (keine Ausgabe), -f 1 ist Vordergrundmodus, komplette Ausgabe. Falls Ausgabe erwünscht ist, wird das Programm screen empfohlen, da beim Schließen des Terminals auch das Script beendet wird.
• Wird keine Funktion -f angegeben, startet automatisch der Vordergrundmodus.
• Hinweis: Nicht jede Kamera wird unterstützt, da manche Videostreams nicht mit dem Script kompatibel sind. In solchen Fällen liefert die Kamera entweder ungeeignetes Material oder einen endlosen Stream, der das Script dauerhaft blockiert. Dieses Verhalten ist technisch bedingt und wurde im Rahmen der Möglichkeiten umfassend getestet.
Wenn die Kamera ein klares Einzelbild liefert, funktioniert alles reibungslos, bei Videostreams kann es jedoch zu Problemen kommen. Sollte ein inkompatibler Stream erkannt werden, verweigert das Script automatisch die weitere Verarbeitung.

Das Script ist ressourcenschonend und benötigt keine Root-Rechte. Es erzeugt keine externen Weiterleitungen außer zur Kamera selbst.
Die heruntergeladenen Bilder werden im vorher festgelegten Medien-Ordner gespeichert und können dort jederzeit angeschaut werden. Videos landen ebenfalls dort.

Da oftmals das gesamte Projekt auf einem Linux-System ohne grafische Oberfläche läuft, ist eine direkte Sichtung der Medien dort weder praktisch noch komfortabel. Für eine reibungslose Nutzung des Scripts – insbesondere zur Auswertung und Verwaltung der erstellten Bilder und Videos – empfehle ich deshalb klar die Einrichtung einer Samba-Freigabe auf dem Headless-Server. Ansonsten müssen die gewonnenen Medien umständlich vom Server mittels FTP/SSH/SFTP kopiert werden.

# Bildbeschaffung
## Geführter Modus
Der geführte Modus über das Menü ist die zentrale, interaktive Hauptfunktion des Webcamloaders. Wird das Script ohne Parameter gestartet, öffnet sich automatisch das Hauptmenü.

Hier erfolgt die Bedienung schrittweise und intuitiv – ganz ohne Kenntnisse über Parameter oder deren Syntax. Besonders für Einsteiger ist dieser Modus ideal: Alle Einstellungen werden nacheinander abgefragt und erklärt, sodass man sicher und zielgerichtet zum gewünschten Ergebnis kommt.

Im Menü kann zwischen verschiedenen Aktionen gewählt werden: Ein neues Projekt starten, ein bestehendes Projekt fortsetzen, Einstellungen ändern, den Status prüfen oder das Projekt abbrechen. Auch ein Video lässt sich hier erstellen, diese Funktion ist im Videosektor genauer erklärt. Der Einstieg erfolgt über die Eingabe grundlegender Informationen wie Kamera-URL, Projektname, Anzahl der Bilder und Aufnahmeintervall. Optional kann ein Zeitfenster für die aktiven Aufnahmezeiten angegeben werden. Außerdem besteht die Möglichkeit, eine Benachrichtigungs-Mailadresse zu hinterlegen und zu entscheiden, ob die Ausgabe im Vordergrund oder still im Hintergrund erfolgen soll.

Sobald alle Angaben gemacht wurden, erhält man eine Übersicht mit geschätztem Speicherbedarf und Laufzeit. Mit einem einfachen Tastendruck startet die Aufzeichnung. Auch nach Projektstart können noch Informationen zum Projektstatus abgerufen oder Einstellungen angepasst werden, etwa um das Projekt frühzeitig zu beenden oder ein neues zu beginnen.

Der Menümodus ist somit der flexibelste und komfortabelste Weg, ein Zeitraffer-Projekt zu starten, und bietet zugleich volle Kontrolle über den Ablauf – ohne direkte Kommandozeilenparameter.

## Quicky-Modus
Der Quicky-Modus ist gedacht für schnelles Beginnen eines Projekts. Nach Übergabe aller erforderlichen Parameter erhält man eine Zusammenfassung mit Berechnung der Aufnahmedauer und kann mit ENTER das Projekt beginnen.

Aufruf: ./webcamloader.sh quicky -u `<URL>` -n `<Name>` -b `<Anzahl>` -i `<Intervall>` -e `<E-Mail>` -f `<Funktion>` -t `<Zeitfenster>`

### Parameter im Einzelnen:
- `-u` = Kamera-URL (http/https)
- `-n` = Projektname
- `-b` = Gesamtanzahl der Bilder
- `-i` = Intervall zwischen Aufnahmen
- `-e` = E-Mail zur Benachrichtigung (optional)
- `-f` = Funktionsmodus (0 = Hintergrund, 1 = Vordergrund) (optional)
- `-t` = Zeitfenster, z. B. `8-18` (optional)

## Cron-Modus
Der Cron-Modus ist ein Einmalaufruf, bei dem genau ein Bild gespeichert wird. Dieser ist gedacht für Langzeitaufnahmen mit Bild einmal am Tag per Crontab. Dabei können auch Folgebilder gesetzt werden. Dies ist sinnvoll, wenn der Cron-Befehl um 12:00 Uhr losgeht aber man nochmal ein Bild um 16:00 Uhr haben möchte. Klar könnte man den Crontab als 12,16 kennzeichnen - man könnte hier auch 2 Bilder definieren im Abstand von 4 Stunden. Ist Geschmackssache.

Aufruf: ./webcamloader.sh cron -u `<URL>` -n `<Name>` -x `<Anzahl>` -y `<Intervall>`

Parameter im Einzelnen:
- `-u` = Kamera URL komplett mit http(s).
- `-n` = Projektname. Freier Name für das Projekt.
- `-x` = Folgebilder (optional).
- `-y` = Intervall (optional).

# Videoerstellung
## Geführter Modus
Im oben erwähnten Menü zur Bilderstellung ist die Videoerstellung ebenfalls ein Punkt davon. Darüber lassen sich mit fertigen, abgeschlossenen Projekten ein Video erstellen. Im geführten Ablauf wird zunächst die gewünschte Bildrate (FPS – Frames per Second) abgefragt. Danach folgt eine Zusammenfassung aller relevanten Angaben zur Kontrolle. Da FPS und Bildanzahl maßgeblich die Videolänge beeinflussen, sollte hier sorgfältig geprüft werden. Dieses landet dann ebenfalls im Medienverzeichnis, parallel zu den Bildern. Ist das Video fertig, kann man das Projekt abschließen oder die FPS erneut mit anderem Wert setzen, sollte das Ergebnis des Videos nicht befriedigend sein. Wird das Projekt abgeschlossen, wird das rohe Projekt, also die Bilder als solches, gelöscht. Das Video bleibt selbstverständlich erhalten.



# Script Download
Das Programm kann hier in immer der neuesten Version heruntergeladen und sich zunutze machen:

Webcamloader Script (via mariobeh.de)
Webcamloader auf Github
Nur in Deutsch verfügbar, Umbau auf anderen Sprachen auf Anfrage. In diesem Falle werden alle Ausgaben (echo) in eine Sprachen-Datei extrahiert und es wird so ermöglicht, unbegrenzte Sprachen zu integrieren.

https://wiki.mariobeh.de/link/54#bkmrk-vielen-dank%2C%C2%A0mariobe
 
Vielen Dank, 
mariobeh.
