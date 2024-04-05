#!/bin/bash

#	██    ██ ██████  ██████   █████  ████████ ███████ ██████  
#	██    ██ ██   ██ ██   ██ ██   ██    ██    ██      ██   ██ 
#	██    ██ ██████  ██   ██ ███████    ██    █████   ██████  
#	██    ██ ██      ██   ██ ██   ██    ██    ██      ██   ██ 
#	 ██████  ██      ██████  ██   ██    ██    ███████ ██   ██ 

# Updater & Reverse Updater BEGINN
if [ "$1" = "update" ]; then
	scriptversion=2404052123
	scriptname=$(basename "$0")
	serverping="public.mariobeh.de"
	web_ver="https://public.mariobeh.de/prv/scripte/$scriptname-version.txt"
	web_mirror="https://public.mariobeh.de/prv/scripte/$scriptname"
	int_vers_dat="/srv/web/prv/scripte/$scriptname-version.txt"
	int_mirror="/srv/web/prv/scripte/$scriptname"
	if [ -f "/srv/web/prv/scripte/$scriptname-version.txt" ]; then
		int_vers_num=$(cat "/srv/web/prv/scripte/$scriptname-version.txt" | head -n1 | tail -n1)
	fi
	if [ -f ".keyvalid" ]; then
		keyvalid=$(cat ".keyvalid" | head -n1 | tail -n1)
	fi
	
	if [ ! "$2" = "valid" ]; then
		if [ -f "opt/.keyfile" ] && [ ! "$2" = "valid" ]; then
			passfile=$(cat "opt/.keyfile" | head -n1 | tail -n1)
			read -p "Passkey: " -s passkeyunenc
			passkey=$(echo -n "$passkeyunenc" | sha256sum | cut -d ' ' -f 1)
			if ! [ "${#scriptversion}" -eq "10" ]; then
				echo "Versionsnummer hat eine falsche Länge. Abbruch."
				exit
			fi
			if [ "$passfile" = "$passkey" ]; then
				if [ ! -f "$int_vers_dat" ]; then
					clear
					echo "Erstmaliges Reverse Update"
					echo "Internes Reverse Update von $(basename "$0") wird vorbereitet:"
					sleep 2
					echo "Kopiere auf das Webverzeichnis..."
					echo "$scriptversion" > "$int_vers_dat"
					cp "$scriptname" "$int_mirror"
					echo "Fertig."
					exit
				else
					if [ "$scriptversion" -gt "$int_vers_num" ]; then
						clear
						echo "Internes Reverse Update von $(basename "$0") wird durchgeführt..."
						sleep 2
						echo "Aktualisiere Versionsnummer in der Versionsdatei"
						echo "$scriptversion" > "$int_vers_dat"
						sleep 0.5
						echo "Kopiere aktualisiertes Script in das Downloadverzeichnis"
						cp -f $0 "$int_mirror"
						sleep 0.5
						echo "Fertig."
						exit
					elif [ "$scriptversion" = "$int_vers_num" ]; then
						echo ""
						echo "Nichts zu updaten, Version aktuell."
						exit
					fi
				fi
			else
				echo ""
				echo "Falscher Passkey. Internes Reverse Update nicht möglich."
				exit
			fi
		else
			if nc -z -w 1 "$serverping" 443 2>/dev/null; then
				wget "$web_ver" -q -O ".version"
				if [ -f ".version" ]; then
					serverversion=$(cat ".version" | head -n1 | tail -n1)
					if [ "$serverversion" -gt "$scriptversion" ]; then
						clear
						echo "Eine neue Version von $scriptname ist verfügbar."
						echo ""
						echo "Diese Version: $scriptversion " #($(($(stat -c %s "$0") / 1024)) KB)"
						echo "Neue Version:  $serverversion " #($(($(wget --spider "$web_mirror" 2>&1 | awk '/Length:/ {print $2}' | cut -d'(' -f1) / 1024)) KB)"
						echo ""
						echo "Script wird aktualisiert, bitte warten."
						echo ""
						sleep 3
						echo "Download"
						wget -q -N "$web_mirror"
						sleep 0.5
						echo "Fertig."
						echo "Validiere Update..."
						sleep 1
						echo "  ↳ Zu Manipulationszwecken wird ein Schlüssel erstellt"
						keyvalid=$(head -c 32 /dev/random | base64 | tr -d '+/=')
						echo "$keyvalid" > ".keyvalid"
						sleep 0.5
						echo "  ↳ Starte Script neu, wende Schlüssel an"
						$0 update valid $keyvalid
						exit
					else
						echo "Kein Update erforderlich, Version aktuell."
						rm ".version"
						exit
					fi
				else
					echo "Konnte Versionsdatei nicht herunterladen, Update fehlgeschlagen."
					exit
				fi
			else
				echo "Keine Verbindung zum Server, Update fehlgeschlagen."
				exit
			fi
		fi
	fi
	if [ "$2" = "valid" ]; then
		echo "  ↳ Überprüfe Schlüssel"
		if [ "$3" = "$keyvalid" ]; then
			echo "  ↳ Schlüssel OK"
			rm ".keyvalid"
			sleep 0.5
			echo "  ↳ Überprüfe Update"
			serverversion=$(cat ".version" | head -n1 | tail -n1)
			if [ "$serverversion" = "$scriptversion" ]; then
				sleep 0.5
				echo "  ↳ Update erfolgreich abgeschlossen."
			else
				sleep 0.5
				echo "   -- Serverversion: $serverversion"
				echo "   -- Scriptversion: $scriptversion"
				echo "  ↳ Update fehlgeschlagen."
			fi
			rm ".version"
			exit
		else
			echo "Key falsch, Manipulation? Update kann nicht validiert werden."
			exit
		fi
	fi
