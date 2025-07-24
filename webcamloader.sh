#!/bin/bash

###############################################################################
# WEBCAMLOADER – Automatischer Webcam-Bildloader
# Autor: mariobeh
#
scriptversion=2507232026 # muss für Updates unkommentiert bleiben
#
# Beschreibung:
# Dieses Bash-Skript lädt automatisch Einzelbilder oder Videoframes von einer
# Netzwerk-Webcam herunter, speichert sie lokal ab und kann bei Fertigstellung
# optional eine Benachrichtigung per E-Mail verschicken. Es eignet sich ideal
# für Zeitraffer, Baufortschrittsdokumentationen, Wetterkameras usw.
#
# Unterstützte Formate:
#  - Bildquellen (z. B. .jpg, snapshot.cgi)
#  - MJPEG-Streams (z. B. faststream.jpg, video.cgi)
#
# Konfiguration erfolgt bei der Erstinstallation automatisch.
#
# -----------------------------------------
# Wichtigster Modus: QUICKY-MODUS
# -----------------------------------------
# Wird für spontane, einmalige Bilderserien verwendet.
#
# Aufruf:
# ./webcamloader.sh quicky -u <URL> -n <Name> -b <Anzahl> -i <Intervall> [OPTIONEN]
#
# Parameter:
# -u | --url        : Kamera-URL (Pflicht)
# -n | --name       : Projektname (Pflicht)
# -b | --bilder     : Anzahl Bilder (Pflicht)
# -i | --intervall  : Wartezeit zwischen Bildern in Sekunden oder z. B. "5m" (Pflicht)
# -e | --email      : E-Mail für Benachrichtigung (optional)
# -f | --funktion   : 0 = Hintergrund, 1 = Vordergrund (optional)
# -t | --time       : Zeitfenster im Format HH-HH (z. B. 8-19 oder 22-6, optional)
#
# Beispiel:
# ./webcamloader.sh quicky -u http://192.168.1.99/snapshot.cgi -n "Südansicht" -b 1000 -i 60 -e du@domain.tld -f 0 -t 8-19
#
# Bitte beachten, der Server muss allgemein in der Lage sein, Emails zu versenden, sollte eine Email angegeben werden.
#
# Funktion:
# - prüft Erreichbarkeit der Kamera
# - speichert Testbild & berechnet Speicherplatzbedarf
# - erstellt Projektordner
# - lädt die Bilder mit Intervall herunter (unter Beachtung des Zeitfensters)
# - optional: E-Mail bei Fehlern oder Abschluss
# - Projekt wird mit .complete oder .incomplete-Datei dokumentiert
#
# Speicherort & Logs:
#  - Datenpfad: ~/.script-data/webcamloader/
#  - Bilder: im definierten Projektpfad
#  - Logs: exec-log/$projektnummer - $projektname.txt
#
# Resume-Funktion:
#  - Abgebrochene Projekte können über resume-Modus fortgesetzt werden
# DERZEIT ABER INAKTIV
#
# Autor & Nutzung:
# mariobeh – optimiert für Linux-Systeme (Debian/Ubuntu)
# Dieses Skript darf gerne weiterverwendet, angepasst oder erweitert werden.
#
# Disclaimer: Dieses Skript ist zur Ausführung eigener Kameras konzipiert. Bitte Datenschutz beachten!
###############################################################################


#     █████  ██      ██       ██████  ███████ ███    ███ ███████ ██ ███    ██ 
#    ██   ██ ██      ██      ██       ██      ████  ████ ██      ██ ████   ██ 
#    ███████ ██      ██      ██   ███ █████   ██ ████ ██ █████   ██ ██ ██  ██ 
#    ██   ██ ██      ██      ██    ██ ██      ██  ██  ██ ██      ██ ██  ██ ██ 
#    ██   ██ ███████ ███████  ██████  ███████ ██      ██ ███████ ██ ██   ████ 


user=$(whoami)
data="/home/$user/script-data/webcamloader"

datum_heute=$(date +"%d.%m.%y")

if [ ! -d "$data" ]; then
    mkdir -p "$data"
fi

# UPDATES BEGINN

if [ -f "$data/config.txt" ]; then

    # 11.24
    if ! grep -q "^Bilder per E-Mail = " "$data/config.txt"; then
        echo "Bilder per E-Mail = 5" >> "$data/config.txt"
    fi

    # 11.24
    # Bytes in der Config für Mindestgröße in KB abschneiden, falls 4-6 stellig
    sed -i 's/\(Testgröße minimum = [0-9]\+\)[0-9]\{3\}/\1/' "$data/config.txt"

fi

# UPDATES ENDE

if [ ! -d "$data/exec-log" ]; then
    mkdir -p "$data/exec-log"
fi

if [ ! -f "$data/.installed" ]; then
    echo ""
    echo "Der Webcamloader wird zum ersten Mal ausgeführt."
    echo "Die Konfigurationsdatei wird erstellt..."
    echo ""
    echo "Abweichender Pfad für den Webcamloader, in denen Bilder und Videos gespeichert werden?"
    echo "Falls nicht, leer lassen, dann wird im gleichen Ordner wie das Script der Pfad angelegt, ansonsten passenden Pfad eingeben."
    read -p "Pfad: " pfadin

    # wenn pfadin leer, dann setze im aktuellen Verzeichnis den Webcamloader-Ordner
    if [ -z "$pfadin" ]; then
        pfad="$(dirname "$(readlink -f "$0")")/webcamloader"
    else
        # Füge "webcamloader" am Ende hinzu, falls es noch nicht vorhanden ist
        if [[ "${pfadin}" != */webcamloader ]]; then
            pfad="$pfadin/webcamloader"
        else
            pfad=$pfadin
        fi

        # Entferne doppelte Schrägstriche, falls vorhanden
        pfad=$(echo "$pfad" | sed 's#/\{2,\}#/#g')
    fi

    echo "Pfad ist \"$pfad\""

    echo "Konfigurationsdatei wird erstellt."

    echo "[Config]" > "$data/config.txt"
    echo "Projekt = 1" >> "$data/config.txt"
    echo "Offline timeout = 10" >> "$data/config.txt"
    echo "Testgröße minimum = 16" >> "$data/config.txt"
    echo "E-Mail nach = 10" >> "$data/config.txt"
    echo "Pfad = $pfad" >> "$data/config.txt"
    echo "Bilder per E-Mail = 5" >> "$data/config.txt"

    if [ ! -d "$pfad" ]; then
        echo "Eingegebener Pfad wird erstellt."
        mkdir -p "$pfad"
    fi

    echo ""
    echo "Fertig."

    echo ""
    echo "Folgende Pakete müssen installiert sein um einen reibungslosen Ablauf zu gewährleisten:"
    echo "\"ffmpeg netcat-traditional\""
    echo "Dies ist eigenverantwortlich zu installieren. Das kann im Anschluss durchgeführt werden."
    echo "Ebenso muss im Falle von E-Mail-Benachrichtigungen sichergestellt werden, dass das System E-Mails versenden kann."
    echo ""
    sleep 5
    read -p "OK (ENTER)"

    echo ""
    echo "Die Installation ist nun beendet."

    touch "$data/.installed"

    exit 0
fi

# Lese Werte aus Config ein
projekt=$(grep -w "Projekt" "$data/config.txt" | cut -d '=' -f 2 | cut -d '#' -f 1 | tr -d ' ')
pfad=$(grep -w "Pfad" "$data/config.txt" | cut -d '=' -f 2 | cut -d '#' -f 1 | tr -d ' ')
timeout=$(grep -w "Offline timeout" "$data/config.txt" | cut -d '=' -f 2 | cut -d '#' -f 1 | tr -d ' ')
mingroesse=$(grep -w "Testgröße minimum" "$data/config.txt" | cut -d '=' -f 2 | cut -d '#' -f 1 | tr -d ' ')
min_err_email=$(grep -w "E-Mail nach" "$data/config.txt" | cut -d '=' -f 2 | cut -d '#' -f 1 | tr -d ' ')
bilderanz=$(grep -w "Bilder per E-Mail" "$data/config.txt" | cut -d '=' -f 2 | cut -d '#' -f 1 | tr -d ' ')

if [ ! -d "$pfad" ]; then
    mkdir -p "$pfad" 2>/dev/null

    # Befehl überprüfen, wenn DIR fehlt, dann Fehler
    if [ ! -d "$pfad" ]; then
        echo ""
        echo "Dateiberechtigungen fehlen, Webcamloader kann auf dem Zielverzeichnis \"$pfad\" nicht schreiben."
        exit 1
    fi
fi

# Projektnummer erhöhen und führende Nullen hinzufügen
while true; do
    projektnr=$(printf "%03d\n" $projekt) # Führende Nullen hinzufügen
    if [ ! -f $data/exec-log/$projektnr* ]; then
        break
    fi
    ((projekt++))
    projekterhohung="1"
done

# Mindestgröße aus der Konfig umrechnen in Bytes
mingroesse=$((mingroesse * 1024))

#Setze Projekt auf führende Nullen
projekt=$(printf "%03d\n" $projekt)

# Überprüfe, ob Projekt eine Nummer ist
if [[ ! "$projekt" =~ ^[0-9]+$ ]]; then
    echo "Fehler, Projekt ist keine Nummer!"
    exit 1
fi

##Erstelle Weitermachen-Script bei Unterbrechungen
#if [ ! -f "$data/resume.sh" ]; then
#    echo "#!/bin/bash" > "$data/resume.sh"
#    chmod +x "$data/resume.sh"
#fi


#    ███████ ██    ██ ███    ██ ██   ██ ████████ ██  ██████  ███    ██ ███████ ███    ██ 
#    ██      ██    ██ ████   ██ ██  ██     ██    ██ ██    ██ ████   ██ ██      ████   ██ 
#    █████   ██    ██ ██ ██  ██ █████      ██    ██ ██    ██ ██ ██  ██ █████   ██ ██  ██ 
#    ██      ██    ██ ██  ██ ██ ██  ██     ██    ██ ██    ██ ██  ██ ██ ██      ██  ██ ██ 
#    ██       ██████  ██   ████ ██   ██    ██    ██  ██████  ██   ████ ███████ ██   ████ 


function port {
    # Argument (URL) wird in "$1" übergeben
    local url="$1"

    # Extrahiere Port, falls vorhanden
    local port=$(echo "$url" | grep -oP ':\K[0-9]+')

    # Setze Standard-Port, wenn keiner angegeben ist
    if [ -z "$port" ]; then
        if echo "$url" | grep -q "^https"; then
            port="443"
        else
            port="80"
        fi
    fi

    # Rückgabe des Ports
    echo "$port"
}



