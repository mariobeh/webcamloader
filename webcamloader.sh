#!/bin/bash

user=$(whoami)
data="/home/$user/script-data/webcamloader"

zeitstempel=$(date +"%Y-%m-%d")

if [ "$1" = "quicky" ] && [ ! -z "$6" ]; then
	x="$6"
	zusammenfuhren="1"
else
	x=1
fi

if [ ! -d "$data" ]; then
	mkdir -p "$data"
fi

# Updater & Reverse Updater BEGINN
scriptversion=2211211716
scriptname=webcamloader.sh
serverping=public.mariobeh.de
web_ver=https://public.mariobeh.de/prv/scripte/$scriptname-version.txt
web_mirror=https://public.mariobeh.de/prv/scripte/$scriptname
int_ver=/srv/web/prv/scripte/$scriptname-version.txt
int_mirror=/srv/web/prv/scripte/$scriptname
host=$(hostname)

if ping -w 1 -c 1 "$serverping" > /dev/null; then
	wget "$web_ver" -q -O "$data/version.txt"
	if [ -f "$data/version.txt" ]; then
		serverversion=$(cat "$data/version.txt" | head -n1 | tail -n1)
		if [ "$serverversion" -gt "$scriptversion" ]; then
			clear
			echo "Eine neue Version von $scriptname ist verfügbar."
			echo ""
			echo "Deine Version: $scriptversion"
			echo "Neue Version:  $serverversion"
			echo ""
			echo "Script wird automatisch aktualisiert, um immer das beste Erlebnis zu bieten."
			echo ""
			sleep 3
			wget -q -N "$web_mirror"
			echo "Fertig. Starte..."
			sleep 2
			$0
			exit
		else
			ipweb=$(host public.mariobeh.de | grep -w address | cut -d ' ' -f 4) # IP vom Mirror-Server
			ipext=$(wget -4qO - icanhazip.com) # IP vom Anschluss
	
			if [ "$user" = "mariobeh" ] && [ "$host" = "behserver" ] && [ "$ipweb" = "$ipext" ]; then
				if [ ! -f "$int_ver" ]; then
					clear
					echo "Internes Reverse Update wird vorbereitet:"
					echo "Kopiere auf das Webverzeichnis..."
					echo "$scriptversion" > "$int_ver"
					cp "$scriptname" "$int_mirror"
					echo "Fertig."
					sleep 2
				elif [ "$scriptversion" -gt "$serverversion" ]; then
					clear
					echo "Internes Reverse Update wird durchgeführt..."
					sleep 2
					echo "$scriptversion" > "$int_ver"
					cp -f $0 "$int_mirror"
					wget "$web_ver" -q -O "$data/version.txt"
					serverversion=$(cat "$data/version.txt" | head -n1 | tail -n1)
					if [ "$serverversion" = "$scriptversion" ]; then
						echo "Update erfolgreich abgeschlossen."
					else
						echo "Update fehlgeschlagen."
					fi
					sleep 2
				fi
			fi
		fi
		rm "$data/version.txt"
	fi
fi
# Updater & Reverse Updater ENDE

if [ ! -f "$data/config.txt" ]; then
	sudo apt-get install zip tar screen ffmpeg -y
	echo "100" > "$data/nummer.txt"
	echo "Projekt-ID;Funktion;Datum;Uhrzeit;Bilderanzahl;Pause;Dauer;FPS;Name;URL" > "$data/Protokoll.csv"
	echo "TestPing = 8.8.8.8" >> "$data/config.txt"
	echo "Bilder = $data/Bilder #(Beispiel)" >> "$data/config.txt"
	echo "" >> "$data/config.txt"
	echo "warten = 10 # Pause in Sekunden, wenn Internet off oder Webcam-Server down" >> "$data/config.txt"
	echo "testgroesse = 4096 # Größe in Bytes, was das Bild mindestens haben soll. Unter dieser Größe geht man von einem fehlerhaften Bild aus" >> "$data/config.txt"

	clear
	echo "Bitte Pfad eintragen in der Config, wo die Bilder gespeichert werden sollen!"
	echo "Es wird empfohlen, dies auf einer HDD zu speichern, statt auf einer SSD."
	echo ""
	echo "Als Vorgabe/Beispiel ist der Bilder-Ordner hier: $data/Bilder."
	echo "Damit sind Downloads nun grundsätzlich möglich."
	sleep 5
fi

intro=" ╚ WCL Version $scriptversion ╝" # zwei Einträge brauchen die Variabel

function intro {
	clear
	echo " ╚ WCL Version $scriptversion ╝"
	echo ""
	echo ""
}

nummer=$(cat "$data/nummer.txt" | head -n1 | tail -n1)
ping=$(grep -w TestPing "$data/config.txt" | cut -d ' ' -f 3)
bilder=$(grep -w Bilder "$data/config.txt" | cut -d ' ' -f 3)
lostwarten=$(grep -w warten "$data/config.txt" | cut -d ' ' -f 3)
testgroesse=$(grep -w testgroesse "$data/config.txt" | cut -d ' ' -f 3)

# VORÜBERGEHEND!
if [ -z "$lostwarten" ] || [ -z "$testgroesse" ]; then
	echo "" >> "$data/config.txt"
	echo "warten = 10 # Pause in Sekunden, wenn Internet off oder Webcam-Server down" >> "$data/config.txt"
	echo "testgroesse = 4096 # Größe in Bytes, was das Bild mindestens haben soll. Unter dieser Größe geht man von einem fehlerhaften Bild aus" >> "$data/config.txt"
fi
# VORÜBERGEHEND!

if [ "$nummer" -ge "999" ] || [ "$nummer" -lt "100" ]; then
	echo "100" > "$data/nummer.txt"
	nummer="100"
	echo "Laufende Nummer zurückgesetzt."
	echo "Entweder waren die Projekte voll oder es wurde manipuliert."
	echo "Das Script beginnt wieder bei $nummer".
	echo "Dies hat auch Auswirkungen auf die Statistik!"
	sleep 5