fi
# Updater & Reverse Updater ENDE

#	 █████  ██      ██       ██████  ███████ ███    ███ ███████ ██ ███    ██ 
#	██   ██ ██      ██      ██       ██      ████  ████ ██      ██ ████   ██ 
#	███████ ██      ██      ██   ███ █████   ██ ████ ██ █████   ██ ██ ██  ██ 
#	██   ██ ██      ██      ██    ██ ██      ██  ██  ██ ██      ██ ██  ██ ██ 
#	██   ██ ███████ ███████  ██████  ███████ ██      ██ ███████ ██ ██   ████ 

user=$(whoami)
data="/home/$user/script-data/webcamloader"

if [ ! -d "$data" ]; then
	mkdir -p "$data"
fi

if [ ! -d "$data/exec-log" ]; then
	mkdir -p "$data/exec-log"
fi

if [ ! -f "$data/config.txt" ]; then
	echo ""
	echo "Der Webcamloader wird zum ersten Mal ausgeführt."
	echo "Die Konfigurationsdatei wird erstellt..."

	echo "[Config]" > "$data/config.txt"
	echo "Projekt = 100 #Projektnummern - beginnend mit 100, kann geändert werden" >> "$data/config.txt"
	echo "Offline warten = 10 #Sekunden, in denen gewartet wird, wenn die Kamera offline ist" >> "$data/config.txt"
	echo "Testgrößenlimit = 4096 #Byte - Testgröße, die das Testbild mindestens haben soll, ehe es nicht als Bild identifiziert werden kann" >> "$data/config.txt"

	read -p "Speicherpfad für das Arbeitsverzeichnis, in welchem Bilder und Videos erstellt werden: " pfad
	echo ""

	if [ -z "$pfad" ]; then
		echo "Pfad = $data/Arbeit #Beispiel. Muss ein Pfad sein, in dem Bilder und Videos gespeichert werden" >> "$data/config.txt"
	else
		echo "Pfad = $pfad #Pfad, in dem Bilder und Videos gespeichert werden" >> "$data/config.txt"
	fi

	echo "Eingegebener Pfad wird erstellt, wenn noch nicht vorhanden: $pfad"

	if [ ! -d "$pfad" ]; then
		mkdir -p "$pfad"
		echo "OK"
	else
		echo "Bereits vorhanden, nichts zu tun."
	fi

	echo ""
	echo "Folgende Pakete müssen installiert sein um einen reibungslosen Ablauf zu gewährleisten:"
	echo "zip tar screen ffmpeg netcat-traditional"
	echo "Dies ist eigenverantwortlich zu installieren. Das kann im Anschluss durchgeführt werden."
	echo ""
	read -p "OK (ENTER)"

	touch "$data/.installed"
fi

# Lese Werte aus Config ein
projekt=$(grep -w "Projekt" "$data/config.txt" | cut -d '=' -f 2 | cut -d '#' -f 1 | tr -d ' ')
pfad=$(grep -w "Pfad" "$data/config.txt" | cut -d '=' -f 2 | cut -d '#' -f 1 | tr -d ' ')
offwarten=$(grep -w "Offline warten" "$data/config.txt" | cut -d '=' -f 2 | cut -d '#' -f 1 | tr -d ' ')
testgroesse=$(grep -w "Testgrößenlimit" "$data/config.txt" | cut -d '=' -f 2 | cut -d '#' -f 1 | tr -d ' ')

if [ ! -d "$pfad" ]; then
	mkdir -p "$pfad" 2>/dev/null

	# Befehl wiederholen, wenn DIR immernoch fehlt, dann Fehler
	if [ ! -d "$pfad" ]; then
		echo ""
	    echo "Dateiberechtigungen fehlen, Webcamloader kann auf dem Zielverzeichnis \"$pfad\" nicht schreiben."
		exit 1
	fi