function picorvid {
    local url="$1"

    # Video
    if echo "$url" | grep -qE '\.mjpg|\.mjpeg|faststream|video\.cgi|GetOneShot|mjpg\.cgi|videostream\.cgi|\/image|\?action\=stream|\/cam_.\.cgi|\.r-kom\.de'; then
        echo "1"
        return 0
    # Bild
    elif echo "$url" | grep -qE 'snapshot\.cgi|SnapshotJPEG|\.jpg|api\.cgi|cgi-bin\/camera|alarmimage|oneshotimage|image\/Index|CGIProxy\.fcgi|nph-jpeg\.cgi|onvif\/snapshot|GetImage\.cgi'; then
        echo "0"
        return 0
    # Nicht unterstützte Streams
    elif echo "$url" | grep -qE 'GetData\.cgi|mjpeg\.cgi|\.png|hugesize\.jpg'; then
        echo "2"
        return 0
    else
        echo "3"
        return 0
    fi
}



function fillortrim {
    #auffüllen auf x Zeichen
    var="$1"
    length=${#var}
        while [ $length -lt "$2" ]; do
            var="$var "
            ((length++))
        done
    var="${var:0:$2}"

    echo "$var"
}



function intro {
    echo "┌                         ┐"
    echo "  W E B C A M L O A D E R"
    echo "└      v$scriptversion        ┘   by mariobeh."
    echo ""
    echo ""
}


#   ██    ██  ██████  ██████  ██████  ███████ ██████  ███████ ██ ████████ ███████ ██████  
#   ██    ██ ██    ██ ██   ██ ██   ██ ██      ██   ██ ██      ██    ██    ██      ██   ██ 
#   ██    ██ ██    ██ ██████  ██████  █████   ██████  █████   ██    ██    █████   ██████  
#    ██  ██  ██    ██ ██   ██ ██   ██ ██      ██   ██ ██      ██    ██    ██      ██   ██ 
#     ████    ██████  ██   ██ ██████  ███████ ██   ██ ███████ ██    ██    ███████ ██   ██ 


function vorbereiter {

    url=$(echo "$2" | sed ':a; s/\([^ ]\) /\1%20/g; ta; s/^%20//; s/%20$//' | sed s'/ //'g)

    #zerlege URL in Adresse und Port
    pingcam=$(echo "$url" | grep -oP '^https?://\K[^:/]+')
    portcam=$(port "$url")

    #Prüfe, ob IP:Port erreichbar ist
    if ! nc -z -w 1 "$pingcam" "$portcam" 2>/dev/null; then
        echo ""
        echo "Adresse: $pingcam:$portcam"
        echo "Kamera nicht erreichbar. Störung?"
        err="1"
    fi

    #Bildanzahl nur ganze Zahl
    if ! [[ $4 =~ ^[0-9]+$ ]]; then
        echo ""
        echo "Bildanzahl: $4"
        echo "Bilderanzahl darf nur eine ganze, positive Zahl sein."
        err="1"
    fi

    #Intervall nur ganze Zahl
    if [[ $5 =~ ^[0-9]+$ ]]; then
        intervall=$5
    elif [[ $5 =~ ^([0-9]+)([mhts])$ ]]; then
        wert=${BASH_REMATCH[1]}
        einheit=${BASH_REMATCH[2]}
        case $einheit in
            m) intervall=$((wert * 60)) ;;          # Minuten in Sekunden
            h) intervall=$((wert * 3600)) ;;        # Stunden in Sekunden
            t) intervall=$((wert * 86400)) ;;       # Tage in Sekunden
            s) intervall=$wert ;;                   # Sekunden direkt übernehmen
        esac
    else
        echo ""
        echo "Intervall: $5"
        echo "Intervall darf nur eine ganze Zahl oder ein Zeitwert mit 'm', 'h', 't' oder 's' sein."
        err="1"
    fi

    #Bei Fehler: Abbruch
    if [ "$err" = "1" ]; then
        echo ""
        echo "Fehler, Abbruch."
        exit 1
    fi

    #Prüfung, ob der Stream ein Video oder Bild ist
    video=$(picorvid "$url") #Rückgabewert 0=Bilder 1=Videostream

    if [ "$video" = "2" ]; then
        echo "Kameraformat wird nicht unterstützt. Das Programm kann nicht arbeiten."
        echo "Fehler, Abbruch."
        exit 1
    elif [ "$video" = "3" ]; then
        echo "Kameraformat nicht erkannt. Das Programm kann nicht arbeiten."
        echo "Fehler, Abbruch."
        exit 1
    fi

    #Kritische Zeichen ersetzen und Länge begrenzen
    projektname=$(echo "$3" | sed 's/\./-/g; s/\//-/g; s/://g ; s/ä/ae/g ; s/ö/oe/g ; s/ü/ue/g ; s/Ä/Ae/g ; s/Ö/Oe/g ; s/Ü/Ue/g' | cut -c1-24)

    #Zusammenfassung
    clear
    intro

    if [ ${#3} -gt 24 ]; then
        echo "Hinweis: Der Name hat mehr als 24 Zeichen. Dieser darf nicht länger sein. Um Fehler vorzubeugen, wird der Name auf 24 Zeichen beschränkt/abgeschnitten."
        echo ""
    fi

    if [ "$projekterhohung" = "1" ]; then
        echo "Hinweis: Projektnummer wurde automatisch erhöht, da die Projektnummer bereits einmal verwendet wurde."
        echo ""
    fi

    echo "Projekt-ID:   $projekt"

    if [ "$3" = "$projektname" ]; then
        echo "Projekt-Name: $projektname"
    else
        echo "Projekt-Name: \"$3\" -> wird intern zu \"$projektname\""
    fi
    
    echo "Anzahl:       $4"

    # passe das Wort Sekunde an
    if [ "$intervall" = "1" ]; then
        echo "Intervall:    $intervall Sekunde"
    else
        echo "Intervall:    $intervall Sekunden"
    fi

    # Zeitfenster Anzeige
    if [ -n "$zeitfenster" ]; then
        echo "Zeitfenster:  $zeitfenster Uhr"
    else
        echo "Zeitfenster:  keine, 24/7"
    fi

    # E-Mail-Variable
    if [ -n "$6" ]; then
        echo "E-Mail:       $6"
    else
        echo "E-Mail:       keine Benachrichtiung"
    fi

    # Vordergrund/Hintergrund
    echo "Ausführung:   $ausf"

    echo ""
    echo ""

    # Aktuelle Zeit als Startpunkt (Unix-Timestamp)
    startzeit=$(date +%s)

    # Werte aus Argumenten
    anzahl_bilder=$4
    intervall=$intervall  # Ist vorher schon korrekt berechnet
    bilder_geplant=0

    # Zeitfenster (z. B. 8-19)
    if [[ "$zeitfenster" =~ ^([0-9]{1,2})-([0-9]{1,2})$ ]]; then
        startstunde=${BASH_REMATCH[1]}
        endestunde=${BASH_REMATCH[2]}
    else
        startstunde=0
        endestunde=24
    fi

    # Initialisiere aktuelle Zeit
    aktuelle_zeit=$startzeit

    echo "Berechne die Fertigstellungszeit ggf. unter Berücksichtigung des angegebenen Zeitfensters."
    echo "Je mehr Bilder angegeben sind, desto länger dauert die Berechnung."
    echo "Dies kann einen Moment dauern."
    echo ""

    # Simulation der Bildaufnahmezeitpunkte
    while [ $bilder_geplant -lt $anzahl_bilder ]; do
        stunde=$((10#$(date -d "@$aktuelle_zeit" +%H)))

        # Fortschritt berechnen und anzeigen
        prozent=$((bilder_geplant * 100 / anzahl_bilder))
        echo -ne "\rBerechnung: $prozent% "

        if (( startstunde < endestunde )); then
            # Zeitfenster am gleichen Tag (z. B. 8-19)
            if (( stunde >= startstunde && stunde < endestunde )); then
                ((bilder_geplant++))
                aktuelle_zeit=$((aktuelle_zeit + intervall))
            else
                naechste=$(date -d "@$aktuelle_zeit" +"%Y-%m-%d")
                aktuelle_zeit=$(date -d "$naechste $startstunde:00 +1 day" +%s)
            fi
        else
            # Zeitfenster über Mitternacht (z. B. 18-6)
            if (( stunde >= startstunde || stunde < endestunde )); then
                ((bilder_geplant++))
                aktuelle_zeit=$((aktuelle_zeit + intervall))
            else
                if (( stunde < startstunde )); then
                    datum=$(date -d "@$aktuelle_zeit" +"%Y-%m-%d")
                    aktuelle_zeit=$(date -d "$datum $startstunde:00" +%s)
                else
                    datum=$(date -d "@$aktuelle_zeit" +"%Y-%m-%d")
                    aktuelle_zeit=$(date -d "$datum $startstunde:00 +1 day" +%s)
                fi
            fi
        fi
    done

    # Zeile abschließen nach Schleife
    echo -e "\rBerechnung abgeschlossen."

    # Gib die errechnete Endzeit formatiert aus
    fertig=$(date -d "@$aktuelle_zeit" +"am %d.%m.%y um %H:%M Uhr")
    echo "Errechnete Fertigstellung unter Berücksichtigung des Zeitfensters: $fertig"
    echo ""

    #Prüfe, ob Kamera ein Videostream ist
    if [ "$video" = "1" ]; then
        echo "Kameraart: Videostream"
        ffmpeg -y -i "$url" -analyzeduration 5M -probesize 5M -loglevel quiet -nostats -hide_banner -vframes 1 "$data/$projekt-test.jpg"
        kameraart="Video"
    elif [ "$video" = "0" ]; then
        echo "Kameraart: einfache Bilder"
        wget --timeout=10 "$url" -O "$data/$projekt-test.jpg" -a /dev/null
        kameraart="Bild"
    fi

    echo "Berechne benötigte Speicherkapazität..."

    filesize=$(stat -c%s "$data/$projekt-test.jpg")

    #Prüfe, ob brauchbares Bild von der Kamera ankommt / Größenextrahierung von Testdatei
    if [ -f "$data/$projekt-test.jpg" ] && [ $filesize -gt "$mingroesse" ]; then
        ls -l "$data/" | grep "$projekt-test.jpg" | sed "s:     : :g ; s:    : :g ; s:   : :g ; s:  : :g" | cut -d ' ' -f 5 > "$data/$projekt-test.txt"
        groesse=$(cat "$data/$projekt-test.txt" | head -n1 | tail -n1)
        echo ""

        # Errechne die Größe für das ganze Projekt
        grosse_mb_soll=$(($4*$groesse/1048576))

        # zeige an, wieviel Speicher auf dem Zieldatenträger frei ist
        frei_raw=$(df -h "$pfad" | awk 'NR==2 {print $4}')
        zahl=$(echo "$frei_raw" | sed 's/[^0-9.,]//g')
        einheit=$(echo "$frei_raw" | sed 's/[0-9.,]//g')

        # Einheit ausschreiben
        case "$einheit" in
          T) einheit_lang="TB" ;;
          G) einheit_lang="GB" ;;
          M) einheit_lang="MB" ;;
          K) einheit_lang="KB" ;;
          *) einheit_lang="?" ;;
        esac

        echo "Errechnete Größe komplett ~ $grosse_mb_soll MB."
        echo "Insgesamt freier Speicher auf dem Zieldatenträger: $zahl $einheit_lang."
        rm $data/$projekt-test.*
    else
        echo ""
        echo "Fehler! Die angegebene Kamera liefert kein Bild!"
        echo "Fehler, Abbruch."

        if [ -f "$data/$projekt-test*" ]; then
            rm $data/$projekt-test.*
        fi
        exit 1
    fi

    echo ""
    echo ""
    echo "--------------------------"

    # wenn funktion ($7) web oder cron, überspringe die Zusammenfassung
    if [ "$7" = "web" ] || [ "$7" = "cron" ]; then
        echo "Das Projekt wird im Hintergrund heruntergeladen."
    else
        read -p "Projekt starten? >> ENTER " null
    fi

    #erstelle LOG-Datei
    echo "Projekt-ID: $projekt" >> "$data/exec-log/$projekt - $projektname.txt"
    echo "Aufruf via $1" >> "$data/exec-log/$projekt - $projektname.txt"
    echo "Kamera-URL: $2" >> "$data/exec-log/$projekt - $projektname.txt"
    echo "Kamera-Art: $kameraart" >> "$data/exec-log/$projekt - $projektname.txt"
    echo "Projektname: $3 ($projektname)" >> "$data/exec-log/$projekt - $projektname.txt"
    echo "Bildanzahl: $4" >> "$data/exec-log/$projekt - $projektname.txt"
    echo "Intervall: $intervall" >> "$data/exec-log/$projekt - $projektname.txt"
    echo "Errechnetes Ende: $fertig" >> "$data/exec-log/$projekt - $projektname.txt"
    echo "E-Mail: $6" >> "$data/exec-log/$projekt - $projektname.txt"
    echo "Projektgröße errechnet: $grosse_mb_soll MB" >> "$data/exec-log/$projekt - $projektname.txt"
    echo "" >> "$data/exec-log/$projekt - $projektname.txt"

    #ersetze Leerzeichen gegen Unterstriche und setze incomplete-Datei
    nameneu=$(echo "$projektname" | sed 's/ /_/g')
    touch "$data/.$projekt.$nameneu.$4.$intervall.incomplete"

    #Projekt +1 --> config
    neuprojekt=$(echo "$projekt" | sed 's/^0*//') #entfernt führende Nullen
    neuprojekt=$((neuprojekt + 1)) #zählt eins rauf
    altprojekt=$(grep -w "Projekt" "$data/config.txt" | cut -d '=' -f 2 | cut -d '#' -f 1 | tr -d ' ')
    sed -i "s/Projekt = $altprojekt/Projekt = $neuprojekt/" "$data/config.txt" #ersetze in der Config die alte Projektnr.
    neu=$(grep -w "Projekt" "$data/config.txt" | cut -d '=' -f 2 | cut -d '#' -f 1 | tr -d ' ')

    #Projekt-ID-Ordner erstellen mit Bildanzahl
    mkdir "$pfad/$projekt - $projektname (${4}Stk - ${intervall}s)"

    #Setze Variablen für Fehler (errors) und Bilder (x)
    x="1"