fi

if [ ! -d "$bilder" ]; then
	mkdir -p "$bilder"
fi

if [ $(ls -A $bilder | wc -l) = "0" ]; then
	aktiv="0"
else
	aktiv="1"
fi

#							88b           d88  88888888888  888b      88  88        88
#							888b         d888  88           8888b     88  88        88
#							88`8b       d8'88  88           88 `8b    88  88        88
#							88 `8b     d8' 88  88aaaaa      88  `8b   88  88        88
#							88  `8b   d8'  88  88"""""      88   `8b  88  88        88
#							88   `8b d8'   88  88           88    `8b 88  88        88
#							88    `888'    88  88           88     `8888  Y8a.    .a8P
#							88     `8'     88  88888888888  88      `888   `"Y8888Y"' 

if [ -z "$1" ]; then
	clear
	echo "  W E B C A M L O A D E R"
	echo "$intro"
	echo ""
	echo ""
	echo "Willkommen zum Webcamloader [WCL]!"
	echo "       Was ist zu tun?"
	echo ""
	echo ""
	echo " 1 - Normaler Modus, geführt"
	if [ "$aktiv" = "1" ]; then
	echo " 2 - Video erstellen von einem Projekt"
	fi
	if [ "$aktiv" = "1" ]; then
	echo " 3 - Ein Projekt in ein Archiv packen"
	fi
	echo " 4 - Informationen zum 'Quicky-Modus'"
	echo " 5 - Ein Archiv integrieren"
	if [ "$aktiv" = "1" ]; then
	echo " 6 - Projekt-Ordner löschen"
	fi
	if [ "$aktiv" = "1" ]; then
		echo " 7 - Speicherbedarf Bilderordner"
	fi
	echo " 8 - Statistik"
	echo ""
	echo ""
	read -p "Deine Eingabe: " menu
	echo ""

	if [ "$menu" = "1" ]; then
		echo "Okay, Normaler Modus."
		sleep 2
		$0 normal
		exit
	elif [ "$menu" = "2" ]; then
		echo "Okay, Video erstellen."
		sleep 2
		$0 video
		exit
	elif [ "$menu" = "3" ]; then
		echo "Okay, ein Archiv erstellen."
		sleep 2
		$0 archiv
		exit
	elif [ "$menu" = "4" ]; then
		echo "Okay, Informationen zum Quicky-Modus."
		sleep 2
		clear
		echo "$intro


 Der Quicky-Modus erlaubt dir, schnellstmöglich mit dem Download der Bilder zu beginnen.
 Der Einsatz ist denkbar einfach.
 Nach dem Script-Namen sind nur Argumente zu übergeben.
 ./script.sh Funktion arg1 arg2 arg3 arg4 arg5
 ./script.sh quicky URL Name Bilderanzahl Pausen
 
 In der Praxis sieht mit einem Beispiel das Ganze so aus:
 
 ./webcamloader.sh quicky http://video.pafunddu.de/webcam/paf_rathaus.jpg Pfaffenhofen 2000 10
 
 --> Das heißt, der Webcamloader lädt 2000 Fotos im Abstand zu je 10 Sekunden mit dem Namen Pfaffenhofen
 	von der Adresse http://video.pafunddu.de/webcam/paf_rathaus.jpg herunter.
 	Dieser Vorgang kann im normalen Modus geführt eingegeben werden.
 
 Auch Videos und Motion Pictures (MJPG) werden unterstützt.
 Hier dasselbe, Beispiel aus der Praxis:
 
 ./webcamloader.sh quicky http://104.251.136.19:8080/mjpg/video.mjpg Pool 6000 30
 
 --> Das heißt, der Webcamloader lädt 6000 Fotos im Abstand zu je 30 Sekunden mit dem Namen Pool von der
 	Adresse http://104.251.136.19:8080/mjpg/video.mjpg herunter. Es ist derselbe Effekt wie bei den Bildern
 	zu erwarten.
 
 ACHTUNG: Sollte der Name der Webcam Leerzeichen enthalten, unbedingt in Anführungszeichen setzen,
 da sich sonst die Argumente verschieben und das Script dann Fehler ausgibt.
 Beispiel:
 ./webcamloader.sh quicky http://video.pafunddu.de/webcam/paf_rathaus.jpg \"Pfaffenhofen Rathaus\" 2000 10

-- ENDE --
		Bitte warten...
" > "$data/quickyinfo.txt"
		more "$data/quickyinfo.txt"
		rm "$data/quickyinfo.txt"
		sleep 10
		$0
		exit
	elif [ "$menu" = "5" ]; then
		echo "Okay, ein Archiv integrieren."
		sleep 2
		intro
		echo "Du kannst ein bereits mit dem webcamloader-Script gepacktes Archiv integrieren zur weiteren Bearbeitung."
		echo "Dieses Archiv muss in das Bilderverzeichnis gespeichert werden, damit es vom Script aufgerufen werden kann."
		echo "HINWEIS: Das Archiv muss dasselbe Format haben, wie es vom Script ausgegeben wird."
		echo ""
		echo "Welches Archiv soll integriert werden? Die Identifizierung erfolgt wieder mit der Projekt-ID."
		echo ""
		read -p "Deine Eingabe: " sid

		name=$(ls $bilder | grep "$sid - " | cut -d ' ' -f 4- | sed "s: -.*::" | head -n1 | tail -n1)

		if [ -f $bilder/Bilder\ $sid\ -*.tar ]; then
			echo ""
			echo "Okay, Projekt-ID $sid mit dem Namen $name."
			echo "Wird entpackt..."
			sleep 1
			tar xf $bilder/Bilder\ $sid\ -*.tar -C "$bilder/"

			if ! [ $(ls -A $bilder/$sid\ -* | wc -l) = "0" ]; then
				echo ""
				echo "Entpacken erfolgreich."
				echo "Archiv wird gelöscht."
				sleep 1
				rm $bilder/Bilder\ $sid\ -*.tar
				echo ""
				echo "Fertig."
			else
				echo ""
				echo "Irgendwas ist schief gelaufen. Es wurde nichts entpackt."
				echo "Bitte nochmal probieren."
				echo "Fehler, Abbruch."
				sleep 3
				exit
			fi

		elif [ -f $bilder/Bilder\ $sid\ -*.zip ]; then
			echo ""
			echo "ZIP wird im Moment noch nicht unterstützt. Bitte manuell entpacken."
			sleep 3
			exit