fi

# Überprüfe, ob Projekt eine Nummer ist
if [[ ! "$projekt" =~ ^[0-9]+$ ]]; then
	echo "Fehler, Projekt ist keine Nummer!"
	exit 1
fi

# Überprüfe, ob Arbeitsverzeichnis leer oder nicht
if [ $(ls -A $pfad | wc -l) = "0" ]; then
	aktiv="0"
else
	aktiv="1"
fi

#	███████ ██    ██ ███    ██ ██   ██ ████████ ██  ██████  ███    ██ 
#	██      ██    ██ ████   ██ ██  ██     ██    ██ ██    ██ ████   ██ 
#	█████   ██    ██ ██ ██  ██ █████      ██    ██ ██    ██ ██ ██  ██ 
#	██      ██    ██ ██  ██ ██ ██  ██     ██    ██ ██    ██ ██  ██ ██ 
#	██       ██████  ██   ████ ██   ██    ██    ██  ██████  ██   ████ 

function arbeit {

	pingcam=$(echo "$2" | grep -oP '^https?://\K[^:/]+')
	portcam=$(echo "$2" | grep -oP ':\K[0-9]+')

	if [ -z "$portcam" ]; then
		if echo "$2" | grep -q "https"; then
			portcam="443"
		else
			portcam="80"
		fi
	fi

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

	#Bildanzahl nicht über max
	if ! (( "$4" <= "14000" )); then
		echo ""
		echo "Bildanzahl überschritten, maximal 14.000 Bilder möglich!"
		echo "Es kann sonst kein Video erstellt werden."
		err="1"
	fi

	#Pause nur ganze Zahl
	if ! [[ $5 =~ ^[0-9]+$ ]]; then
		echo ""
		echo "Pause: $5"
		echo "Pause darf nur eine ganze, positive Zahl sein."
		err="1"
	fi

	#Bei Fehler: Abbruch
	if [ "$err" = "1" ]; then
		echo ""
		echo "Fehler, Abbruch."
		exit 1
	fi

	#Prüfung, ob der Stream ein Video oder Bild ist
	if echo "$2" | grep -qE '\.mjpg|\.mjpeg|faststream|video\.cgi|GetOneShot|mjpg\.cgi|videostream\.cgi|\/image|\?action\=stream|\/cam_.\.cgi'; then
		video="1"
	
	elif echo "$2" | grep -qE 'snapshot\.cgi|SnapshotJPEG|\.jpg|api\.cgi|cgi-bin\/camera|alarmimage|oneshotimage|image\/Index|CGIProxy\.fcgi|nph-jpeg\.cgi|onvif\/snapshot'; then
		video="0"
	
	elif echo "$2" | grep -qE 'GetData\.cgi|mjpeg\.cgi|\.png'; then
		echo "Kameraformat wird nicht unterstützt. Das Programm kann nicht arbeiten."
		echo "Fehler, Abbruch."
		exit 1
	else
		echo "Kameraformat nicht erkannt. Das Programm kann nicht arbeiten."
		echo "Fehler, Abbruch."
		exit 1
	fi

	#Kritische Zeichen wie . oder / ersetzen
	projektname=$(echo "$3" | sed 's/\./-/g; s/\//-/g')

	#Zusammenfassung
	clear
	echo "Projekt-ID:   $projekt"

	if [ "$3" = "$projektname" ]; then
		echo "Projekt-Name: $3"
	else
		echo "Projekt-Name: $3 -> wird intern zu $projektname"
	fi
	
	echo "Anzahl:       $4"
	echo "Pause:        $5"

	if [ -n "$6" ]; then
	    echo "E-Mail:       $6"
	else
		echo "E-Mail:       keine Benachrichtiung"
    fi

	echo ""
	echo ""

	#Dauererrechnung - theoretisch nach Bildanzahl x Pause
	echo "Dauer etwa $((($4 * $5 / 60) + $4 / 60)) Min., $(($4 * $5 / 60 / 60)) Std., $(($4 * $5 / 60 / 60 / 24)) Tag(e)."
	echo "Theoretisch fertig: am $(date -d "+$((($4 * $5 / 60) + $4 / 60)) minutes" +"%d.%m.%y um %H:%M") Uhr."
	echo ""

	#Setze die theoretisch-fertig-Zeit in eine Variable, um sie permanent anzuzeigen
	fertig="am $(date -d "+$(($4*$5/60)) minutes" +"%d.%m.%y um %H:%M") Uhr."

	if [ "$video" = "1" ]; then
		echo "Kamera liefert einen Videostream"
		ffmpeg -y -i "$2" -analyzeduration 5M -probesize 5M -loglevel quiet -nostats -hide_banner -vframes 1 "$data/$projekt-test.jpg"
	elif [ "$video" = "0" ]; then
		echo "Kamera liefert Bilder"
		wget "$2" -O "$data/$projekt-test.jpg" -a /dev/null
	fi

	echo "Berechne benötigte Speicherkapazität..."

	if [ $(stat -c%s "$data/$projekt-test.jpg") -gt "$testgroesse" ]; then
		ls -l "$data/" | grep "$projekt-test.jpg" | sed "s:     : :g ; s:    : :g ; s:   : :g ; s:  : :g" | cut -d ' ' -f 5 > "$data/$projekt-test.txt"
		groesse=$(cat "$data/$projekt-test.txt" | head -n1 | tail -n1)
		echo ""
		grosse_mb_soll=$(($4*$groesse/1048576))
		echo "Am Ende wird der Projekt-Ordner um die $grosse_mb_soll MB groß sein."
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
	read -p "Download starten? >> ENTER " null

	#erstelle LOG-Datei
	echo "Projekt-ID: $projekt" >> "$data/exec-log/$projekt - $3.txt"
	echo "Kamera-URL: $2" >> "$data/exec-log/$projekt - $3.txt"
	echo "Projektname: $3 ($projektname)" >> "$data/exec-log/$projekt - $3.txt"
	echo "Bildanzahl: $4" >> "$data/exec-log/$projekt - $3.txt"
	echo "Pause: $5" >> "$data/exec-log/$projekt - $3.txt"
	echo "Theoretisches Ende: $fertig" >> "$data/exec-log/$projekt - $3.txt"
	echo "E-Mail: $6" >> "$data/exec-log/$projekt - $3.txt"
	echo "" >> "$data/exec-log/$projekt - $3.txt"

	#ersetze Leerzeichen gegen Unterstriche und setze incomplete-Datei
	nameneu=$(echo "$projektname" | sed 's/ /_/g')
	touch "$data/.$projekt.$nameneu.$4.$5.incomplete"

	#Setze Projekt +1
	neuprojekt=$(($projekt + 1))
	sed -i "s/Projekt = $projekt/Projekt = $neuprojekt/" "$data/config.txt"

	#Projekt-ID-Ordner erstellen mit Bildanzahl
	mkdir "$pfad/$projekt - $projektname (${4}Stk - ${5}s)"

	x="1"

	while [ "$x" -le "$4" ]; do #solange ausführen, bis Anzahl erreicht

		#Prüfe, ob Kamera offline ist
		while ! nc -z -w 1 "$pingcam" "$portcam" 2>/dev/null; do
			clear
			echo "W E B C A M L O A D E R"
			echo ""
			echo ""
			echo "PROJEKT: $projekt - $projektname"
			echo "Theoretisch fertig: $fertig"
			echo ""
			#Ausgabe
			echo "$(date +"%d.%m.%y %H:%M:%S") :: Kamera offline? Prüfe erneut nach $offwarten Sekunden..."
			#Protokolliere
			echo "$(date +"%d.%m.%y %H:%M:%S") :: Kamera offline" >> "$data/exec-log/$projekt - $3.txt"
			sleep "$offwarten"
		done
	
		clear
		echo "W E B C A M L O A D E R"
		echo ""
		echo ""
		echo "PROJEKT: $projekt - $projektname - Pause: ${5}s"
		echo "Theoretisch fertig: $fertig"
		echo ""
		#Ausgabe
		echo "$(date +"%d.%m.%y %H:%M:%S") :: Bild $x von $4 wird erstellt..."
		#Protokolliere
		echo "$(date +"%d.%m.%y %H:%M:%S") :: Bild $x / $4" >> "$data/exec-log/$projekt - $3.txt"

		if [ "$video" = "1" ]; then
			ffmpeg -y -i "$2" -loglevel quiet -nostats -hide_banner -vframes 1 "$pfad/$projekt - $projektname (${4}Stk - ${5}s)/$(date +"%y%m%d%H%M%S - $projektname - $x von $4 (${5}s).jpg")" > "/dev/null"

		elif [ "$video" = "0" ]; then
			wget "$2" -O "$pfad/$projekt - $projektname (${4}Stk - ${5}s)/$(date +"%y%m%d%H%M%S - $projektname - $x von $4 (${5}s).jpg")" -a "/dev/null"
		fi

		sleep "$5"
		x=$(($x + 1))
	done

	clear
	echo "$4 Bild(er) gespeichert mit der Projekt-Nummer $projekt ($projektname)"
	echo "Räume auf: entferne fehlerhafte Bilder, die kleiner sind als $testgroesse Bytes..."

	find "$pfad/$projekt"* -maxdepth 1 -type f -name "*.jpg" -size -${testgroesse}c -exec rm {} \;

	bildanzahl=$(find $pfad/$projekt* -type f | wc -l)

	if [ ! "$4" = "$bildanzahl" ]; then
		echo "Tatsächliche Bilder nach dem Entfernen ungültiger Bilder: $bildanzahl."
	else
		echo "Alle Bilder OK."
	fi

	nameneu=$(echo "$projektname" | sed 's/ /_/g')
	mv $data/.$projekt.*.incomplete "$data/.$projekt.$nameneu.$bildanzahl.$5.fertig"

	dat_org="$pfad/$projekt - $projektname (${4}Stk - ${5}s)"
	dat_mod="$pfad/$projekt - $projektname (${bildanzahl}Stk - ${5}s)"

	if [ ! "$dat_org" = "$dat_mod" ]; then
		mv "$dat_org" "$dat_mod"
	fi

	if [ -n "$6" ]; then
	    echo "Sammle Informationen..."

        # SAMMELN BGEINN
		echo "W E B C A M L O A D E R" >> "$data/email.txt"
		echo "Projekt fertig!" >> "$data/email.txt"
		echo "" >> "$data/email.txt"
		echo "" >> "$data/email.txt"
		echo "Projekt-ID: $projekt" >> "$data/email.txt"
		echo "Projektname: $projektname" >> "$data/email.txt"

		if [ "$4" = "$bildanzahl" ]; then
			echo "Bildanzahl: $bildanzahl Stk." >> "$data/email.txt"
		else
			echo "Bildanzahl soll: $4 Stk." >> "$data/email.txt"
			echo "Bildanzahl ist: $bildanzahl Stk." >> "$data/email.txt"
		fi

		echo "Pause: $5 Sek." >> "$data/email.txt"
		echo "" >> "$data/email.txt"
		echo "Projektgröße errechnet: ${grosse_mb_soll}M" >> "$data/email.txt"
		echo "Projektgröße tatsächlich: $(du -sh $pfad/${projekt}* | cut -d '/' -f 1)" >> "$data/email.txt"
		# SAMMELN ENDE

		echo "Sende E-Mail..."

		cat "$data/email.txt" | mail -s "Webcamloader" "$6"

		rm "$data/email.txt"
	fi

	echo ""
	echo "Fertig."

	exit 0
	}