#    # Füge dem Weitermachen-Script projektspezifische Informationen hinzu
#    echo "" >> "$data/resume.sh"
#    echo "echo \"RESUME: Starte $projekt - $projektname\"" >> "$data/resume.sh"
#    echo "$(dirname "$(readlink -f "$0")")/$(basename "$0") resume $projekt" >> "$data/resume.sh"
}


#   ██     ██  ██████  ██████  ██   ██ ███████ ██████  
#   ██     ██ ██    ██ ██   ██ ██  ██  ██      ██   ██ 
#   ██  █  ██ ██    ██ ██████  █████   █████   ██████  
#   ██ ███ ██ ██    ██ ██   ██ ██  ██  ██      ██   ██ 
#    ███ ███   ██████  ██   ██ ██   ██ ███████ ██   ██ 


function worker {

    # Setze Variablen
    error_sekunden=$(($min_err_email * 60 / timeout))
    errors="0"

    zeitfenster="$7"

#    if [ "$1" = "resume" ] && [ -n "$7" ]; then
#        x="$7"
#        projektname="$3"
#        nameneu=$(echo "$3" | sed 's/ /_/g')
#
#        #zerlege URL in Adresse und Port
#        pingcam=$(echo "$url" | grep -oP '^https?://\K[^:/]+')
#        portcam=$(port "$url")
#
#        #Protokolliere
#        echo "$(date +"%d.%m.%y %H:%M:%S") :: Wiederaufnahme" >> "$data/exec-log/$projekt - $projektname.txt"
#    fi

        while [ "$x" -le "$4" ]; do #solange ausführen, bis Anzahl erreicht

            prozent=$(( ($x * 100) / $4 ))

            # === Zeitfensterprüfung ===
            if [[ "$zeitfenster" =~ ^([0-9]{1,2})-([0-9]{1,2})$ ]]; then
                startstunde=${BASH_REMATCH[1]}
                endestunde=${BASH_REMATCH[2]}
                aktuelle_stunde=$(date +%H)

                if (( startstunde < endestunde )); then
                    # Normale Zeitspanne (z. B. 8–19)
                    if (( aktuelle_stunde < startstunde || aktuelle_stunde >= endestunde )); then
                        echo "$(date +"%d.%m.%y %H:%M:%S") :: Aufnahme unterdrückt (außerhalb Zeitfenster $(printf "%02d:00–%02d:59" "$startstunde" "$(( (endestunde + 23) % 24 ))") Uhr)."
                        sleep "$intervall"
                        continue
                    fi
                else
                    # Über Mitternacht (z. B. 18–6)
                    if ! (( aktuelle_stunde >= startstunde || aktuelle_stunde < endestunde )); then
                        echo "$(date +"%d.%m.%y %H:%M:%S") :: Aufnahme unterdrückt (außerhalb Zeitfenster $(printf "%02d:00–%02d:59" "$startstunde" "$(( (endestunde + 23) % 24 ))") Uhr)."
                        sleep "$intervall"
                        continue
                    fi
                fi
            fi

            # Überprüfen, ob .incomplete umbenannt oder gelöscht wurde
            if [ ! -f "$data/.$projekt.$nameneu.$4.$intervall.incomplete" ]; then
                break
            fi

            #Prüfe, ob Kamera offline ist
            while ! nc -z -w 1 "$pingcam" "$portcam" 2>/dev/null; do
                clear
                intro
                echo "PROJEKT: $projekt - $3"

                if [ ! "$1" = "resume" ]; then
                    echo "Errechnet fertig: $fertig"
                fi

                echo ""

                #Ausgabe
                echo "$(date +"%d.%m.%y %H:%M:%S") :: Kamera offline? Prüfe erneut nach $timeout Sekunden...  - Fortschritt: $prozent%"

                #Protokolliere
                echo "$(date +"%d.%m.%y %H:%M:%S") :: Kamera offline" >> "$data/exec-log/$projekt - $projektname.txt"

                #Sammle Informationen im Fehlerfall nach x Minuten und schicke E-Mail
                if [ "$errors" = "$error_sekunden" ] && [ ! "$6" = "0" ] && [ -n "$6" ]; then

                    # SAMMELN BGEINN
                    echo "W E B C A M L O A D E R" >> "$data/.$projekt-email.txt"
                    echo "Projekt fehlerhaft!" >> "$data/.$projekt-email.txt"
                    echo "" >> "$data/.$projekt-email.txt"
                    echo "" >> "$data/.$projekt-email.txt"
                    echo "Projekt-ID: $projekt" >> "$data/.$projekt-email.txt"
                    echo "Projektname: $3" >> "$data/.$projekt-email.txt"
                    echo "Bildanzahl: $x von $bildanzahl Stk." >> "$data/.$projekt-email.txt"
                    echo "Intervall: $intervall Sek." >> "$data/.$projekt-email.txt"
                    echo "" >> "$data/.$projekt-email.txt"
                    echo "Projektgröße: $(du -sh "$pfad/${projekt}"* | cut -d '/' -f 1 | tr -d ' ')" >> "$data/.$projekt-email.txt"
                    echo "" >> "$data/.$projekt-email.txt"
                    echo "Fortschritt: $prozent%" >> "$data/.$projekt-email.txt"
                    echo "" >> "$data/.$projekt-email.txt"
                    echo "" >> "$data/.$projekt-email.txt"
                    echo "Das Projekt wird nicht unterbrochen, aber es besteht nun seit $min_err_email Minuten keine Verbindung zur Kamera mehr." >> "$data/.$projekt-email.txt"
                    # SAMMELN ENDE

                    echo "Sende E-Mail..."
                    cat "$data/.$projekt-email.txt" | mail -s "Webcamloader" "$6"
                    rm "$data/.$projekt-email.txt"

                fi

                ((errors++))

                sleep "$timeout"
            done

        errors="0"
    
        clear
        intro
        echo "PROJEKT: $projekt - \"$3\" - Intervall: ${intervall}s"
        echo "Errechnet fertig: $fertig"
        echo ""

        # Ausgabe
        echo "$(date +"%d.%m.%y %H:%M:%S") :: Bild $x von $4 wird erstellt - Fortschritt: $prozent%"

        # Protokolliere
        echo "$(date +"%d.%m.%y %H:%M:%S") :: Bild $x / $4" >> "$data/exec-log/$projekt - $projektname.txt"

        # Bildpfad definieren
        bildpfad="$pfad/$projekt - $projektname (${4}Stk - ${intervall}s)/$(date +"%y%m%d%H%M%S - $projektname - $x von $4 (${intervall}s).jpg")"

        if [ "$video" = "1" ]; then
            ffmpeg -y -i "$2" -loglevel quiet -nostats -hide_banner -vframes 1 "$bildpfad" > "/dev/null"
            echo "OK. Warte ${intervall}s ab..."

        elif [ "$video" = "0" ]; then
            wget "$2" -O "$bildpfad" -a "/dev/null"
            echo "OK. Warte ${intervall}s ab..."
        fi

        filesize=$(stat -c%s "$bildpfad")

        # Überprüfe, ob das Bild existiert und ob die Größe kleiner als mingroesse ist
        if [ -f "$bildpfad" ] && [ $filesize -lt "$mingroesse" ]; then
            rm "$bildpfad"
            echo "Das Bild wurde gelöscht, da es kleiner als die Mindestgröße ist."
            # Protokolliere
            echo "$(date +"%d.%m.%y %H:%M:%S") :: Bild $x / $4 gelöscht (Mindestgröße!)" >> "$data/exec-log/$projekt - $projektname.txt"
        else
            echo "Bild OK."
        fi

        sleep "$intervall"

        if [ -f "$data/.$projekt.$nameneu.$4.$intervall.incomplete" ]; then
            ((x++))
        fi

    done

    clear

    if [ -f "$data/.$projekt.$nameneu.$4.$intervall.incomplete" ]; then
        echo "$4 Bild(er) gespeichert mit der Projekt-Nummer $projekt ($projektname)"
    else
        echo "$x Bild(er) gespeichert mit der Projekt-Nummer $projekt ($projektname)"
    fi

    bildanzahl=$(find $pfad/$projekt* -type f | wc -l)

    if [ ! "$4" = "$bildanzahl" ]; then
        echo "Tatsächliche Bilder nach dem Entfernen ungültiger Bilder: $bildanzahl."
    else
        echo "Alle Bilder OK."
    fi

    if [ -f "$data/.$projekt.$nameneu.$4.$intervall.incomplete" ]; then
        mv "$data/.$projekt.$nameneu.$4.$intervall.incomplete" "$data/.$projekt.$nameneu.$bildanzahl.$intervall.complete"
    else
        echo "Das Projekt wurde manuell beendet."
    fi

    dat_org="$pfad/$projekt - $projektname (${4}Stk - ${intervall}s)"
    dat_mod="$pfad/$projekt - $projektname (${bildanzahl}Stk - ${intervall}s)"

    if [ ! "$dat_org" = "$dat_mod" ]; then
        mv "$dat_org" "$dat_mod"
    fi

    # Entferne Projekt aus RESUME Datei
#    sed -i "/^echo RESUME: Starte $projekt.*/,+1 d" "$data/resume.sh"

    if [ ! "$6" = "0" ] && [ -n "$6" ]; then
        echo "Sammle Informationen..."

        # SAMMELN BGEINN
        echo "W E B C A M L O A D E R" >> "$data/.$projekt-email.txt"
        echo "Projekt fertig!" >> "$data/.$projekt-email.txt"
        echo "" >> "$data/.$projekt-email.txt"
        echo "" >> "$data/.$projekt-email.txt"
        echo "Projekt-ID: $projekt" >> "$data/.$projekt-email.txt"
        echo "Projektname: $3" >> "$data/.$projekt-email.txt"

        if [ "$4" = "$bildanzahl" ]; then
            echo "Bildanzahl: $bildanzahl Stk." >> "$data/.$projekt-email.txt"
        else
            echo "Bildanzahl soll: $4 Stk." >> "$data/.$projekt-email.txt"
            echo "Bildanzahl ist: $bildanzahl Stk." >> "$data/.$projekt-email.txt"
        fi

        echo "Intervall: $intervall Sek." >> "$data/.$projekt-email.txt"
        echo "" >> "$data/.$projekt-email.txt"
        echo "Projektgröße: $(du -sh "$pfad/${projekt}"* | cut -d '/' -f 1 | tr -d ' ')" >> "$data/.$projekt-email.txt"

        # Finde die Bilder und speichere sie in einem Array
        bilder=$(find "$pfad/$projekt - $projektname (${bildanzahl}Stk - ${intervall}s)" -type f -iname '*.jpg' | shuf -n $bilderanz)

        # Erstelle den Befehl für die Anhänge
        anhang=()

        # Füge jeden Bildpfad als Anhang hinzu
        while IFS= read -r bild; do
            if [ -e "$bild" ]; then  # Überprüfe, ob die Datei existiert
                anhang+=(-A "$bild")
            else
                echo "Datei existiert nicht: $bild"  # Ausgabe für nicht existierende Datei
            fi
        done <<< "$bilder"

        # Stelle sicher, dass die Anhangsvariable keine zusätzlichen Leerzeichen hat
        anhang=$(echo $anhang | xargs)

        # DEBUG
        echo ""
        echo ""
        echo "BILDER: $bilder"
        echo ""
        echo "ARRAY: ${anhang[@]}"
        echo ""
        echo "ANHANG: $anhang"
        echo ""
        echo ""

        # SAMMELN ENDE

        echo "Sende E-Mail..."

        # Versende die E-Mail mit dem Inhalt der Textdatei und den Anhängen
        mail -s "Webcamloader" "${anhang[@]}" "$6" < "$data/.$projekt-email.txt"

        rm "$data/.$projekt-email.txt"
    fi

    echo ""
    echo "Fertig."

    exit 0
 
}