#			unzip $bilder/Bilder\ $sid\ -*.zip
		else
			echo "Kein gültiges Archiv gefunden!"
			echo "Fehler, Abbruch."
			sleep 3
			exit
		fi

	elif [ "$menu" = "6" ]; then
		echo "Okay, einen Projekt-Ordner löschen."
		sleep 2
		intro
		echo "Projekt-Ordner löschen..."
		echo ""
		echo "Welche Projekt-ID soll gelöscht werden?"
		echo ""
		read -p "Deine Eingabe: " sid
		echo ""

		anzahl=$(find $bilder/$sid* -type f | wc -l)
		name=$(ls $bilder | grep "$sid - " | cut -d ' ' -f 3- | sed "s: (.*::" | head -n1 | tail -n1)

		echo "Okay, $sid - $name."
		sleep 1

		if [ ! "$anzahl" = "0" ]; then
			echo ""
			echo "Es befinden sich $anzahl Bilder in diesem Ordner. Wirklich löschen?"
			read -p "'ja' für ja, für nein ENTER: " loschen
			if [ "$loschen" = "ja" ]; then
				echo ""
				rm -r $bilder/$sid\ *
				echo "Projekt-ID $sid erfolgreich gelöscht."
			fi
		else
			echo ""
			rm -r $bilder/$sid\ *
			echo "Projekt-ID $sid erfolgreich gelöscht."
		fi

	elif [ "$menu" = "7" ]; then
		echo "Okay, Speicherbedarf vom Bilderordner anzeigen."
		sleep 2
		echo ""
		echo $(du $bilder -hs)
		echo ""
		echo "Einen Moment, Du gelangst wieder ins Menü."
		sleep 10
		$0
		exit

	elif [ "$menu" = "8" ]; then
		echo "Okay, Statistik anzeigen."
		sleep 2
		echo ""

		if [ ! "$nummer" = "100" ]; then
			echo "Projekte: $(($nummer - 100 + 1))"
		fi
		if [ -f "$data/exec-log.txt" ]; then
			aktionen=$(sed $= -n "$data/exec-log.txt")
			echo "Aktionen: $aktionen"
		fi

		echo ""
		echo "Einen Moment, Du gelangst wieder ins Menü."
		sleep 10
		$0
		exit

else
		echo "Fehler, keine gültige Eingabe getroffen."
		echo "Fehler, Abbruch."
		sleep 3
		exit
	fi
fi

#					 ,ad8888ba,    88        88  88    ,ad8888ba,   88      a8P  8b        d8
#					d8"'    `"8b   88        88  88   d8"'    `"8b  88    ,88'    Y8,    ,8P 
#					8'        `8b  88        88  88  d8'            88  ,88"       Y8,  ,8P  
#					8          88  88        88  88  88             88,d88'         "8aa8"   
#					8          88  88        88  88  88             8888"88,         `88'    
#					8,    "88,,8P  88        88  88  Y8,            88P   Y8b         88     
#					Y8a.    Y88P   Y8a.    .a8P  88   Y8a.    .a8P  88     "88,       88     
#					 `"Y8888Y"Y8a   `"Y8888Y"'   88    `"Y8888Y"'   88       Y8b      88     