#	 ██████  ██    ██ ██  ██████ ██   ██ ██    ██
#	██    ██ ██    ██ ██ ██      ██  ██   ██  ██ 
#	██    ██ ██    ██ ██ ██      █████     ████  
#	██ ▄▄ ██ ██    ██ ██ ██      ██  ██     ██   
#	 ██████   ██████  ██  ██████ ██   ██    ██   
#	    ▀▀                                        

if [ "$1" = "quicky" ] && [ -n "$2" ] && [ -n "$3" ] && [ -n "$4" ] && [ -n "$5" ] && [ -f "$data/.installed" ]; then

	arbeit "$1" "$2" "$3" "$4" "$5" "$6"

elif [ "$1" = "quicky" ] && [ -z "$5" ]; then
	echo "Fehler, für den Quicky-Modus fehlt mindestens ein Argument."
	echo "Info:"
	echo "$0 quicky Kamera-URL Projekt-Name Gesamtbilder Pause"
	echo "$0 quicky \"http://172.22.20.36:8000/snapshot.cgi\" \"Alpenpanorama\" 5000 10"
	echo ""
	echo "Darauf achten: Leerzeichen trennt - ist im Namen ein Leerzeichen enthalten, unbedingt mit \" \" arbeiten!"
	echo "Dasselbe gilt bei der Kamera-URL. Sind hier Zeichen wie ein \"&\", muss ebenfalls mit \" \" gearbeitet werden!"
	echo ""
	echo "Hinweis:"
	echo "\$1 = quicky"
	echo "\$2 = Kamera-URL"
	echo "\$3 = Name des Projekts"
	echo "\$4 = Bildanzahl"
	echo "\$5 = Pause zwischen Bildern"
	echo "\$6 = E-Mail-Adresse zum Benachrichtigen wenn Projekt fertig (optional)"
	exit 1