#    ██████  ███████ ███████ ██    ██ ███    ███ ███████ 
#    ██   ██ ██      ██      ██    ██ ████  ████ ██      
#    ██████  █████   ███████ ██    ██ ██ ████ ██ █████   
#    ██   ██ ██           ██ ██    ██ ██  ██  ██ ██      
#    ██   ██ ███████ ███████  ██████  ██      ██ ███████ 

#if [ "$1" = "resume" ]; then
#
#    if [ -z "$2" ]; then
#        exit 1
#    fi
#
#    echo "$(date +"%d.%m.%y %H:%M:%S") :: RESUME: Starte $2 – warte 30 Sekunden..." >> "$data/exec-log/$2 - resume.txt"
#    sleep 30
#
#    # Hole Informationen ein aus dem jewiligen Log
#    projekt="$2"
#    url=$(grep -w "Kamera-URL:" $data/exec-log/$projekt*.txt | cut -d ':' -f 2- | sed ':a; s/\([^ ]\) /\1%20/g; ta; s/^%20//; s/%20$//' | sed s'/ //'g)
#    bildanzahl_ist=$(find $pfad/$projekt* -type f | wc -l)
#    bildanzahl_soll=$(grep -w "Bildanzahl:" $data/exec-log/$projekt*.txt | cut -d ':' -f 2- | sed s'/ //'g)
#    name=$(grep -w "Projektname:" "$data/exec-log/$projekt"* | cut -d ':' -f 2- | sed 's/.*(\(.*\)).*/\1/') # | sed s'/ /_/'g)
#    intervall=$(grep -w "Intervall:" $data/exec-log/$projekt*.txt | cut -d ':' -f 2- | sed s'/ //'g)
#    email=$(grep -w "E-Mail:" $data/exec-log/$projekt*.txt | cut -d ':' -f 2- | sed s'/ //'g)
#    kameraart=$(grep -w "Kamera-Art:" $data/exec-log/$projekt*.txt | cut -d ':' -f 2- | sed s'/ //'g)
#
#    bildanzahl_ist=$((bildanzahl_ist + 1))
#
#    if [ -z "$email" ]; then
#        email="0"
#    fi
#
#    if [ "$kameraart" = "Bild" ]; then
#        video="0"
#    elif [ "$kameraart" = "Video" ]; then
#        video="1"
#    else
#        exit 1
#    fi
#
#    worker "resume" "$url" "$name" "$bildanzahl_soll" "$intervall" "$email" "$bildanzahl_ist" >/dev/null 2>&1 &
#
#fi

#     ██████  ██    ██ ██  ██████ ██   ██ ██    ██
#    ██    ██ ██    ██ ██ ██      ██  ██   ██  ██ 
#    ██    ██ ██    ██ ██ ██      █████     ████  
#    ██ ▄▄ ██ ██    ██ ██ ██      ██  ██     ██   
#     ██████   ██████  ██  ██████ ██   ██    ██   
#        ▀▀                                       

if [ "$1" = "quicky" ]; then
    shift # Verschiebe das erste Argument (quicky) aus dem Argumentvektor

    # Standardwert für funktion setzen
#    funktion="1"
#    ausf="Vordergrund"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -u|-k|--kamera|--url|--uri) url="$2"; shift 2 ;;
            -b|-x|--pictures|--pics|--bilder|--bildanzahl) bildanzahl="$2"; shift 2 ;;
            -p|-s|-y|-w|-i|--wait|--sleep|--pause|--intervall) intervall="$2"; shift 2 ;;
            -e|-m|--mail|--email|--notification|--notes) email="$2"; shift 2 ;;
            -n|--name|--projektname) name="$2"; shift 2 ;;
            -f|--funktion) funktion="$2"; shift 2 ;;
            -t|-z|--time|--zeit|--zeitfenster) zeitfenster="$2"; shift 2 ;;
        esac
    done

    if [ -z "$url" ] || [ -z "$bildanzahl" ] || [ -z "$intervall" ] || [ -z "$name" ]; then
        echo "Fehler, für den Quicky-Modus fehlt mindestens ein Argument."
        echo "Info:"
        echo ""
        echo " -u|-k|--kamera|--url|--uri                        = URL"
        echo " -b|-x|--pictures|--pics|--bilder|--bildanzahl     = Bilderanzahl"
        echo " -p|-s|-y|-w|-i|--wait|--sleep|--pause|--intervall = Intervall"
        echo " -n|--name|--projektname                           = Name"
        echo " -e|-m|--mail|--email|--notification               = E-Mail (optional)"
        echo " -f|--funktion                                     = Funktion (optional)"
        echo " -t|-z|--time|--zeit|--zeitfenster                 = Zeitfenster (optional)"
        echo ""
        echo "Die Funktion (-f) kann folgende Werte haben: 0, hintergrund (Hintergrund) oder 1, vordergrund, normal (Vordergrund)."
        echo "-f 0 bestimmt, dass die Ausführung des Downloads im Hintergrund geschieht. Für eine Anzeige des Geschehens ist Vordergrund optimal."
        echo ""
        echo "Das Zeitfenster bestimmt, wann Aufnahmen getätigt werden dürfen. -t 8-19 besagt, dass zwischen 8 und 18:59 Uhr Bilder gespeichert werden."
        echo ""
        echo "$0 quicky2 -u URL -n Name -b Bildanzahl -i Intervall -e E-Mail (optional) -f 0"
        echo "$0 quicky2 -u \"http://172.22.20.36:8000/snapshot.cgi\" -n \"Alpenpanorama\" -b 5000 -i 10 -e \"mail@domain.tld\""
        echo ""
        echo "Darauf achten: Leerzeichen trennt - ist im Namen ein Leerzeichen enthalten, unbedingt mit \" \" arbeiten!"
        echo "Dasselbe gilt bei der Kamera-URL. Sind hier Zeichen wie ein \"&\", muss ebenfalls mit \" \" gearbeitet werden!"
        exit 1
    fi

    if [ -z "$email" ]; then
        email=""
    fi

    if [ -z "$zeitfenster" ]; then
        zeitfenster=""
    fi


    case "$funktion" in
        "0"|"web"|"cron"|"hintergrund")
            ausf="Hintergrund"
            vorbereiter "quicky" "$url" "$name" "$bildanzahl" "$intervall" "$email" "$funktion" "$zeitfenster"
            worker "quicky" "$url" "$name" "$bildanzahl" "$intervall" "$email" "$zeitfenster" >/dev/null 2>&1 &
            ;;
        "1"|"normal"|"vordergrund")
            ausf="Vordergrund"
            vorbereiter "quicky" "$url" "$name" "$bildanzahl" "$intervall" "$email" "$funktion" "$zeitfenster"
            worker "quicky" "$url" "$name" "$bildanzahl" "$intervall" "$email" "$zeitfenster"
            ;;
        *)
            echo "Funktion \"-f\" fehlt. Diese kann folgende Werte haben:"
            echo "Vordergrund: 1, normal, vordergrund"
            echo "Hintergrund: 0, hintergrund"
            echo "Ohne Nachfrage für Web/Crontab: web, cron"
            exit 1
            ;;
    esac

    exit 0