if [ "$1" = "quicky" ] && [ ! -z "$2" ] && [ ! -z "$3" ] && [ ! -z "$4" ] && [ ! -z "$5" ]; then

	if ! ping -w 1 -c 1 "$ping" > /dev/null; then
		echo ""
		echo "Keine Internetverbindung. Störung?"
		echo "Stelle sicher, dass der Webcamloader auf das Internet zugreifen kann und darf."
		echo "Fehler, Abbruch."
		sleep 3
		exit
	fi

	if ! [ "$4" -eq "$4" ]; then
		echo ""
		echo "Fehler. Bilderanzahl darf nur eine ganze Zahl sein."
		echo "Fehler, Abbruch."
		sleep 3
		exit
	fi

	if [ "$4" -gt "14331" ]; then
		echo ""
		echo "Fehler: Bildanzahl überschritten, maximal 14.330 Bilder möglich!"
		echo "Es kann sonst kein Video erstellt werden."
		echo "Fehler, Abbruch."
		sleep 3
		exit
	fi

	if ! [ "$5" -eq "$5" ]; then
		echo ""
		echo "Fehler: Pause zwischen Bildern darf nur eine ganze Zahl sein."
		echo "Fehler, Abbruch."
		sleep 3
		exit
	fi

	vdatei1=$(echo "$2" | grep ".mjpg")
	vdatei2=$(echo "$2" | grep "faststream")
	vdatei3=$(echo "$2" | grep "video.cgi")
	vdatei4=$(echo "$2" | grep "videostream.cgi")
	vdatei5=$(echo "$2" | grep "mjpg.cgi")
	vdatei6=$(echo "$2" | grep "GetData.cgi")
	vdatei7=$(echo "$2" | grep "?video")

	if [ -n "$vdatei1" ] || [ -n "$vdatei2" ] || [ -n "$vdatei3" ] || [ -n "$vdatei4" ] || [ -n "$vdatei5" ] || [ -n "$vdatei6" ] || [ -n "$vdatei7" ]; then
		video="1"
	fi

	intro
	echo "Projekt-ID:	$nummer"
	echo "Projekt		$3"
	echo "Anzahl		$4"
	echo "Pause		$5"
	echo ""
	echo ""
	
	if [ ! -z "$6" ]; then
		echo "Mache bei Bild Nr. $x weiter."
		echo "Es können danach zwei Projekte zusammengeführt werden."
	else
		echo "Dauer etwa $(($4*$5/60)) Min., $(($4*$5/60/60)) Std., $(($4*$5/60/60/24)) Tag(e)."
		echo "Im Idealfall fertig: $(date -d "+$(($4*$5/60)) minutes" +"%d.%m.%y, %H:%M:%S")."
		echo ""
		echo "Prüfe, ob die URL gültig ist und berechne benötigte Speicherkapazität..."
		echo ""
		echo "Sollte nach mehreren Sekunden keine Bestätigung kommen, handelt es sich um ein Videoformat,"
		echo "welches noch nicht im Script erfasst wurde. Unterbreche das Script mit STRG+C."
		echo "Rufe das Script noch einmal auf und hänge provisorisch an die Adresse am Ende ein \"?video\" an."

		if [ "$video" = "1" ]; then
			ffmpeg -y -i "$2" -loglevel quiet -nostats -hide_banner -vframes 1 "$data/$nummer-test.jpg" > /dev/null
			if [ ! $(stat -c%s "$data/$nummer-test.jpg") -gt "$testgroesse" ] ;then
				echo ""
				echo "Fehler!"
				echo "Die eingegebene URL liefert kein Bild!"
				echo "Fehler, Abbruch."
				rm $data/$nummer-test.*
				sleep 3
				exit
			else
				ls -l "$data/" | grep "$nummer-test.jpg" | sed "s:     : :g ; s:    : :g ; s:   : :g ; s:  : :g" | cut -d ' ' -f 5 > "$data/$nummer-test.txt"
				grosse=$(cat "$data/$nummer-test.txt" | head -n1 | tail -n1)
				echo ""
				echo "Am Ende wird der Projekt-Ordner um die $(($4*$grosse/1048576)) MB groß sein."
				rm $data/$nummer-test.*
			fi
		else
			wget "$2" -O "$data/$nummer-test.jpg" -a /dev/null
			if [ ! $(stat -c%s "$data/$nummer-test.jpg") -gt "$testgroesse" ] ;then
				echo ""
				echo "Fehler!"
				echo "Die eingegebene URL liefert kein Bild!"
				echo "Fehler, Abbruch."
				rm $data/$nummer-test.*
				sleep 3
				exit
			else
				ls -l "$data/" | grep "$nummer-test.jpg" | sed "s:     : :g ; s:    : :g ; s:   : :g ; s:  : :g" | cut -d ' ' -f 5 > "$data/$nummer-test.txt"
				grosse=$(cat "$data/$nummer-test.txt" | head -n1 | tail -n1)
				echo ""
				echo "Am Ende wird der Projekt-Ordner um die $(($4*$grosse/1048576)) MB groß sein."
				rm $data/$nummer-test.*
			fi
		fi
	fi

	echo ""
	echo ""
	echo ""
	read -p "Download starten? >> ENTER" null
	echo "$(($nummer + 1))" > "$data/nummer.txt" # raufzählen bei der Projekt-ID
	mkdir "$bilder/$nummer - $3 ($4 Stk - $5 Sek)" # Projekt-ID-Ordner erstellen mit Bildanzahl
	echo "$nummer;Quicky;$(date +"%d.%m.%Y;%H:%M");$4;$5;;;$3;$2" >> "$data/Protokoll.csv"

	intro
	echo "PROJEKT: $nummer - $3"
	sleep 2
	echo ""
	echo ""

	if [ "$video" = "1" ]; then
		while [ $x -le $4 ]; do # solange ausführen, bis Anzahl erreicht
			while ! ping -w 3 -c 1 "$ping" > /dev/null; do
				intro
				echo "($nummer) $(date +"%d.%m.%y %H:%M:%S") :: Keine Internetverbindung. Prüfe erneut..."
				echo "($nummer) $(date +"%y%m%d-%H%M%S") :: Keine Internetverbindung" >> "$data/exec-log.txt"
				sleep "$lostwarten"
			done
			ffmpeg -y -i "$2" -loglevel quiet -nostats -hide_banner -vframes 1 "$bilder/$nummer - $3 ($4 Stk - $5 Sek)/test.jpg" > /dev/null
			if [ $(stat -c%s "$bilder/$nummer - $3 ($4 Stk - $5 Sek)/test.jpg") -gt "$testgroesse" ]; then
				intro
				echo "($nummer) $(date +"%d.%m.%y %H:%M:%S") :: Bild $x von $4 wird erstellt..."
				echo "($nummer) $(date +"%y%m%d-%H%M%S") :: Bild $x / $4 (V)" >> "$data/exec-log.txt"
				mv "$bilder/$nummer - $3 ($4 Stk - $5 Sek)/test.jpg" "$bilder/$nummer - $3 ($4 Stk - $5 Sek)/$(date +"%Y%m%d%H%M%S") - $3 ($5 s, $4 Stk).jpg" > /dev/null
				sleep "$5"
				x=$(($x + 1))
			else
				intro
				echo "($nummer) $(date +"%d.%m.%y %H:%M:%S") :: Ziel-Host nicht erreichbar oder fehlerhaftes Bild. Prüfe erneut..."
				echo "($nummer) $(date +"%y%m%d-%H%M%S") :: Ziel-Host nicht erreichbar (V)" >> "$data/exec-log.txt"
				sleep "$lostwarten"
			fi
		done 
	else
		while [ $x -le $4 ]; do # solange ausführen, bis Anzahl erreicht
			while ! ping -w 3 -c 1 "$ping" > /dev/null; do
				intro
				echo "($nummer) $(date +"%d.%m.%y %H:%M:%S") :: Keine Internetverbindung. Prüfe erneut..."
				echo "($nummer) $(date +"%y%m%d-%H%M%S") :: Keine Internetverbindung" >> "$data/exec-log.txt"
				sleep "$lostwarten"
			done
			intro
			echo "($nummer) $(date +"%d.%m.%y %H:%M:%S") :: Bild $x von $4 wird erstellt..."
			echo "($nummer) $(date +"%y%m%d-%H%M%S") :: Bild $x / $4 (B)" >> "$data/exec-log.txt"
			wget "$2" -O "$bilder/$nummer - $3 ($4 Stk - $5 Sek)/$(date +"%Y%m%d%H%M%S - $3 - $x von $4 ($5 s).jpg")" -a /dev/null
			sleep "$5"
			x=$(($x + 1))
		done
	fi
		
	intro
	echo "$4 Bild(er) gespeichert mit der Projekt-Nummer $nummer ($3)"
	echo ""
	echo "Räume auf: entferne fehlerhafte Bilder..."
	find $bilder/$nummer* -type f -name *.jpg -size 0c -exec rm {} \;

	if [ "$zusammenfuhren" = "1" ]; then
		touch "$bilder/$nummer fertig (Z)"
		echo ""
		echo ""
		echo "Mit welcher Projekt-ID möchtest Du die aktuelle $nummer zusammenführen?"
		echo ""
		read -p "Projekt-ID: " id
		echo ""
		echo "Okay, die $nummer wird nach $id verschoben und zusammengeführt. Bitte warten."
		sleep 1
		mv $bilder/$nummer\ -*/*.jpg $bilder/$id\ -*

		if [ $(ls -A $bilder/$nummer\ -* | wc -l) = "0" ]; then # lösche altes Verzeichnis
			rm -r $bilder/$nummer\ -*
		fi

		if [ -f "$bilder/$nummer fertig (Z)" ]; then # lösche altes fertig-Flag
			rm "$bilder/$nummer fertig (Z)"
		fi

		touch "$bilder/$id fertig"
	else
		touch "$bilder/$nummer fertig"
	fi

	echo "Fertig."

elif [ "$1" = "quicky" ] && ([ ! -z "$2" ] || [ ! -z "$3" ] || [ ! -z "$4" ] || [ ! -z "$5" ]); then
	echo ""
	echo "Fehler, für den Quicky-Modus fehlt mindestens ein Argument."
	echo "Fehler, Abbruch."
	sleep 3
	exit
fi

#					888b      88    ,ad8888ba,    88888888ba   88b           d88         db         88
#					8888b     88   d8"'    `"8b   88      "8b  888b         d888        d88b        88
#					88 `8b    88  d8'        `8b  88      ,8P  88`8b       d8'88       d8'`8b       88
#					88  `8b   88  88          88  88aaaaaa8P'  88 `8b     d8' 88      d8'  `8b      88
#					88   `8b  88  88          88  88""""88'    88  `8b   d8'  88     d8YaaaaY8b     88
#					88    `8b 88  Y8,        ,8P  88    `8b    88   `8b d8'   88    d8""""""""8b    88
#					88     `8888   Y8a.    .a8P   88     `8b   88    `888'    88   d8'        `8b   88
#					88      `888    `"Y8888Y"'    88      `8b  88     `8'     88  d8'          `8b  88888888888

if [ "$1" = "normal" ]; then

	if ! ping -w 1 -c 1 "$ping" > /dev/null; then
		echo ""
		echo "Keine Internetverbindung. Störung?"
		echo "Stelle sicher, dass der Webcamloader auf das Internet zugreifen kann und darf."
		echo "Fehler, Abbruch."
		sleep 3
		exit
	fi

	intro
	echo "Projekt-ID:		$nummer"
	echo ""
	read -p "Webcam-URL:		" url
	read -p "Bezeichnung:		" name
	read -p "Bildanzahl:		" anzahl
	read -p "Pause zw. Bildern in s:	" pause

	if ! [ "$anzahl" -eq "$anzahl" > /dev/null ]; then
		echo ""
		echo "Fehler. Bilderanzahl darf nur eine ganze Zahl sein."
		echo "Fehler, Abbruch."
		sleep 3
		exit
	fi

	if ! [ "$pause" -eq "$pause" > /dev/null ]; then
		echo ""
		echo "Fehler: Pause zwischen Bildern darf nur eine ganze Zahl sein."
		echo "Fehler, Abbruch."
		sleep 3
		exit
	fi

	if [ "$anzahl" -gt "14331" ]; then
		echo ""
		echo "Fehler: Bildanzahl überschritten, maximal 14.330 Bilder möglich!"
		echo "Es kann sonst kein Video erstellt werden."
		echo "Fehler, Abbruch."
		sleep 3
		exit
	fi

	vdatei1=$(echo "$url" | grep ".mjpg")
	vdatei2=$(echo "$url" | grep "faststream")
	vdatei3=$(echo "$url" | grep "video.cgi")
	vdatei4=$(echo "$url" | grep "videostream.cgi")
	vdatei5=$(echo "$url" | grep "mjpg.cgi")
	vdatei6=$(echo "$url" | grep "GetData.cgi")
	vdatei7=$(echo "$url" | grep "?video")

	if [ -n "$vdatei1" ] || [ -n "$vdatei2" ] || [ -n "$vdatei3" ] || [ -n "$vdatei4" ] || [ -n "$vdatei5" ] || [ -n "$vdatei6" ] || [ -n "$vdatei7" ]; then
		video="1"
	fi

	intro
	echo "- ZUSAMMENFASSUNG -"
	echo ""
	echo "Dauer etwa $(($anzahl*$pause/60)) Min., $(($anzahl*$pause/60/60)) Std., $(($anzahl*$pause/60/60/24)) Tag(e)."
	echo "Im Idealfall fertig: $(date -d "+$(($anzahl*$pause/60)) minutes" +"%d.%m.%y, %H:%M:%S")."
	echo ""
	echo "Prüfe, ob die URL gültig ist und berechne benötigte Speicherkapazität..."
	echo ""
	echo "Sollte nach mehreren Sekunden keine Bestätigung kommen, handelt es sich um ein Videoformat,"
	echo "welches noch nicht im Script erfasst wurde. Unterbreche das Script mit STRG+C."
	echo "Rufe das Script noch einmal auf und hänge provisorisch an die Adresse am Ende ein \"?video\" an."
	echo "Berechne benötigte Speicherkapazität..."

	if [ "$video" = "1" ]; then
		ffmpeg -y -i "$url" -loglevel quiet -nostats -hide_banner -vframes 1 "$data/$nummer-test.jpg" > /dev/null
		if [ ! $(stat -c%s "$data/$nummer-test.jpg") -gt "$testgroesse" ] ;then
			echo ""
			echo "Fehler!"
			echo "Die eingegebene URL liefert kein Bild!"
			echo "Fehler, Abbruch."
			rm $data/$nummer-test.*
			sleep 3
			exit
		else
			ls -l "$data/" | grep "$nummer-test.jpg" | sed "s:     : :g ; s:    : :g ; s:   : :g ; s:  : :g" | cut -d ' ' -f 5 > "$data/$nummer-test.txt"
			grosse=$(cat "$data/$nummer-test.txt" | head -n1 | tail -n1)
			echo ""
			echo "Am Ende wird der Projekt-Ordner um die $(($anzahl*$grosse/1048576)) MB groß sein."
			rm $data/$nummer-test.*
		fi
	else
		wget "$url" -O "$data/$nummer-test.jpg" -a /dev/null
		if [ ! $(stat -c%s "$data/$nummer-test.jpg") -gt "$testgroesse" ] ;then
			echo ""
			echo "Fehler!"
			echo "Die eingegebene URL liefert kein Bild!"
			echo "Fehler, Abbruch."
			rm $data/$nummer-test.*
			sleep 3
			exit
		else
			ls -l "$data/" | grep "$nummer-test.jpg" | sed "s:     : :g ; s:    : :g ; s:   : :g ; s:  : :g" | cut -d ' ' -f 5 > "$data/$nummer-test.txt"
			grosse=$(cat "$data/$nummer-test.txt" | head -n1 | tail -n1)
			echo ""
			echo "Am Ende wird der Projekt-Ordner um die $(($anzahl*$grosse/1048576)) MB groß sein."
			rm $data/$nummer-test.*
		fi
	fi

	echo ""
	echo ""
	echo ""
	read -p "Download starten? >> ENTER" null
	echo "$(($nummer + 1))" > "$data/nummer.txt" # raufzählen bei der Projekt-ID
	mkdir "$bilder/$nummer - $name ($anzahl Stk - $pause Sek)" # Projekt-ID-Ordner erstellen mit Bildanzahl
	echo "$nummer;Normal;$(date +"%d.%m.%Y;%H:%M");$anzahl;$pause;;;$name;$url" >> "$data/Protokoll.csv"

	intro
	echo "PROJEKT: $nummer - $name"
	sleep 2
	echo ""
	echo ""

	if [ "$video" = "1" ]; then
		while [ $x -le $anzahl ]; do # solange ausführen, bis Anzahl erreicht
			while ! ping -w 3 -c 1 "$ping" > /dev/null; do
				intro
				echo "($nummer) $(date +"%d.%m.%y %H:%M:%S") :: Keine Internetverbindung. Prüfe erneut..."
				echo "($nummer) $(date +"%y%m%d-%H%M%S") :: Keine Internetverbindung" >> "$data/exec-log.txt"
				sleep "$lostwarten"
			done
			ffmpeg -y -i "$url" -loglevel quiet -nostats -hide_banner -vframes 1 "$bilder/$nummer - $name ($anzahl Stk - $pause Sek)/test.jpg" > /dev/null
			if [ $(stat -c%s "$bilder/$nummer - $name ($anzahl Stk - $pause Sek)/test.jpg") -gt "$testgroesse" ]; then
				intro
				echo "($nummer) $(date +"%d.%m.%y %H:%M:%S") :: Bild $x von $anzahl wird erstellt..."
				echo "($nummer) $(date +"%y%m%d-%H%M%S") :: Bild $x / $anzahl (V)" >> "$data/exec-log.txt"
				mv "$bilder/$nummer - $name ($anzahl Stk - $pause Sek)/test.jpg" "$bilder/$nummer - $name ($anzahl Stk - $pause Sek)/$(date +"%Y%m%d%H%M%S") - $name ($pause s, $anzahl Stk).jpg" > /dev/null
				sleep "$pause"
				x=$(($x + 1))
			else
				intro
				echo "($nummer) $(date +"%d.%m.%y %H:%M:%S") :: Ziel-Host nicht erreichbar oder fehlerhaftes Bild. Prüfe erneut..."
				echo "($nummer) $(date +"%y%m%d-%H%M%S") :: Ziel-Host nicht erreichbar (V)" >> "$data/exec-log.txt"
				sleep "$lostwarten"
			fi
		done 
	else
		while [ $x -le $anzahl ]; do # solange ausführen, bis Anzahl erreicht
			while ! ping -w 3 -c 1 "$ping" > /dev/null; do
				intro
				echo "($nummer) $(date +"%d.%m.%y %H:%M:%S") :: Keine Internetverbindung. Prüfe erneut..."
				echo "($nummer) $(date +"%y%m%d-%H%M%S") :: Keine Internetverbindung" >> "$data/exec-log.txt"
				sleep "$lostwarten"
			done
			intro
			echo "($nummer) $(date +"%d.%m.%y %H:%M:%S") :: Bild $x von $anzahl wird erstellt..."
			echo "($nummer) $(date +"%y%m%d-%H%M%S") :: Bild $x / $anzahl (B)" >> "$data/exec-log.txt"
			wget "$url" -O "$bilder/$nummer - $name ($anzahl Stk - $pause Sek)/$(date +"%Y%m%d%H%M%S - $name - $x von $anzahl ($pause s).jpg")" -a /dev/null
			sleep "$pause"
			x=$(($x + 1))
		done
	fi
		
	intro
	echo "$anzahl Bild(er) gespeichert mit der Projekt-Nummer $nummer ($name)"
	echo ""
	echo "Räume auf: entferne fehlerhafte Bilder..."
	find $bilder/$nummer* -type f -name *.jpg -size 0c -exec rm {} \;
	echo "Fertig."
	touch "$bilder/$nummer fertig"

	if [ "$zusammenfuhren" = "1" ]; then
		echo "$bilder/$nummer fertig"
		echo ""
		echo ""
		echo "Mit welcher Projekt-ID möchtest Du die aktuelle $nummer zusammenführen?"
		echo ""
		read -p "Projekt-ID: " id
		echo ""
		echo "Okay, die $nummer wird nach $id verschoben und zusammengeführt. Bitte warten."
		sleep 1
		mv $bilder/$nummer\ -*/*.jpg $bilder/$id\ -*

		if [ $(ls -A $bilder/$nummer\ -* | wc -l) = "0" ]; then # lösche altes Verzeichnis
			rm -r $bilder/$nummer\ -*
		fi

		if [ -f "$bilder/$nummer fertig" ]; then # lösche altes fertig-Flag
			rm "$bilder/$nummer fertig"
		fi

		touch "$bilder/$id fertig"
	else
		touch "$bilder/$nummer fertig"
	fi

	echo "Fertig."