fi

#	███    ███ ███████ ███    ██ ██    ██ ███████ ███████ ██   ██ ████████  ██████  ██████  
#	████  ████ ██      ████   ██ ██    ██ ██      ██      ██  ██     ██    ██    ██ ██   ██ 
#	██ ████ ██ █████   ██ ██  ██ ██    ██ ███████ █████   █████      ██    ██    ██ ██████  
#	██  ██  ██ ██      ██  ██ ██ ██    ██      ██ ██      ██  ██     ██    ██    ██ ██   ██ 
#	██      ██ ███████ ██   ████  ██████  ███████ ███████ ██   ██    ██     ██████  ██   ██ 

if [ -z "$1" ]; then

#	projektneu=$(grep -w "Projekt" "$data/config.txt" | cut -d '=' -f 2 | cut -d '#' -f 1 | tr -d ' ')
#	projekt=$((projektneu - 1))

	clear
	echo "W E B C A M L O A D E R"
	echo ""
	echo ""
	echo "Willkommen! ••• Menü."
	echo ""

#	                 ██  ██       ██ 		██   ██  █████  ██    ██ ██████  ████████
#	                ████████     ███ 		██   ██ ██   ██ ██    ██ ██   ██    ██   
#	█████ █████      ██  ██       ██ 		███████ ███████ ██    ██ ██████     ██   
#	                ████████      ██ 		██   ██ ██   ██ ██    ██ ██         ██   
#	                 ██  ██       ██ 		██   ██ ██   ██  ██████  ██         ██   

	echo "1 - Geführter Modus"
	echo "2 - Fertige Projekte"
	echo "3 - Projekt abschließen"