fi

#     ██████ ██████   ██████  ███    ██ 
#    ██      ██   ██ ██    ██ ████   ██ 
#    ██      ██████  ██    ██ ██ ██  ██ 
#    ██      ██   ██ ██    ██ ██  ██ ██ 
#     ██████ ██   ██  ██████  ██   ████ 

# Vorbereitung für Cron-Aufrufe, Funktion noch ausstehend

if [ "$1" = "cron" ]; then
    shift # Verschiebe das erste Argument (cron) aus dem Argumentvektor
    
    # Standardwerte
    anzahl="1"
    intervall="1"

    # Argumente einlesen
    while getopts "u:n:x:y:" opt; do
        case "$opt" in
            u) url="$OPTARG" ;;
            n) projektname="$OPTARG" ;;
            x) anzahl="$OPTARG" ;;
            y) intervall="$OPTARG" ;;
            *) echo "Ungültiger Parameter"; exit 1 ;;
        esac
    done

    # Pflichtparameter prüfen
    if [ -z "$url" ] || [ -z "$projektname" ]; then
        echo "[FEHLER] Bitte Kamera-URL (-u) und Projektname (-n) angeben."
        exit 1
    fi

    # Projektname bereinigen für Dateinutzung
    projektname=$(echo "$projektname" | sed 's/ /_/g' | sed 's/[^a-zA-Z0-9äöüÄÖÜß_-]//g')

    # Prüfen, ob Projektname schon existiert → cXX übernehmen
    bestehend=$(find "$data" -type f -name ".c*.$projektname.*.complete" 2>/dev/null | head -n1)

    if [ -n "$bestehend" ]; then
        # cXX aus Dateiname extrahieren
        nr=$(echo "$bestehend" | sed -n 's/.*\.c\([0-9]\+\)\..*/\1/p')
    else
        # neue Projektnummer ermitteln
        projekteinsg=$(find "$data" -type f -name ".c*.*.complete" 2>/dev/null | wc -l)
    
        if [ "$projekteinsg" = "0" ]; then
            nr=1
        else
            nr=$((projekteinsg + 1))
        fi
    fi

    # Immer auf zweistellig bringen
    nr=$(printf "%02d" "$nr")

    # Zielverzeichnis vorbereiten
    zielverzeichnis="$pfad/c${nr} - $projektname"
    mkdir -p "$zielverzeichnis"

    # Typ bestimmen
    typ=$(picorvid "$url")
    if [ "$typ" = "2" ]; then
        echo "[FEHLER] Ungeeigneter Streamtyp erkannt."
        exit 1
    elif [ "$typ" = "3" ]; then
        echo "[FEHLER] Unbekannter URL-Typ."
        exit 1
    fi

    # Aktuellen Bildzähler ermitteln
    bildnr=$(find "$zielverzeichnis" -type f -iname "* - $projektname - *.jpg" | wc -l)
    bildnr=$((bildnr + 1))

    # Hauptschleife für Bilder
    for ((i=1; i<=anzahl; i++)); do
        timestamp=$(date +"%y%m%d%H%M%S")
        bildpfad="$zielverzeichnis/$(date +"%y%m%d%H%M%S - $projektname - $bildnr.jpg")"


        versuch=1
        while [ $versuch -le 3 ]; do
            echo "[INFO] Lade Bild $bildnr (Versuch $versuch)..."

            if [ "$typ" = "0" ]; then
                wget --timeout=10 -q -O "$bildpfad" "$url"
            elif [ "$typ" = "1" ]; then
                ffmpeg -loglevel quiet -y -i "$url" -frames:v 1 "$bildpfad"
            fi

            # Prüfen, ob Datei gültig ist
            if [ -f "$bildpfad" ] && [ "$(stat -c%s "$bildpfad")" -ge "$mingroesse" ]; then
                echo "[OK] Bild $bildnr gespeichert: $bildpfad"
                break
            else
                echo "[WARNUNG] Bild ungültig (zu klein), wiederhole..."
                rm -f "$bildpfad"
                versuch=$((versuch + 1))
                sleep 10
            fi
        done

        if [ $versuch -gt 3 ]; then
            echo "[FEHLER] Bild $bildnr konnte nicht gespeichert werden."
        fi

        bildnr=$((bildnr + 1))

        # Nur warten, wenn weitere Bilder folgen
        if [ "$i" -lt "$anzahl" ]; then
            sleep "$intervall"
        fi

    done

    # Bildanzahl aktualisieren
    bildanzahl=$(find "$zielverzeichnis" -type f -iname "*.jpg" | wc -l)

    # Alte Statusdatei entfernen, neue schreiben
    rm -f "$data/.c${nr}.${projektname}."*".complete"
    statusfile="$data/.c${nr}.${projektname}.${bildanzahl}.cron.complete"
    touch "$statusfile"

    exit 0
fi


#    ███    ███ ███████ ███    ██ ██    ██
#    ████  ████ ██      ████   ██ ██    ██
#    ██ ████ ██ █████   ██ ██  ██ ██    ██
#    ██  ██  ██ ██      ██  ██ ██ ██    ██
#    ██      ██ ███████ ██   ████  ██████ 

function hauptmenu {

#                     ██  ██       ██         ██   ██  █████  ██    ██ ██████  ████████
#                    ████████     ███         ██   ██ ██   ██ ██    ██ ██   ██    ██   
#    █████ █████      ██  ██       ██         ███████ ███████ ██    ██ ██████     ██   
#                    ████████      ██         ██   ██ ██   ██ ██    ██ ██         ██   
#                     ██  ██       ██         ██   ██ ██   ██  ██████  ██         ██   

    clear
    intro
    echo "Willkommen! ••• Menü."
    echo ""

    echo "1 - Geführter Modus zum Erstellen eines Projekts"
    echo "2 - Fertige Projekte einsehen & Video erstellen"
    echo "3 - Projekt abschließen / abbrechen"
    echo "4 - Status laufender Projekte"
    echo "5 - Konfigurationswerte ändern"
    echo "9 - Update"

    echo ""
    read -p "Auswahl: " auswahl
    echo ""
}