fi

#					       db         88888888ba     ,ad8888ba,   88        88  88  8b           d8
#					      d88b        88      "8b   d8"'    `"8b  88        88  88  `8b         d8'
#					     d8'`8b       88      ,8P  d8'            88        88  88   `8b       d8' 
#					    d8'  `8b      88aaaaaa8P'  88             88aaaaaaaa88  88    `8b     d8'  
#					   d8YaaaaY8b     88""""88'    88             88""""""""88  88     `8b   d8'   
#					  d8""""""""8b    88    `8b    Y8,            88        88  88      `8b d8'    
#					 d8'        `8b   88     `8b    Y8a.    .a8P  88        88  88       `888'     
#					d8'          `8b  88      `8b    `"Y8888Y"'   88        88  88        `8'      

if [ "$1" = "archiv" ]; then
	intro
	echo "Archivarer"
	echo ""
	echo ""
	if [ "$aktiv" = "0" ]; then
		echo "Es ist nichts vorhanden,"
		echo "von was möchtest du ein Video erstellen?"
		echo ""
		echo "Bitte zuerst ein Projekt starten!"
		echo ""
		echo "Fehler, Abbruch."
		sleep 3
		exit
	fi
	echo "Welche Projekt-ID soll archiviert werden? Für alle, schreibe 'alle'."
	echo "Es werden nur die Bilder-Ordner archiviert, keine Videos."
	echo ""
	read -p "Deine Eingabe: " sid
	echo ""
	if [ "$sid" = "alle" ]; then
		echo "Es werden alle Projekte archiviert."
	else
		echo "Es wird das Projekt Nummer $sid archiviert."
	fi
	sleep 2
	echo ""
	echo ""
	echo "Archiv in .tar ( 1 ) oder .zip ( 2 )?"
	echo ""
	read -p "Deine Eingabe: " archivnr
	echo ""

	anzahl=$(find $bilder/$sid* -type f | wc -l)
	name=$(ls $bilder | grep "$sid - " | cut -d ' ' -f 3- | sed "s: (.*::" | head -n1 | tail -n1)

	if [ "$archivnr" = "1" ]; then
		echo "Okay, tar."
		echo "Bitte warten..."

		if [ -f "$bilder/$sid fertig" ]; then # kann mit der Zeit weg
			rm "$bilder/$sid fertig"
		fi

		if [ ! "$sid" = "alle" ]; then	# wenn SID und TAR
			cd "$bilder"
			tar -cpf "Bilder $sid - $name - $zeitstempel ($anzahl Stk).tar" $sid*
			echo ""
			echo "$sid;Archiv;$(date +"%d.%m.%Y;%H:%M");$anzahl;TAR;;;$name" >> "$data/Protokoll.csv"

			if [ -f $bilder/Bilder\ $sid\ -*.tar ]; then
				rm -r $bilder/$sid\ -*
			fi

			echo "Projekt-Ordner erfolgreich in ein .tar-Archiv gepackt."
		else
			tar -cpf "$bilder/Bilder komplett - $zeitstempel.tar" $bilder/*	# wenn ALLE und TAR
			echo ""
			echo "alle;Archiv;$(date +"%d.%m.%Y;%H:%M");$anzahl;TAR;;;$name" >> "$data/Protokoll.csv"
			echo "Alle Projekte erfolgreich in ein .tar-Archiv gepackt."
		fi
	elif [ "$archivnr" = "2" ]; then
		echo "Okay, zip."
		echo "Bitte warten..."
		if [ ! "$sid" = "alle" ]; then	# wenn SID und ZIP
			zip -r "$bilder/Bilder $sid - $name - $zeitstempel ($anzahl Stk).zip" $bilder/$sid*
			echo ""
			echo "$sid;Archiv;$(date +"%d.%m.%Y;%H:%M");$anzahl;ZIP;;;$name" >> "$data/Protokoll.csv"

			if [ -f $bilder/Bilder\ $sid\ -*.zip ]; then
				rm -r $bilder/$sid\ -*
			fi

			echo "Projekt-Ordner erfolgreich in ein .zip-Archiv gepackt."
		else
			zip -r "$bilder/Bilder komplett - $zeitstempel.zip" $bilder/*	# wenn ALLE und ZIP
			echo ""
			echo "alle;Archiv;$(date +"%d.%m.%Y;%H:%M");$anzahl;ZIP;;;$name" >> "$data/Protokoll.csv"
			echo "Alle Projekte erfolgreich in ein .zip-Archiv gepackt."
		fi
	fi
fi

#							8b           d8  88  88888888ba,    88888888888  ,ad8888ba,  
#							`8b         d8'  88  88      `"8b   88          d8"'    `"8b 
#							 `8b       d8'   88  88        `8b  88         d8'        `8b
#							  `8b     d8'    88  88         88  88aaaaa    88          88
#							   `8b   d8'     88  88         88  88"""""    88          88
#							    `8b d8'      88  88         8P  88         Y8,        ,8P
#							     `888'       88  88      .a8P   88          Y8a.    .a8P 
#							      `8'        88  88888888Y"'    88888888888  `"Y8888Y"'

if [ "$1" = "video" ]; then
	intro
	echo "Video Creator"
	echo ""
	echo ""
	if [ "$aktiv" = "0" ]; then
		echo "Es ist nichts vorhanden,"
		echo "von was möchtest du ein Video erstellen?"
		echo ""
		echo "Bitte zuerst ein Projekt starten!"
		echo ""
		echo "Fehler, Abbruch."
		sleep 3
		exit
	fi
	echo "Mit welcher Projekt-ID willst Du ein Video erstellen?"
	read -p "Deine Eingabe: " sid
	if [ -f $bilder/Video\ $sid* ]; then
		echo ""
		echo "Die ID wurde bereits visualisiert,"
		echo "willst du die Datei mit einem anderen FPS - Wert nochmal starten?"
		read -p "ENTER für ja oder 'nein' für nein: " uberschreiben
		if [ ! -z "$uberschreiben" ]; then
			echo ""
			echo "Okay, Abbruch."
			sleep 3
			exit
		fi
	fi

	find $bilder/$sid* -type f -name *.jpg -size 0c -exec rm {} \;

	anzahl=$(find $bilder/$sid* -type f | wc -l)
	name=$(ls "$bilder" | grep "$sid - " | cut -d ' ' -f 3- | sed "s: (.*::" | head -n1 | tail -n1)

	v_jahr=$(ls -r $bilder/$sid* | tail -n 1 | cut -b 1-4)
	v_monat=$(ls -r $bilder/$sid* | tail -n 1 | cut -b 5-6)
	v_tag=$(ls -r $bilder/$sid* | tail -n 1 | cut -b 7-8)

	b_jahr=$(ls $bilder/$sid* | tail -n 1 | cut -b 1-4)
	b_monat=$(ls $bilder/$sid* | tail -n 1 | cut -b 5-6)
	b_tag=$(ls $bilder/$sid* | tail -n 1 | cut -b 7-8)

	von="$v_jahr-$v_monat-$v_tag"
	bis="$b_jahr-$b_monat-$b_tag"

	echo ""
	echo "Name:		$name"
	echo "Bildanzahl: 	$anzahl"
	echo ""
	echo "Wieviele Bilder pro Sekunde (FPS)?"
	read -p "Deine Eingabe: " rfps
	intro
	echo "- ZUSAMMENFASSUNG -"
	echo ""
	echo "ID:		$sid"
	echo "Name:		$name"
	echo "Bilderanzahl:	$anzahl"
	echo "FPS:		$rfps"
	echo "Videolänge:	$(($anzahl / $rfps)) Sekunden"
	if [ "$von" = "$bis" ]; then
		echo "Aufnahmedatum:	$von"
	else
		echo "Aufnahmedatum:	$von bis $bis"
	fi
	echo ""
	echo ""
	read -p "OK? >> ENTER" null
	echo ""
	echo "Okay, Projekt-ID $sid wird visualisiert."
	sleep 5

	if [ "$von" = "$bis" ]; then
		cat $bilder/$sid*/*.jpg | ffmpeg -f image2pipe -r $rfps -hide_banner -framerate 1 -i - -vcodec libx264 "$bilder/Video $sid - $name - $von (${anzahl}Stk - ${rfps}fps - $(($anzahl / $rfps))s).mp4"
	else
		cat $bilder/$sid*/*.jpg | ffmpeg -f image2pipe -r $rfps -hide_banner -framerate 1 -i - -vcodec libx264 "$bilder/Video $sid - $name - $von bis $bis (${anzahl}Stk - ${rfps}fps - $(($anzahl / $rfps))s).mp4"
	fi

	echo "$sid;Video;$(date +"%d.%m.%Y;%H:%M");$anzahl;;$(($anzahl / $rfps));$rfps;$name" >> "$data/Protokoll.csv"

	if [ -f "$bilder/$sid fertig" ]; then # kann mit der Zeit weg
		rm "$bilder/$sid fertig"
	fi
fi

### SPECIALS ###

if [ "$1" = "video" ] && [ "$2" = "martin" ]; then
	echo "Verschiebe..."
	mv $bilder/*Moatl*.mp4 "/srv/hdd/Martin/"
	echo "Rechte..."
	sudo chown -R martin:martin "/srv/hdd/Martin"
fi