#	echo "4 - Status laufender Projekte"

	echo ""
	read -p "Auswahl: " auswahl
	echo ""

#	                 ██  ██       ██     ██ 		 ██████  ███████ ███████ 
#	                ████████     ███    ███ 		██       ██      ██      
#	█████ █████      ██  ██       ██     ██ 		██   ███ █████   █████   
#	                ████████      ██     ██ 		██    ██ ██      ██      
#	                 ██  ██       ██ ██  ██ 		 ██████  ███████ ██      

	if [ "$auswahl" = "1" ]; then
		clear
		echo "W E B C A M L O A D E R"
		echo ""
		echo ""
		echo "Menü 1.1: Geführter Modus"
		echo ""
		echo "In diesem Menü werden nacheinander die Parameter abgefragt, die für das Programm wichtig sind."
		echo "Geprüft werden die Eingaben zum Abschluss"
		echo ""
		echo ""
		echo "Bitte nacheinander Parameter eingeben:"
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

		# Anzahl Abfrage mit Prüfung
		while true; do
		    read -p "Wie viele Bilder insgesamt: " anzahl
		    if [[ $anzahl =~ ^[1-9][0-9]*$ && $anzahl -ge 1 && $anzahl -le 14000 ]]; then
		        break
		    else
		        echo "Bildanzahl ungültig. Bitte eine Bildanzahl bis max. 14000 eingeben."
		    fi
		done

		# Pause Abfrage mit Prüfung
		while true; do
		    read -p "Pause zwischen Bildern: " pause
		    if [[ $pause =~ ^[0-9]+$ && -n $pause ]]; then
		        break
		    else
		        echo "Pause ungültig. Bitte geben Sie eine Zahl ein."
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

#		arbeit "$1"     "$2"   "$3"    " $4"     "$5"     "$6"
		arbeit "menu" "$url" "$name" "$anzahl" "$pause" "$email"
	fi

#	                 ██  ██       ██    ██████  	███████ ███████ ██████  
#	                ████████     ███         ██ 	██      ██      ██   ██ 
#	█████ █████      ██  ██       ██     █████  	█████   █████   ██████  
#	                ████████      ██    ██      	██      ██      ██   ██ 
#	                 ██  ██       ██ ██ ███████ 	██      ███████ ██   ██ 

	if [ "$auswahl" = "2" ]; then
		clear
		echo "W E B C A M L O A D E R"
		echo ""
		echo ""
		echo "Menü 2.1: Fertige Projekte"
		echo ""

		# Liste der Dateien im Verzeichnis abrufen
		file_list=$(find "$data" -maxdepth 1 -type f -name *.fertig 2>/dev/null)

		# Überprüfen, ob Dateien gefunden wurden
		if [ -n "$file_list" ]; then

			# Schleife über die Dateien
			for file in $file_list; do

				# Projektnummer und Projektnamen extrahieren
				projektnummer=$(echo "$file" | awk -F'/' '{print $NF}' | cut -d '.' -f 2)
				projektname=$(echo "$file" | awk -F'/' '{print $NF}' | cut -d '.' -f 3 | sed 's/_/ /g')
				bildanzahl=$(echo "$file" | awk -F'/' '{print $NF}' | cut -d '.' -f 4)
				pause=$(echo "$file" | awk -F'/' '{print $NF}' | cut -d '.' -f 5)

				echo "$projektnummer - $projektname - Bildanzahl: $bildanzahl - Pause: $pause"
			done
		else
			echo "Keine fertigen Projekte gefunden."
			exit 0
		fi

		echo ""
		read -p "Projektnummer zur weiteren Bearbeitung: " projekt

		projektname=$(find "$data" -name .$projekt.* | awk -F'/' '{print $NF}' | cut -d '.' -f 3 | sed 's/_/ /g')
		bildanzahl=$(find "$data" -name .$projekt.* | awk -F'/' '{print $NF}' | cut -d '.' -f 4)
		pause=$(find "$data" -name .$projekt.* | awk -F'/' '{print $NF}' | cut -d '.' -f 5)

		echo "• OK, Projekt $projekt: $projektname ausgewählt."