function geführt {

#                     ██  ██       ██     ██          ██████  ███████ ███████ 
#                    ████████     ███    ███         ██       ██      ██      
#    █████ █████      ██  ██       ██     ██         ██   ███ █████   █████   
#                    ████████      ██     ██         ██    ██ ██      ██      
#                     ██  ██       ██ ██  ██          ██████  ███████ ██      

    clear
    intro
    echo "Menü 1.1: Geführter Modus"
    echo ""
    echo "In diesem Menü werden nacheinander die Parameter abgefragt, die für das Programm wichtig sind."
    echo ""
    echo ""

    # URL Abfrage mit Prüfung
    while true; do
        read -p "Kamera-URL: " url
        if [[ -n $url && $url =~ ^(http|https):// ]]; then
            break
        else
            echo "URL ungültig, bitte nochmal eingeben."
        fi
    done

    # Name Abfrage mit Prüfung
    while true; do
        read -p "Name des Projekts: " name
        if [[ -n $name ]]; then
            break
        else
            echo "Name darf nicht leer sein."
        fi
    done

    # Bildanzahl Abfrage mit Prüfung
    while true; do
        read -p "Bildanzahl: " anzahl
        if [[ $anzahl =~ ^[0-9]+$ && -n $anzahl ]]; then
            break
        else
            echo "Bildanzahl ungültig. Bitte geben Sie eine Zahl ein."
        fi
    done

    # Intervall Abfrage mit Prüfung
    while true; do
        read -p "Intervall zwischen Bildern in Sekunden: " intervall
        if [[ $intervall =~ ^[0-9]+$ && -n $intervall ]]; then
            break
        else
            echo "Intervall ungültig. Bitte geben Sie eine Zahl ein."
        fi
    done

    # E-Mail Abfrage mit Prüfung
    while true; do
        read -p "Soll eine E-Mail bei Fertigstellung gesendet werden? Falls ja, E-Mail-Adresse, falls nein, leer lassen: " email
        if [[ -z $email ]]; then
            break
        elif [[ $email =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            break
        else
            echo "E-Mail-Adresse ungültig. Bitte eine gültige E-Mail-Adresse eingeben oder leerlassen (optional)."
        fi
    done

    # Ausführung: Vordergrund / Hintergrund
    echo ""
    echo "Soll der Webcamloader im Vordergrund oder Hintergrund laufen?"
    echo "Vordergrund: Information über den Download, läuft nur solange, wie das Terminalfenster geöffnet ist, geeignet auch für eine screen-Session,"
    echo "Hintergrund: Passive Ausführung im Hintergrund ohne interaktive Informationen, geeignet für Ausführung für Langzeitaufnahmen."
    echo ""
    echo "Wird einfach mit ENTER bestätigt, läuft die Anwendung im Hintergrund."
    
    while true; do
        read -p "Hintergrund (0) oder Vordergrund (1): " ausfuhrung
        if [[ -z "$ausfuhrung" || "$ausfuhrung" == "0" || "$ausfuhrung" == "1" ]]; then
            break
        else
            echo "Ungültige Eingabe. Bitte nur ENTER, 0 oder 1 eingeben."
        fi
    done

    if [ -z "$ausfuhrung" ]; then #|| [ "$ausfuhrung" = "0" ]; then
        ausf="Hintergrund"
        vorbereiter "Menü" "$url" "$name" "$anzahl" "$intervall" "$email" "$funktion"
        worker "quicky" "$url" "$name" "$bildanzahl" "$intervall" "$email" >/dev/null 2>&1 &
    fi

    if [ "$ausfuhrung" = "1" ] || [ "$ausfuhrung" = "0" ]; then
        ausf="Vordergrund"
        vorbereiter "Menü" "$url" "$name" "$anzahl" "$intervall" "$email" "$funktion"
        worker "quicky" "$url" "$name" "$bildanzahl" "$intervall" "$email"
    fi

exit 0

}



function status {

#                     ██  ██       ██    ██   ██     ███████ ████████  █████  ████████ ██    ██ ███████ 
#                    ████████     ███    ██   ██     ██         ██    ██   ██    ██    ██    ██ ██      
#    █████ █████      ██  ██       ██    ███████     ███████    ██    ███████    ██    ██    ██ ███████ 
#                    ████████      ██         ██          ██    ██    ██   ██    ██    ██    ██      ██ 
#                     ██  ██       ██ ██      ██     ███████    ██    ██   ██    ██     ██████  ███████ 

    clear
    intro

    # Projekte zählen - $nr initialisieren
    nr="0"

    # Liste der Dateien im Verzeichnis abrufen
    file_list=$(find "$data" -maxdepth 1 -type f -name *.incomplete 2>/dev/null)

    # Überprüfen, ob Dateien gefunden wurden
    if [ -n "$file_list" ]; then

        zeitstempel=$(date +"%d.%m.%y %H:%M:%S")
        echo "Aktuelle Uhrzeit: $zeitstempel"
        echo ""
        status_jetzt=$(date -d "$(echo "$zeitstempel" | sed 's/\(..\)\.\(..\)\.\(..\) \(..\):\(..\):\(..\)/20\3\/\2\/\1 \4:\5:\6/')" +%s)

        echo "┌-----┬--------------------------┬-----------------┬-------┬-------------------┬--------------------------┬---┬---┬-----┐"
        echo "| ID  |       Projektname        |      Bilder     | Intrv |   letzte Aktion   |errechnete Fertigstellung | @ |OK?|  %  |"
        echo "├-----┼--------------------------┼-----------------┼-------┼-------------------┼--------------------------┼---┼---┼-----┤"

        # Schleife über die Dateien
        for file in $file_list; do

            # Projekte zählen
            ((nr++))

            # Projektnummer und Projektnamen extrahieren
            projektnummer=$(echo "$file" | awk -F'/' '{print $NF}' | cut -d '.' -f 2)
            projektname=$(echo "$file" | awk -F'/' '{print $NF}' | cut -d '.' -f 3 | sed 's/_/ /g')
            bildanzahl_theo=$(echo "$file" | awk -F'/' '{print $NF}' | cut -d '.' -f 4)
            bildanzahl_real=$(find $pfad/$projektnummer* -type f -name *.jpg | wc -l)
            intervall=$(echo "$file" | awk -F'/' '{print $NF}' | cut -d '.' -f 5)
            theo_ende=$(grep -w "Ende:" $data/exec-log/$projektnummer* | cut -d ':' -f 2- | cut -d ' ' -f 2- | cut -d '.' -f 1-3)
            letztezeile=$(cat $data/exec-log/$projektnummer* | tail -n 1 | head -n 1 | cut -d ':' -f 1-3 | sed 's/ \([^ ]*\)$/\1/')
            email=$(grep -w "E-Mail:" $data/exec-log/$projektnummer* | cut -d ':' -f 2- | sed 's/ //g')

            # Email vorhanden?
            if [ -n "$email" ]; then
                email="✓"
            else
                email="X"
            fi

            # Fertigstellung in %
            prozent=$(( ($bildanzahl_real * 100) / $bildanzahl_theo ))

            #auffüllen auf x Zeichen
            projektname=$(fillortrim "$projektname" "24")
            bildanzahl_real=$(fillortrim "$bildanzahl_real" "6")
            bildanzahl_theo=$(fillortrim "$bildanzahl_theo" "6")
            intervall=$(fillortrim "$intervall" "5")
            prozent=$(fillortrim "$prozent" "2")

            # Rechne mit Zeit
            status_letztezeile=$(date -d "$(echo "$letztezeile" | sed 's/\(..\)\.\(..\)\.\(..\) \(..\):\(..\):\(..\)/\3\2\1 \4:\5:\6/')" +"%s")
            status_unterschied=$((status_jetzt - status_letztezeile))

            # Überprüfung, ob die vergangene Zeit größer als die Intervallzeit ist
            if [ "$status_unterschied" -gt "$intervall" ]; then
                status="X"
            else
                status="✓"
            fi

            echo "| $projektnummer | $projektname | $bildanzahl_real / $bildanzahl_theo | $intervall | $letztezeile | $theo_ende | $email | $status | $prozent% |"
        done

    echo "└-----┴--------------------------┴-----------------┴-------┴-------------------┴--------------------------┴---┴---┴-----┘"

    echo ""
    echo "Laufende Projekte: $nr"
    echo ""

    else
        echo "Keine unvollständigen/laufenden Projekte gefunden."
    fi
}

function fertigmenu {

#                     ██  ██       ██    ██████      ███████ ███████ ██████  
#                    ████████     ███         ██     ██      ██      ██   ██ 
#    █████ █████      ██  ██       ██     █████      █████   █████   ██████  
#                    ████████      ██    ██          ██      ██      ██   ██ 
#                     ██  ██       ██ ██ ███████     ██      ███████ ██   ██ 

        clear
        intro
        echo "Menü 2.1: Fertige Projekte"
        echo ""

        # Liste der Dateien im Verzeichnis abrufen
        file_list=$(find "$data" -maxdepth 1 -type f -name *.complete 2>/dev/null)

        # Überprüfen, ob Dateien gefunden wurden
        if [ -n "$file_list" ]; then

            echo "┌-----┬--------------------------┬--------┬-------┬-----------------------┐"
            echo "| ID  |       Projektname        | Bilder | Intrv |     Aufnahmedatum     |"
            echo "├-----┼--------------------------┼--------┼-------┼-----------------------┤"

            # Schleife über die Dateien
            for file in $file_list; do

                # Projektnummer und Projektnamen extrahieren
                projektnummer=$(echo "$file" | awk -F'/' '{print $NF}' | cut -d '.' -f 2)
                projektname=$(echo "$file" | awk -F'/' '{print $NF}' | cut -d '.' -f 3 | sed 's/_/ /g')
                bildanzahl=$(find $pfad/$projektnummer* -type f | wc -l)
                intervall=$(echo "$file" | awk -F'/' '{print $NF}' | cut -d '.' -f 5)

                #auffüllen auf x Zeichen
                projektname=$(fillortrim "$projektname" "24")
                bildanzahl=$(fillortrim "$bildanzahl" "6")
                intervall=$(fillortrim "$intervall" "5")

            # Datei heißt: 2402461216.......jpg
            # Extrahiere den Zeitstempel der ersten Datei
            erste_datei=$(ls $pfad/$projektnummer* | head -n 1)
            v_jahr=$(echo $erste_datei | cut -b 1-2)
            v_monat=$(echo $erste_datei | cut -b 3-4)
            v_tag=$(echo $erste_datei | cut -b 5-6)

            # Extrahiere den Zeitstempel der letzten Datei
            letzte_datei=$(ls -r $pfad/$projektnummer* | head -n 1)
            b_jahr=$(echo $letzte_datei | cut -b 1-2)
            b_monat=$(echo $letzte_datei | cut -b 3-4)
            b_tag=$(echo $letzte_datei | cut -b 5-6)

            # Erstelle das gewünschte Format
            von="$v_tag.$v_monat.$v_jahr"
            bis="$b_tag.$b_monat.$b_jahr"

            if [ "$datum_heute" = "$von" ]; then
                von=$(fillortrim "heute" "8")
            fi

            if [ "$datum_heute" = "$bis" ]; then
                bis=$(fillortrim "heute" "8")
            fi

            if [ "$von" = "$bis" ]; then
                rec="$von"
                rec=$(fillortrim "        $rec" "21")
            else
                rec="$von bis $bis"
            fi

                echo "| $projektnummer | $projektname | $bildanzahl | $intervall | $rec |"
            done

            echo "└-----┴--------------------------┴--------┴-------┴-----------------------┘"

        else
            echo "Keine fertigen Projekte gefunden."
            exit 0
        fi

        echo ""
        read -p "Projektnummer zur weiteren Bearbeitung: " projekt

        projektname=$(find "$data" -name .$projekt.* | awk -F'/' '{print $NF}' | cut -d '.' -f 3 | sed 's/_/ /g')
        bildanzahl=$(find $pfad/$projekt* -type f | wc -l)
        intervall=$(find "$data" -name .$projekt.* | awk -F'/' '{print $NF}' | cut -d '.' -f 5)

        # Überprüfen, ob die Variable leer ist
        if [ -z "$projektname" ]; then
            echo "Fehler, Projekt-ID existiert nicht."
            exit 1
        fi

        echo "• OK, Projekt $projekt: $projektname ausgewählt."

#                     ██  ██      ██████ 
#                    ████████          ██
#    █████ █████      ██  ██       █████ 
#                    ████████     ██     
#                     ██  ██      ███████

        echo ""
        echo "1 - Video erstellen"
        echo "2 - Projekt löschen"
        echo ""
        read -p "Auswahl: " auswahl

#                     ██  ██      ██████      ██     ██     ██    ██ ██ ██████  
#                    ████████          ██    ███    ███     ██    ██ ██ ██   ██ 
#    █████ █████      ██  ██       █████      ██     ██     ██    ██ ██ ██   ██ 
#                    ████████     ██          ██     ██      ██  ██  ██ ██   ██ 
#                     ██  ██      ███████ ██  ██ ██  ██       ████   ██ ██████  

        if [ "$auswahl" = "1" ]; then

            # Bilder chronologisch absteigend sortieren und in die Bildliste schreiben
            find "$pfad/$projekt"* -type f -name "*.jpg" -printf "file '%p'\n" | sort > "$data/$projekt-liste.txt"

            # Extrahiere den Zeitstempel der ersten Datei
erste_datei=$(find "$pfad/$projekt"* -type f -name "*.jpg" | sort | head -n 1)
dateiname_erst=$(basename "$erste_datei")
v_jahr=${dateiname_erst:0:2}
v_monat=${dateiname_erst:2:2}
v_tag=${dateiname_erst:4:2}

# Extrahiere den Zeitstempel der letzten Datei
letzte_datei=$(find "$pfad/$projekt"* -type f -name "*.jpg" | sort -r | head -n 1)
dateiname_letzt=$(basename "$letzte_datei")
b_jahr=${dateiname_letzt:0:2}
b_monat=${dateiname_letzt:2:2}
b_tag=${dateiname_letzt:4:2}

if [ -z "$erste_datei" ] || [ -z "$letzte_datei" ]; then
    echo "[FEHLER] Keine Bilddateien gefunden."
    exit 1
fi

            # Erstelle das gewünschte Format
            von="$v_tag.$v_monat.$v_jahr"
            bis="$b_tag.$b_monat.$b_jahr"

            if [ "$von" = "$bis" ]; then
    echo "Aufnahmedatum: $von"
else
    echo "Aufnahmedatum: $von bis $bis"
fi


            echo "• Video Creator"
            echo ""
            echo "Projektname: $projektname"
            echo "Anzahl Bilder: $bildanzahl"

            if [ ! "$intervall" = "cron" ]; then
                echo "Intervall: $intervall Sekunden"
            fi

            echo ""

            read -p "Wieviel FPS (Frames per Second) soll das Video haben?: " fps

            while true; do
                echo " - ZUSAMMENFASSUNG -"
                echo ""
                echo "ID           : $projekt"
                echo "Name         : $projektname"
                echo "Bilderanzahl : $bildanzahl"
                
                if [ ! "$intervall" = "cron" ]; then
                echo "Intervall: $intervall Sekunden"
            fi
                
                echo "FPS          : $fps"
                echo "Videolänge   : $(($bildanzahl / $fps)) Sekunden / $((($bildanzahl / $fps + 20) / 60)) Minuten" # Sekunden +20 / 60 = Min

                if [ "$von" = "$bis" ]; then
                    echo "Aufnahmedatum: $von"
                else
                    echo "Aufnahmedatum: $von bis $bis"
                fi

                echo ""
                read -p "OK? >> ENTER / FPS ändern: " fps2

                if [ -z "$fps2" ]; then
                    break
                else
                    echo ""
                    fps=$fps2
                fi        
            done

            echo ""
            echo "Okay, Projekt $projekt - $projektname wird visualisiert. Bitte warten..."
            sleep 3

            if [ "$von" = "$bis" ]; then
                ffmpeg -f concat -safe 0 -r "$fps" -i "$data/$projekt-liste.txt" -vcodec libx264 "$pfad/Video $projekt - $projektname - $von (${bildanzahl}Stk - ${fps}fps - $(($bildanzahl / $fps))s).mp4"
            else
                ffmpeg -f concat -safe 0 -r "$fps" -i "$data/$projekt-liste.txt" -vcodec libx264 "$pfad/Video $projekt - $projektname - $von bis $bis (${bildanzahl}Stk - ${fps}fps - $(($bildanzahl / $fps))s).mp4"
            fi

            rm "$data/$projekt-liste.txt"

            clear
            intro

            echo "ID           : $projekt"
            echo "Name         : $projektname"
            echo "Videolänge   : $(($bildanzahl / $fps)) Sekunden / $((($bildanzahl / $fps + 20) / 60)) Minuten" # Sekunden +20 / 60 = Min
            echo ""

            echo "Video gespeichert."

            echo "Soll dieses Video in mehrere Videos aufgeteilt werden? Wenn ja, Anzahl, wenn nein, einfach ENTER."
            read -p "Anzahl: " teile

            # wenn Teile angegeben wird, teile das Video
            if [ -n "$teile" ]; then
                laenge="$(($bildanzahl / $fps))"
                segmentdauer=$(echo "$laenge / $teile" | bc)

                if [ "$segmentdauer" -le 0 ]; then
                    echo "Fehler: Segmentdauer ist zu kurz. Überprüfe die Eingaben."
                    exit 1
                fi

                if [ "$von" = "$bis" ]; then
                    for ((i=0; i<teile; i++)); do
                        start_time=$(echo "$i * $segmentdauer" | bc)
                        ffmpeg -i "$pfad/Video $projekt - $projektname - $von (${bildanzahl}Stk - ${fps}fps - $(($bildanzahl / $fps))s).mp4" -ss "$start_time" -t "$segmentdauer" -c copy "$pfad/Video $projekt - $projektname - $von (${bildanzahl}Stk - ${fps}fps - $(($bildanzahl / $fps))s) - Teil $((i + 1)) von $teile.mp4"
                    done
                    rm "$pfad/Video $projekt - $projektname - $von (${bildanzahl}Stk - ${fps}fps - $(($bildanzahl / $fps))s).mp4"
                else
                    for ((i=0; i<teile; i++)); do
                        start_time=$(echo "$i * $segmentdauer" | bc)
                        ffmpeg -i "$pfad/Video $projekt - $projektname - $von bis $bis (${bildanzahl}Stk - ${fps}fps - $(($bildanzahl / $fps))s).mp4" -ss "$start_time" -t "$segmentdauer" -c copy "$pfad/Video $projekt - $projektname - $von bis $bis (${bildanzahl}Stk - ${fps}fps - $(($bildanzahl / $fps))s) - Teil $((i + 1)) von $teile.mp4"
                    done
                    rm "$pfad/Video $projekt - $projektname - $von bis $bis (${bildanzahl}Stk - ${fps}fps - $(($bildanzahl / $fps))s).mp4"
                fi
                echo "$i Teile gespeichert."
            fi

            # Protokolliere ins LOG
            echo "$(date +"%d.%m.%y %H:%M:%S") :: Video erstellt mit $fps FPS" >> "$data/exec-log/$projekt - $projektname.txt"

            echo ""
            echo "Projekt $projekt mit dem Namen $projektname wurde visualisiert."
            echo ""
            echo "Projekt abschließen? Falls nein, kann das Video überarbeitet / neu erstellt werden."
            read -p "ja/nein: " auswahl

            auswahl2=$(echo "$auswahl" | sed 's/.*/\L&/')

            if [ "$auswahl2" = "ja" ]; then
                rm $data/.$projekt*.complete
                rm -r $pfad/$projekt*
            else
                echo ""
                echo "Projekt nicht abgeschlossen."
                echo "Vorgang kann wiederholt werden, um den FPS-Wert fürs Video anzupassen."
            fi

            echo ""
            echo "Fertig."
            exit 0

#                     ██  ██      ██████      ██    ██████          ██████  ███████ ██      
#                    ████████          ██    ███         ██         ██   ██ ██      ██      
#    █████ █████      ██  ██       █████      ██     █████          ██   ██ █████   ██      
#                    ████████     ██          ██    ██              ██   ██ ██      ██      
#                     ██  ██      ███████ ██  ██ ██ ███████         ██████  ███████ ███████ 

        elif [ "$auswahl" = "2" ]; then
            echo "• Projekt löschen"
            echo ""
            read -p "Wirklich löschen? Ja oder nein: " auswahl

            auswahl2=$(echo "$auswahl" | sed 's/.*/\L&/')

            if [ "$auswahl2" = "ja" ]; then
                rm $data/.$projekt*.complete
                find "$pfad" -type d -name $projekt* -exec rm -r {} +

                # Protokolliere ins LOG
                echo "$(date +"%d.%m.%y %H:%M:%S") :: Projekt gelöscht" >> $data/exec-log/$projekt*.txt
                
                echo "Projekt $projekt gelöscht."
                exit 0
            fi

            if [ -z "$auswahl" ]; then
                echo "Weder ja noch nein ausgewählt, nichts passiert."
                exit 0
            fi
        fi
}

function abschliessen {

#                     ██  ██       ██    ██████       █████  ██████  ███████  ██████ ██   ██ ██      
#                    ████████     ███         ██     ██   ██ ██   ██ ██      ██      ██   ██ ██      
#    █████ █████      ██  ██       ██     █████      ███████ ██████  ███████ ██      ███████ ██      
#                    ████████      ██         ██     ██   ██ ██   ██      ██ ██      ██   ██ ██      
#                     ██  ██       ██ ██ ██████      ██   ██ ██████  ███████  ██████ ██   ██ ███████ 

        clear
        intro
        echo "Menü 3.1: Projekt abschließen/abbrechen"
        echo ""
        echo "Ist ein Projekt abgebrochen, oder in jedem Fall nicht automatisch erfolgreich abgeschlossen worden,"
        echo "wird es natürlich nicht als \"fertig\" gekennzeichnet."
        echo "Auf diese Art und Weise kann ein laufendes Projekt auch abgebrochen werden."
        echo "Um diesen Status \"fertig\" zu erreichen, damit weitere Aktionen möglich sind, wie ein Video erstellen,"
        echo "kann hier das Projekt manuell abgeschlossen werden."
        echo "Es wird dann der abgebrochene Stand bei den Bildern berückstichtigt, nicht der Soll-Bilder-Wert."
        echo ""

        # Liste der Dateien im Verzeichnis abrufen
        file_list=$(find "$data" -maxdepth 1 -type f -name *.incomplete 2>/dev/null)

        # Überprüfen, ob Dateien gefunden wurden
        if [ -n "$file_list" ]; then

            echo "┌-----┬--------------------------┬--------┬-------┬-----------------------┐"
            echo "| ID  |       Projektname        | Bilder | Intrv |     Aufnahmedatum     |"
            echo "├-----┼--------------------------┼--------┼-------┼-----------------------┤"

            # Schleife über die Dateien
            for file in $file_list; do

                # Projektnummer und Projektnamen extrahieren
                projektnummer=$(echo "$file" | awk -F'/' '{print $NF}' | cut -d '.' -f 2)
                projektname=$(echo "$file" | awk -F'/' '{print $NF}' | cut -d '.' -f 3 | sed 's/_/ /g')
                bildanzahl=$(find "$pfad/$projektnummer"* -type f -name "*.jpg" | wc -l)
                intervall=$(echo "$file" | awk -F'/' '{print $NF}' | cut -d '.' -f 5)

                #auffüllen auf x Zeichen
                projektname=$(fillortrim "$projektname" "24")
                bildanzahl=$(fillortrim "$bildanzahl" "6")
                intervall=$(fillortrim "$intervall" "5")

                # Extrahiere den Zeitstempel der ersten Datei
                erste_datei=$(ls $pfad/$projektnummer* | head -n 1)
                v_jahr=$(echo $erste_datei | cut -b 1-2)
                v_monat=$(echo $erste_datei | cut -b 3-4)
                v_tag=$(echo $erste_datei | cut -b 5-6)
    
                # Extrahiere den Zeitstempel der letzten Datei
                letzte_datei=$(ls -r $pfad/$projektnummer* | head -n 1)
                b_jahr=$(echo $letzte_datei | cut -b 1-2)
                b_monat=$(echo $letzte_datei | cut -b 3-4)
                b_tag=$(echo $letzte_datei | cut -b 5-6)
    
                # Erstelle das gewünschte Format
                von="$v_tag.$v_monat.$v_jahr"
                bis="$b_tag.$b_monat.$b_jahr"
    
                if [ "$datum_heute" = "$von" ]; then
                    von=$(fillortrim "heute" "8")
                fi
    
                if [ "$datum_heute" = "$bis" ]; then
                    bis=$(fillortrim "heute" "8")
                fi
    
                if [ "$von" = "$bis" ]; then
                    rec="$von"
                    rec=$(fillortrim "        $rec" "21") # 7 Leerzeichen voranstellen
                else
                    rec=$(fillortrim "$rec" "24")
                    rec="$von bis $bis"
                fi

                echo "| $projektnummer | $projektname | $bildanzahl | $intervall | $rec |"
            done

            echo "└-----┴--------------------------┴--------┴-------┴-----------------------┘"

            echo ""
            read -p "Projektnummer zur weiteren Bearbeitung: " projekt

            echo "• OK, Projekt $projekt ausgewählt."

            #Sammle Informationen nur über das ausgewählte Projekt
            file=$(find $data/.$projekt*.incomplete 2>/dev/null)
            projektnummer=$(echo "$file" | awk -F'/' '{print $NF}' | cut -d '.' -f 2)
            projektname=$(echo "$file" | awk -F'/' '{print $NF}' | cut -d '.' -f 3)
            bildanzahl_real=$(find "$pfad/$projektnummer"* -type f -name "*.jpg" | wc -l)
            intervall=$(echo "$file" | awk -F'/' '{print $NF}' | cut -d '.' -f 5)

            nameausgabe=$(echo "$projektname" | sed 's/_/ /g')

            # Überprüfen, ob die Variable leer ist
            if [ -z "$file" ]; then
                echo "Fehler, Projekt-ID existiert nicht."
                exit 1
            fi

            echo ""
            echo "Projekt $projekt: $nameausgabe"
            read -p "Abschließen? > ENTER " auswahl

            if [ -z "$auswahl" ]; then
                echo ""
                echo "Projekt wird abgeschlossen..."
                
                mv $data/.$projekt.*.incomplete "$data/.$projekt.$projektname.$bildanzahl_real.$intervall.complete"

                # entferne Projekt aus dem Wiederaufnahme-Script
#                sed -i "/^echo RESUME: Starte $projekt.*/,+1 d" "$data/resume.sh"

                # Protokolliere ins LOG
                echo "$(date +"%d.%m.%y %H:%M:%S") :: Projekt manuell abgeschlossen" >> $data/exec-log/$projekt*.txt

                echo "Fertig."
                exit 0
            fi
        else
            echo "Keine unvollständigen Projekte gefunden."
            exit 0
        fi
}

function modifizieren {

#                     ██  ██       ██    ███████      ██████  ██████  ███    ██ ███████ 
#                    ████████     ███    ██          ██      ██    ██ ████   ██ ██      
#    █████ █████      ██  ██       ██    ███████     ██      ██    ██ ██ ██  ██ █████   
#                    ████████      ██         ██     ██      ██    ██ ██  ██ ██ ██      
#                     ██  ██       ██ ██ ███████      ██████  ██████  ██   ████ ██      

    # $projekt ist normalerweise mit führender Null. Um den Wert aber gültig ersetzen zu können, muss dieses wieder umformatiert werden
    projekt=${projekt#0}

    # Größe von Bytes wieder in KB umrechnen, damit der Wert geändert werden kann
    mingroesse=$((mingroesse / 1024))

    echo "• Konfigurationsbereich"
    echo ""
    echo "1 - Speicherpfad ändern"
    echo "2 - erweitert"
    echo ""
    read -p "Auswahl: " auswahl
    echo ""

    if [ "$auswahl" = "1" ]; then
        echo "• Speicherpfad ändern."
        echo ""

        echo "Speicherpfad bisher: $pfad"
        read -p "ändern zu: " pfadneu

        if [ -z "$pfadneu" ] || [ "${pfadneu:0:1}" != "/" ]; then
            echo "Fehler: Der Pfad darf nicht leer sein und muss zwingend mit einem / beginnen."
            exit 1
        fi

        echo ""
        echo "\"$pfadneu\""
        read -p "Übernehmen? > ENTER"

        mkdir -p "$pfadneu"
        sed -i "s,Pfad = $pfad,Pfad = $pfadneu," "$data/config.txt"
        echo "Pfad geändert."
        exit 0
        
    elif [ "$auswahl" = "2" ]; then
        echo "• Erweiterte Konfigurationseinstellungen."
        echo ""
        echo "Bitte diese Werte nur dann ändern, wenn Du weißt, was Du tust. Manche Dinge rufen Fehler hervor oder funktionieren nicht mehr richtig, wenn Werte willkürlich geändert werden."

        sleep 2

        echo ""
        echo "Folgende Einstellungen sind vorhanden:"
        echo ""
        echo "(1) Offline timeout: $timeout Sekunden"
        echo "    > Sekunden, die gewartet wird, bis das Script erneut versucht, ein Bild herunterzuladen, wenn die Kamera offline ist."
        echo ""

        echo "(2) Testgröße minimum: ${mingroesse}KB"
        echo "    > KB, die ein Bild mindestens haben muss, um als erfolgreiches Bild zu gelten."
        echo ""

        echo "(3) E-Mail nach: $min_err_email Minuten"
        echo "    > Minuten, nach der eine E-Mail versendet wird, wenn die Kamera offline ist.*"
        echo ""

        echo "(4) Nächste Projektnummer: $projekt"
        echo "    > Laufende Projektnummer. Kann z. B. nach Tests korrigiert werden."
        echo ""

        echo "(5) Bilder per E-Mail: $bilderanz Stück"
        echo "    > Anzahl der random Bilder, die bei Beendigung eines Projekts per E-Mail mit der Zusammenfassung mitgesendet werden.*"
        echo ""
        echo "* = Nur relevant bei aktiver E-Mail-Benachrichtigung."
        echo ""

        echo "Was ist zu ändern?"
        echo ""
        read -p "Auswahl: " auswahl

        if [ "$auswahl" = "1" ]; then
            echo "Bisheriger Wert: $timeout Sekunden"
            read -p "Neuer Wert: " timeoutneu

            # Überprüfen, ob der eingegebene Wert eine ganze Zahl und größer als 1 ist
            if ! [[ "$timeoutneu" =~ ^[0-9]+$ ]]; then
                echo "Fehler: Der neue Wert muss eine ganze Zahl sein."
                exit 1
            elif (( timeoutneu <= 1 )); then
                echo "Fehler: Der neue Wert muss größer als 1 sein."
                exit 1
            fi

            echo "Eingegeben: $timeoutneu Sekunden"
            read -p "Übernehmen? > ENTER"
            sed -i "s/Offline timeout = $timeout/Offline timeout = $timeoutneu/" "$data/config.txt"
            echo "OK"
            exit 0



        elif [ "$auswahl" = "2" ]; then
            echo "Bisheriger Wert: ${mingroesse}KB"
            echo "Hinweis: Werte in KB. Eingabe mit oder ohne KB:"
            read -p "Neuer Wert: " mingroesseneu

            # Überprüfe auf eine ganze Zahl, optional gefolgt von "KB" (Groß- oder Kleinschreibung)
            if [[ "$mingroesseneu" =~ ^([0-9]+)([Kk][Bb]?)?$ ]]; then
                # Extrahiere die Zahl aus dem Match
                mingroesseneu="${BASH_REMATCH[1]}"
    
                if (( mingroesseneu < 16 || mingroesseneu > 999 )); then
                    echo "Fehler: Der Wert muss größer als 16KB und kleiner als 999KB sein."
                    exit 1
                fi
            else
                echo "Fehler: Der Wert muss eine ganze Zahl sein und kann mit oder ohne KB eingegeben werden."
                exit 1
            fi

            echo "Eingegeben: ${mingroesseneu}KB"
            read -p "Übernehmen? > ENTER"
            sed -i "s/Testgröße minimum = $mingroesse/Testgröße minimum = $mingroesseneu/" "$data/config.txt"
            echo "OK"
            exit 0



        elif [ "$auswahl" = "3" ]; then
            echo "Bisheriger Wert: $min_err_email Minuten"
            read -p "Neuer Wert: " min_err_emailneu

            # Überprüfen, ob der eingegebene Wert eine ganze Zahl größer als 1 ist
            if ! [[ "$min_err_emailneu" =~ ^[1-9][0-9]*$ ]]; then
                echo "Fehler: Der Wert muss eine ganze Zahl größer als 1 sein."
                exit 1
            fi

            echo "Eingegeben: $min_err_emailneu Minuten"
            read -p "Übernehmen? > ENTER"
            sed -i "s/E-Mail nach = $min_err_email/E-Mail nach = $min_err_emailneu/" "$data/config.txt"
            echo "OK"
            exit 0



        elif [ "$auswahl" = "4" ]; then
            echo "Bisheriger Wert: $projekt"
            echo "Hinweis: Dies ist eine laufende Nummer, standardmäßig beginnend mit 1. Sollten Projekte bereits existieren und dieser Wert existiert doppelt, kann dies zu Fehlern führen. Wert kann zwischen 1 und 999 sein."
            echo ""
            read -p "Neuer Wert: " projektneu

            # Überprüfen, ob der eingegebene Wert eine ganze Zahl größer als 1 ist
            if ! [[ "$projektneu" =~ ^[1-9][0-9]{0,2}$ ]] || (( projektneu < 1 || projektneu > 999 )); then
                echo "Fehler: Der Wert muss eine ganze Zahl zwischen 1 und 999 sein."
                exit 1
            fi

            echo "Eingegeben: $projektneu"
            read -p "Übernehmen? > ENTER"
            sed -i "s/Projekt = $projekt/Projekt = $projektneu/" "$data/config.txt"
            echo "OK"
            exit 0



        elif [ "$auswahl" = "5" ]; then
            echo "Bisheriger Wert: $bilderanz"
            read -p "Neuer Wert: " bilderanzneu

            # Überprüfen, ob der eingegebene Wert eine ganze Zahl zwischen 1 und 20 ist
            if ! [[ "$bilderanzneu" =~ ^[1-9]$|^1[0-9]$|^20$ ]]; then
                echo "Fehler: Der Wert muss eine ganze Zahl zwischen 1 und 20 sein."
                exit 1
            fi

            echo "Eingegeben: $bilderanzneu"
            read -p "Übernehmen? > ENTER"
            sed -i "s/Projekt = $bilderanz/Projekt = $bilderanzneu/" "$data/config.txt"
            echo "OK"
            exit 0

        else
            echo "Keine gültige Auswahl."
            exit 1
        fi
    else
        echo "Keine gültige Auswahl."
        exit 1
    fi
}


#   ██    ██ ██  █████      ███    ███ ███████ ███    ██ ██    ██ 
#   ██    ██ ██ ██   ██     ████  ████ ██      ████   ██ ██    ██ 
#   ██    ██ ██ ███████     ██ ████ ██ █████   ██ ██  ██ ██    ██ 
#    ██  ██  ██ ██   ██     ██  ██  ██ ██      ██  ██ ██ ██    ██ 
#     ████   ██ ██   ██     ██      ██ ███████ ██   ████  ██████  


if [ -z "$1" ] || [ "$1" = "menu" ]; then
    hauptmenu
fi

if [ "$auswahl" = "1" ]; then
    geführt
    exit 0
fi

if [ "$auswahl" = "2" ] || [ "$1" = "fertig" ]; then
    fertigmenu
    exit 0
fi

if [ "$auswahl" = "3" ]; then
    abschliessen
    exit 0
fi

if [ "$auswahl" = "4" ] || [ "$1" = "status" ]; then
    status
    exit 0
fi

if [ "$auswahl" = "5" ]; then
    modifizieren
    exit 0
fi

if [ "$auswahl" = "9" ]; then
    update
    exit 0
fi

exit 0