#	                 ██  ██      ██████ 
#	                ████████          ██
#	█████ █████      ██  ██       █████ 
#	                ████████     ██     
#	                 ██  ██      ███████

		echo ""
		echo "1 - Video erstellen"
		echo "2 - Projekt löschen"
		echo ""
		read -p "Auswahl: " auswahl

#	                 ██  ██      ██████      ██     ██     ██    ██ ██ ██████  
#	                ████████          ██    ███    ███     ██    ██ ██ ██   ██ 
#	█████ █████      ██  ██       █████      ██     ██     ██    ██ ██ ██   ██ 
#	                ████████     ██          ██     ██      ██  ██  ██ ██   ██ 
#	                 ██  ██      ███████ ██  ██ ██  ██       ████   ██ ██████  

		if [ "$auswahl" = "1" ]; then
			echo "• Video Creator"
			echo ""
			echo "Projektname: $projektname"
			echo "Anzahl Bilder: $bildanzahl"
			echo ""
			read -p "Wieviel FPS (Frames per Second) soll das Video haben?: " fps
			echo "$fps FPS."
			echo ""

			# Datei heißt: 2403261216.......jpg
			# Extrahiere den Zeitstempel der ersten Datei
			erste_datei=$(ls $pfad/$projekt* | head -n 1)
			v_jahr=$(echo $erste_datei | cut -b 1-2)
			v_monat=$(echo $erste_datei | cut -b 3-4)
			v_tag=$(echo $erste_datei | cut -b 5-6)

			# Extrahiere den Zeitstempel der letzten Datei
			letzte_datei=$(ls -r $pfad/$projekt* | head -n 1)
			b_jahr=$(echo $letzte_datei | cut -b 1-2)
			b_monat=$(echo $letzte_datei | cut -b 3-4)
			b_tag=$(echo $letzte_datei | cut -b 5-6)

			# Erstelle das gewünschte Format
#			von="$v_jahr-$v_monat-$v_tag"
#			bis="$b_jahr-$b_monat-$b_tag"
			von="$v_tag.$v_monat.$v_jahr"
			bis="$b_tag.$b_monat.$b_jahr"

			echo "- ZUSAMMENFASSUNG -"
			echo ""
			echo "ID:            $projekt"
			echo "Name:          $projektname"
			echo "Bilderanzahl:  $bildanzahl"
			echo "FPS:           $fps"
			echo "Videolänge:    $(($bildanzahl / $fps)) Sekunden"

			if [ "$von" = "$bis" ]; then
				echo "Aufnahmedatum: $von"
			else
				echo "Aufnahmedatum: $von bis $bis"
			fi

			echo ""
			echo ""
			read -p "OK? >> ENTER" null
			echo ""
			echo "Okay, Projekt $projekt - $projektname wird visualisiert. Bitte warten..."
			sleep 3

			if [ "$von" = "$bis" ]; then
				cat $pfad/$projekt*/*.jpg | ffmpeg -f image2pipe -r $fps -hide_banner -framerate 1 -i - -vcodec libx264 "$pfad/Video $projekt - $projektname - $von (${bildanzahl}Stk - ${fps}fps - $(($bildanzahl / $fps))s).mp4"
			else
				cat $pfad/$projekt*/*.jpg | ffmpeg -f image2pipe -r $fps -hide_banner -framerate 1 -i - -vcodec libx264 "$pfad/Video $projekt - $projektname - $von bis $bis (${bildanzahl}Stk - ${fps}fps - $(($bildanzahl / $fps))s).mp4"
			fi

			# Protokolliere ins LOG
			echo "$(date +"%d.%m.%y %H:%M:%S") :: VIDEO ERSTELLT - FPS: $fps" >> "$data/exec-log/$projekt - $3.txt"

			echo ""
			echo "Projekt $projekt mit dem Namen $projektname wurde visualisiert."
			echo ""
			echo "Projekt abschließen? Falls nein, kann das Video überarbeitet / neu erstellt werden."
			read -p "Projekt abschließen? Ja/nein: " auswahl

			auswahl2=$(echo "$auswahl" | sed 's/.*/\L&/')

			if [ "$auswahl2" = "ja" ]; then
				rm $data/.$projekt*.fertig
				rm -r $pfad/$projekt*
			else
				echo ""
				echo "Projekt nicht abgeschlossen."
				echo "Vorgang kann wiederholt werden, um den FPS-Wert fürs Video anzupassen."
			fi

			echo ""
			echo "Fertig."
			exit 0

#	                 ██  ██      ██████      ██    ██████  		██████  ███████ ██      
#	                ████████          ██    ███         ██ 		██   ██ ██      ██      
#	█████ █████      ██  ██       █████      ██     █████  		██   ██ █████   ██      
#	                ████████     ██          ██    ██      		██   ██ ██      ██      
#	                 ██  ██      ███████ ██  ██ ██ ███████ 		██████  ███████ ███████ 

		elif [ "$auswahl" = "2" ]; then
			echo "• Projekt löschen"
			echo ""
			read -p "Wirklich löschen? Ja oder nein: " auswahl

			auswahl2=$(echo "$auswahl" | sed 's/.*/\L&/')

			if [ "$auswahl2" = "ja" ]; then
				rm $data/.$projekt*.fertig
				find "$pfad" -type d -name $projekt* -exec rm -r {} +
				
				echo "Projekt $projekt gelöscht."
				exit 0
			fi

			if [ -z "$auswahl" ]; then
				echo "Weder ja noch nein ausgewählt, nichts passiert."
			    exit 0
            fi
		fi
	fi

#	                 ██  ██       ██    ██████  	 █████  ██████  ███████  ██████ ██   ██ ██      
#	                ████████     ███         ██ 	██   ██ ██   ██ ██      ██      ██   ██ ██      
#	█████ █████      ██  ██       ██     █████  	███████ ██████  ███████ ██      ███████ ██      
#	                ████████      ██         ██ 	██   ██ ██   ██      ██ ██      ██   ██ ██      
#	                 ██  ██       ██ ██ ██████  	██   ██ ██████  ███████  ██████ ██   ██ ███████ 

	if [ "$auswahl" = "3" ]; then
		clear
		echo "W E B C A M L O A D E R"
		echo ""
		echo ""
		echo "Menü 3.1: Projekt abschließen"
		echo ""
		echo "Ist ein Projekt abgebrochen, oder in jedem Fall nicht automatisch erfolgreich abgeschlossen worden,"
		echo "wird es natürlich nicht als \"fertig\" gekennzeichnet."
		echo "Um diesen Status dennoch zu erreichen, damit weitere Aktionen möglich sind, wie ein Video erstellen,"
		echo "kann hier das Projekt manuell abgeschlossen werden."
		echo "Es wird dann der abgebrochene Stand bei den Bildern berückstichtigt, nicht der Soll-Bilder-Wert."
		echo ""
		echo ""

		# Liste der Dateien im Verzeichnis abrufen
		file_list=$(find "$data" -maxdepth 1 -type f -name *.incomplete 2>/dev/null)

		# Überprüfen, ob Dateien gefunden wurden
		if [ -n "$file_list" ]; then

			# Schleife über die Dateien
			for file in $file_list; do

				# Projektnummer und Projektnamen extrahieren
				projektnummer=$(echo "$file" | awk -F'/' '{print $NF}' | cut -d '.' -f 2)
				projektname=$(echo "$file" | awk -F'/' '{print $NF}' | cut -d '.' -f 3 | sed 's/_/ /g')
				bildanzahl_theo=$(echo "$file" | awk -F'/' '{print $NF}' | cut -d '.' -f 4)
				bildanzahl_real=$(find $pfad/$projektnummer* -type f -name *.jpg | wc -l)
				pause=$(echo "$file" | awk -F'/' '{print $NF}' | cut -d '.' -f 5)

				echo "$projektnummer - $projektname - Bildanzahl: $bildanzahl_real - Pause: $pause"
			done
		else
			echo "Keine unvollständigen Projekte gefunden."
			exit 0
		fi

		echo ""
		read -p "Projektnummer zur weiteren Bearbeitung: " projekt
		
		echo "• OK, Projekt $projekt ausgewählt."

		echo ""
		echo "Projekt wird abgeschlossen..."

		nameneu=$(echo "$projektname" | sed 's/ /_/g')

		echo "Fehler im Programm, es wird hier unterbrochen."
		exit 1
		
		mv $data/.$projekt.*.incomplete "$data/.$projekt.$nameneu.$bildanzahl_real.$pause.fertig"

		dat_org="$pfad/$projekt - $projektname (${bildanzahl_theo}Stk - ${pause}s)"
		dat_mod="$pfad/$projekt - $projektname (${bildanzahl_real}Stk - ${pause}s)"

		if [ ! "$dat_org" = "$dat_mod" ]; then
			mv "$dat_org" "$dat_mod"
		fi

		echo "Fertig."
		exit 0
	fi

	exit 0
fi

exit 0