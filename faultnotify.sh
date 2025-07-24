#!/bin/bash

scriptversion=2507131130

#	 █████  ██      ██       ██████  ███████ ███    ███ ███████ ██ ███    ██
#	██   ██ ██      ██      ██       ██      ████  ████ ██      ██ ████   ██
#	███████ ██      ██      ██   ███ █████   ██ ████ ██ █████   ██ ██ ██  ██
#	██   ██ ██      ██      ██    ██ ██      ██  ██  ██ ██      ██ ██  ██ ██
#	██   ██ ███████ ███████  ██████  ███████ ██      ██ ███████ ██ ██   ████

user=$(whoami)
data="/home/$user/script-data/$(basename "$0")"

if [ ! -d "$data" ]; then
	mkdir -p "$data"
fi

### UPDATES BEGINN ###

# 26.05.24
if [ -d "$data/ipfail" ]; then
	echo "Wende Update-Änderungen an: ipfail -> jail"
	mv "$data/ipfail" "$data/jail"
	sleep 1
fi

### UPDATES ENDE ###

#Speziell für den Fall von systemd-Starts
export TERM=xterm

if [ -z "$1" ]; then
	echo "Aufruf nur möglich mit Argumenten:"
	echo ""
	echo "- \"$0 install\" - (Installation und Einrichtung der Konfiguration),"
	echo "- \"$0 update\"  - Updatevorgang für faultnotify,"
	echo "- \"$0 test\"    - (Testvorgang der Geräte; einmalig oder Dauerschleife),"
	echo "- \"$0 add\"     - (hinzufügen von Geräten) und"
	echo "- \"$0 mod\"     - (modifizieren der Config und der Gerätschaften) möglich."
	echo ""
	echo "- \"$0 on\"      - für Dauerschleifen-Tests (Voraussetzung für -test)"
	echo "- \"$0 off\"     - Dauerschleife deaktivieren"
	echo ""
	echo "Für den Erstbetrieb:"
	echo "1. \"$0 install\""
	echo "2. \"$0 add\""
	echo "3. \"$0 test\""
	exit 1
fi

#	███████ ██    ██ ███    ██ ██   ██ ████████ ██  ██████  ███    ██ ███████ ███    ██ 
#	██      ██    ██ ████   ██ ██  ██     ██    ██ ██    ██ ████   ██ ██      ████   ██ 
#	█████   ██    ██ ██ ██  ██ █████      ██    ██ ██    ██ ██ ██  ██ █████   ██ ██  ██ 
#	██      ██    ██ ██  ██ ██ ██  ██     ██    ██ ██    ██ ██  ██ ██ ██      ██  ██ ██ 
#	██       ██████  ██   ████ ██   ██    ██    ██  ██████  ██   ████ ███████ ██   ████

# Funktion zum Prüfen, ob ein Gerät als offline markiert wurde
is_marked_offline() {
    [ -f "$data/jail/ID$dev_id-R1" ] || [ -f "$data/jail/ID$dev_id-R2" ]
}

# Funktion zum Prüfen, ob ein Port erreichbar ist (für Netcat)
is_port_open() {
    if [ "$protocol" = "UDP" ]; then
        timeout 2 bash -c "</dev/udp/$dev_ip/$dev_port" 2>/dev/null
    else
        timeout 2 bash -c "</dev/tcp/$dev_ip/$dev_port" 2>/dev/null
    fi
}

# Funktion für das Logging
log_event() {
    echo "$(date +"%d.%m.%Y;%H:%M:%S");$1;$dev_ip;$dev_port;$2;$dev_name;$3" >> "$data/logs/events.csv"
}

# Funktion für Benachrichtigungen
notify() {
    local message="$1"
    if [ "$benachrichtigung" = "telegram" ]; then
        curl -s --data "text=$message" --data "chat_id=$telegram_chatid" "https://api.telegram.org/bot$telegram_bottoken/sendMessage" > /dev/null
    else
        echo "$message" >> "$data/email.txt"
    fi
}

#	██ ███    ██ ███████ ████████  █████  ██      ██      
#	██ ████   ██ ██         ██    ██   ██ ██      ██      
#	██ ██ ██  ██ ███████    ██    ███████ ██      ██      
#	██ ██  ██ ██      ██    ██    ██   ██ ██      ██      
#	██ ██   ████ ███████    ██    ██   ██ ███████ ███████ 

if [ "$1" = "install" ] && [ ! -f "$data/.installed" ]; then

if [ ! -d "$data" ]; then
	mkdir -p "$data"
fi

if [ ! -d "$data/jail" ]; then
	mkdir "$data/jail"
fi

if [ ! -d "$data/logs" ]; then
	mkdir "$data/logs"
fi

function install_if_missing {
    PACKAGE=$1
    if ! dpkg -l | grep -qw $PACKAGE; then
        echo "Fehlendes Paket $PACKAGE wird installiert..."
		read -p "OK? "
        sudo apt-get install -y $PACKAGE
    else
        echo "OK: $PACKAGE ist bereits installiert."
    fi
}

	clear
	echo "Faultnotify, die Störungsbenachrichtigung wird nun installiert."
	echo "Nun beginnt der Einrichtungsprozess."
	echo "Diese Installation ist geführt. Es können zu überwachende Geräte hinzugefügt werden."
	sleep 3

	echo ""
	echo "Folgende Pakete müssen installiert sein um einen reibungslosen Ablauf zu gewährleisten:"
	echo ""
	echo "ssmtp mailutils curl netcat-traditional"
	echo ""
	echo "Das Script versucht nun diese Pakete, falls nicht vorhanden, zu installieren."
	echo "Unter Umständen wird das root-Passwort verlangt, wenn das Script nicht als root ausgeführt wird."

	# Update der Paketliste nur einmal
	echo "Aktualisiere Paketliste..."
	sudo apt-get update -y > /dev/null

	# Pakete prüfen und installieren
	install_if_missing "ssmtp"
	install_if_missing "mailutils"
	install_if_missing "curl"
	install_if_missing "netcat-traditional"

	sleep 1
	clear
	echo "Zudem muss sichergestellt werden, dass - im Falle einer Benachrichtigung mit E-Mail - der Server Mails verschicken kann."
	sleep 3

	echo ""
	echo "[Config]" > "$data/config.txt"
	echo "Online-Ping-Prüfung = 8.8.8.8 # Ping-Ziel zur Prüfung des Hosts" >> "$data/config.txt"

	echo "Wie soll die Benachrichtigung erfolgen?"
	read -p "E-Mail ( 1 ) oder Telegram ( 2 ): " benachrichtigung
	echo ""

	verifizierungscode=$(shuf -i 1000-9999 -n1)

	if [ -z "$benachrichtigung" ]; then
		echo "Bitte nicht leer lassen, Abbruch."
		exit 1

	elif [ "$benachrichtigung" = "1" ]; then
		echo "Okay, E-Mail."
		echo "Bitte Empfänger-Adresse eingeben, bei mehreren Mailadressen mit Komma trennen, z. B. 'a@b.de,c@d.at'"
		read -p "Adresse(n): " email

		#E-Mail - Bestätigungscode?
		echo ""
		echo "Kann der Server E-Mails versenden?"
		echo "Es wird ein Verifizierungscode verschickt zur Bestätigung."
		echo "Falls dies missglücken sollte, wird die Installation ganz normal weiter geführt, es liegt in der Selbstverantwortung."
		echo "Die Mail wird an die angegebene(n) Adressen verschickt."

		#Sendevorgang
		echo "Verifizierungscode: $verifizierungscode" | mail -s "Faultnotify - Verifizierungscode" "$email"
		echo ""
		read -p "Verifizierungscode von E-Mail (leer lassen für Abbruch): " re_verifizierungscode

		if [ "$verifizierungscode" = "$re_verifizierungscode" ]; then
			echo "Verifizierung erfolgreich abgeschlossen."
		else
			echo "Verifizierung missglückt."
			echo "Die Installation wird dennoch fortgeführt. Im Anschluss kann die Email berichtigt werden in der Konfigurationsdatei unter \"$data\" oder der Server eigenverantwortlich zum Versand vorbereitet werden."
		fi

		echo ""
		echo "Benachrichtigung = email # \"email\" oder \"telegram\"" >> "$data/config.txt"
		echo "E-Mail-Adresse = $email #Empfänger-Adresse. Bei mehreren mit Komma ohne Leerzeichen trennen: \"a@b.de,c@d.at\"" >> "$data/config.txt"
		echo "Telegram-Bot:Token = " >> "$data/config.txt"
		echo "Telegram Chat-ID = " >> "$data/config.txt"

		echo "E-Mail-Adresse(n) $email registriert."

	elif [ "$benachrichtigung" = "2" ]; then
		echo "Okay, Telegram."
		read -p "Bitte den Telegram-Bot mit Token eintragen (Bot:Token): " telegram_bottoken
		read -p "Bitte die Telegram-Chat-ID eintragen: " telegram_chatid

		#Telegram - Bestätigungscode?
		echo ""
		echo "Kann über den BotToken zur Chat ID eine Nachricht gesendet werden?"
		echo "Es wird ein Verifizierungscode verschickt zur Bestätigung."
		echo "Falls dies missglücken sollte, wird die Installation ganz normal weiter geführt, es liegt in der Selbstverantwortung."

		#Sendevorgang
		curl -s --data "text=Faultnotify - Verifizierungscode: $verifizierungscode" --data "chat_id=$telegram_chatid" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
		echo ""
		read -p "Verifizierungscode von Telegram (leer lassen für Abbruch): " re_verifizierungscode

		if [ "$verifizierungscode" = "$re_verifizierungscode" ]; then
			echo "Verifizierung erfolgreich abgeschlossen."
		else
			echo "Die Installation wird dennoch fortgeführt. Im Anschluss können die Telegram-Einstellungen berichtigt werden in der Konfigurationsdatei unter \"$data\"."
		fi

		echo ""
		echo "Benachrichtigung = telegram # \"email\" oder \"telegram\"" >> "$data/config.txt"
		echo "E-Mail-Adresse =  #Empfänger-Adresse. Bei mehreren mit Komma ohne Leerzeichen trennen." >> "$data/config.txt"
		echo "Telegram-Bot:Token = $telegram_bottoken" >> "$data/config.txt"
		echo "Telegram Chat-ID = $telegram_chatid" >> "$data/config.txt"

		echo "Telegram registriert."
	else
		echo "Fehler, nur 1 oder 2 sind möglich."
		exit 1
	fi

	echo "nächste Geräte ID = 1" >> "$data/config.txt"
	echo "" >> "$data/config.txt"
	echo "[Geräte/Dienste]" >> "$data/config.txt"

	echo "Ersteinrichtung fertig. Hinzufügen der Geräte per \"$0 add\""
	touch "$data/.installed"

	exit 0

#else
#	echo "Programm wurde bereits installiert."
#	echo "Modifizieren der Konfiguration mit \"$0 mod\" möglich."
#	exit 1
fi

#	 █████  ██████  ██████ 
#	██   ██ ██   ██ ██   ██
#	███████ ██   ██ ██   ██
#	██   ██ ██   ██ ██   ██
#	██   ██ ██████  ██████ 

if [ "$1" = "add" ] && [ -f "$data/.installed" ]; then

	clear
	echo "Hinzufügen der zu überwachenden Geräte im Faultnotify, dem Störungsbenachrichtigungsdienst"
	echo ""

	while true; do

		x=$(grep -w "nächste Geräte ID" "$data/config.txt" | cut -d '=' -f 2 | cut -d '#' -f 1 | tr -d ' ')
		y=$(printf %03d $x)

		# Eingabeaufforderung für Gerätenamen
		read -p "Bitte den Namen des neuen Geräts/Dienstes ID Nr. $x eingeben (leer lassen zum Beenden): " dev_name

		# Überprüfen, ob der Gerätename nicht leer ist
		if [ -z "$dev_name" ]; then
			echo ""
			echo "Sektor Geräte hinzufügen wird beendet."
			break
		fi

		# ersetze kritische Zeichen aus der Eingabe - [=|&] - mehrere möglich (grep+sed)
		if echo "$dev_name" | grep -E "[=]" >/dev/null; then
			echo "Hinweis: Kritische Zeichen wurden ersetzt."
			dev_name=$(echo "$dev_name" | sed -E 's/[=]/_/g')
		fi

		# Eingabeaufforderung für die IP-Adresse des Geräts
		read -p "| > Bitte die IP-Adresse oder Domain des Geräts/Dienstes $dev_name eingeben: " dev_ip

		# Überprüfen, ob die IP-Adresse oder Domain nicht leer und gültig ist
		if ! [[ "$dev_ip" =~ ^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+|[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})$ ]]; then
			echo "Ungültige IP-Adresse oder Domain. Bitte erneut eingeben."
			continue
		fi

		# Eingabeaufforderung für die IP-Adresse des Geräts
		read -p "| >> Handelt es sich hier um einen Dienst? Wenn ja, welcher Port soll überwacht werden? Leer lassen für nein: " dev_port

		# Überprüfen, ob die IP-Adresse nicht leer und gültig ist
		if [ -n "$dev_port" ] && ! [[ "$dev_port" =~ ^[1-9][0-9]{0,4}$ && "$dev_port" -ge 1 && "$port" -le 65535 ]]; then
			echo "Ungültiger Port. Bitte erneut eingeben."
			continue
		fi

		if [ -n "$dev_port" ]; then
			read -p "| >>> Handelt es sich um das UDP-Protokoll? Eingabe \"ja\", \"u\" oder \"udp\". Leer lassen für normales TCP: " dev_protocol_roh

			dev_protocol=$(echo "$dev_protocol_roh" | sed 's/.*/\L&/')
			if [ -z "$dev_protocol_roh" ]; then
				# Eingabe ist leer
				dev_protocol=""
			elif [ "$dev_protocol" != "ja" ] && [ "$dev_protocol" != "u" ] && [ "$dev_protocol" != "udp" ]; then
				# Eingabe ist nicht leer und nicht "ja", "u" oder "udp"
				echo "Ungültige Eingabe. Bitte erneut eingeben."
				continue
			else
				# Eingabe ist "ja", "u" oder "udp"
				dev_protocol="u"
			fi
		fi


		# Schreibe die Informationen in die Konfigurationsdatei
		echo "ID $y = $dev_name = $dev_ip = $dev_port $dev_protocol" >> "$data/config.txt"

		echo "$(date +"%d.%m.%Y;%H:%M:%S");$1;$y;$dev_name;$dev_ip;$dev_port;$dev_protocol" >> "$data/logs/allgemein.csv"

		# Inkrementiere die Zählvariable für das nächste Gerät
		neux=$((x + 1))
		sed -i "s/nächste Geräte ID = $x/nächste Geräte ID = $neux/" "$data/config.txt"

		echo ""

	done
	touch "$data/.added"
	exit 0

elif [ ! -f "$data/.installed" ]; then
	echo "Programm nicht installiert, bitte erst mit \"$0 install\" installieren."
	exit 1
fi

#	███    ███  ██████  ██████ 
#	████  ████ ██    ██ ██   ██
#	██ ████ ██ ██    ██ ██   ██
#	██  ██  ██ ██    ██ ██   ██
#	██      ██  ██████  ██████

if [ "$1" = "mod" ] && [ -f "$data/.installed" ]; then

	echo "Modifizierungs-Sektor"
	echo ""
	
# Schleife durch alle Zeilen der Konfigurationsdatei
	while IFS= read -r line; do
		# Überprüfen, ob die Zeile mit "Gerät" beginnt
		if [[ "$line" == ID* ]]; then

			# Extrahieren von Geräte-Namen und IP-Adresse
			dev_id=$(echo "$line" | cut -d '=' -f 1 | cut -d ' ' -f 2)
			dev_name=$(echo "$line" | cut -d '=' -f 2 | cut -d '#' -f 1 | sed 's/^[ \t]*//;s/[ \t]*$//')
			dev_ip=$(echo "$line" | cut -d '=' -f 3 | cut -d '#' -f 1 | tr -d ' ')
			dev_port=$(echo "$line" | cut -d '=' -f 4 | cut -d ' ' -f 2 | cut -d '#' -f 1 | tr -d ' ')
			dev_protocol=$(echo "$line" | cut -d '=' -f 4 | cut -d ' ' -f 3 | cut -d '#' -f 1 | tr -d ' ')

			#wenn ein Port angegeben ist, zeige einen Doppelpunkt an in der Auflistung
			if [ -n "$dev_port" ]; then
				doppelpunkt=":"
			else
				doppelpunkt=""
			fi

			if [ -n "$dev_port" ]; then
				if [ -n "$dev_protocol" ]; then
					dev_protocol="UDP"
				else
					dev_protocol="TCP"
				fi
			fi

			#auffüllen auf x Zeichen
			length=${#dev_name}
			while [ $length -lt 30 ]; do
			    dev_name="$dev_name "
			    ((length++))
			done
			dev_name="${dev_name:0:30}"

			#Geräteauflistung
			echo "ID$dev_id | $dev_name | $dev_ip $doppelpunkt $dev_port $dev_protocol"

		fi
	done < "$data/config.txt"

	echo ""
	echo "Was soll geändert werden?"
	echo "Die Eingabe kann die ID sein (IDx/IDxx/IDxxx), der Name in Such-Form (Icecast) oder die IP als Ganzes (172.16.10.135)."
	echo ""
	read -p "Eingabe: " input_roh

	#Schreibe vom Input her alles klein
	input_mod=$(echo "$input_roh" | sed 's/.*/\L&/')
	
	#wenn im "$input_mod" "id" enthalten ist, DANN
	if [[ "$input_mod" =~ ^id+ ]]; then
		#ersetze mit "idxxx =" - immer 3stellig UND
		input_mod=$(echo "$input_mod" | sed -E -e 's/id([0-9]{3})/id \1 =/' -e 's/id([0-9]{2})/id 0\1 =/' -e 's/id([0-9]{1})/id 00\1 =/')
		#setze "input_id" auf 1
		input_id="1"
	fi

	if [ -z "$input_roh" ]; then
		echo "Keine Eingabe, nach nichts kann nicht gesucht werden."
		exit 1
	fi

	# wenn NICHT nach ID gesucht wird, aber kein Eintrag da ist
	if ! [ "$input_id" = "1" ] && [ $(grep -i -c "ID.*$input_mod" "$data/config.txt") -lt "1" ]; then
		echo "Bitte Suche verfeinern, \"$input_mod\" enthält keinen Eintrag."
		exit 1
	# wenn NICHT nach ID gesucht wird, aber mehrere Einträge da sind
	elif ! [ "$input_id" = "1" ] && [ $(grep -i -c "ID.*$input_mod" "$data/config.txt") -gt "1" ]; then
		echo "Bitte Suche verfeinern, \"$input_mod\" enthält mehrere Einträge."
		exit 1
	# wenn nach ID gesucht wird, aber kein Eintrag da ist
	elif [ "$input_id" = "1" ] && [ $(grep -i -c "^$input_mod" "$data/config.txt") -lt "1" ]; then
		echo "Bitte Suche verfeinern, \"$input_mod\" enthält keinen Eintrag."
		exit 1
	# wenn nach ID gesucht wird, aber mehrere Einträge da sind
	elif [ "$input_id" = "1" ] && [ $(grep -i -c "^$input_mod" "$data/config.txt") -gt "1" ]; then
		echo "Bitte Suche verfeinern, \"$input_mod\" enthält mehrere Einträge."
		exit 1
	fi

	echo ""
	echo "Folgende Zeile ist betroffen: $(grep -i "$input_mod" "$data/config.txt")"
	echo "Was soll geschehen?"
	echo ""
	echo "1 - Eintrag löschen und neu definieren"
	echo "2 - Eintrag ersatzlos löschen"
	read -p "Auswahl: " input_menu

	if [ "$input_menu" = "1" ]; then
		# entferne die Zeile aus der config
		sed -i "/$(grep -i "$input_mod" "$data/config.txt")/d" "$data/config.txt"
		echo ""
		# starte den add-Vorgang
		$0 add
		echo "Gerät/Dienst gelöscht und neu hinzugefügt."
		echo "$(date +"%d.%m.%Y;%H:%M:%S");$1;$input_mod;gelöscht & neu hinzugefügt" >> "$data/logs/allgemein.csv"
		exit 0
	elif [ "$input_menu" = "2" ]; then
		# entferne die Zeile aus der config
		sed -i "/$(grep -i "$input_mod" "$data/config.txt")/d" "$data/config.txt"
		echo ""
		echo "Gerät/Dienst gelöscht."
		echo "$(date +"%d.%m.%Y;%H:%M:%S");$1;$input_mod;gelöscht" >> "$data/logs/allgemein.csv"
		exit 0
	else
		echo "Keine gültige Auswahl."
		exit 1
	fi

elif [ ! -f "$data/.installed" ]; then
	echo "Programm nicht installiert, bitte erst mit \"$0 install\" installieren."
	exit 1
fi

#	████████ ███████ ███████ ████████
#	   ██    ██      ██         ██
#	   ██    █████   ███████    ██
#	   ██    ██           ██    ██
#	   ██    ███████ ███████    ██

if [ "$1" = "test" ] && [ -f "$data/.installed" ] && [ -f "$data/.added" ]; then

	if [ ! -f "$data/.work" ]; then
		echo ""
		echo "Keine Automatik aktiviert. Einmaliges Testen der Geräte erlauben?"
		echo "Zukünftig: \"$0 on\" für Automatik einschalten, \"$0 off\" für aus."
		echo "Erst dann beginnt der Testsektor ohne diesen Aufforderungsabschnitt zu arbeiten."
		echo ""
		read -p "ENTER für ja, ansonsten STRG+C für Abbruch. "
		touch "$data/.work"
		temp="ja"
	fi

	# while ping $ping_ext = true, do
	# else echo "Störung der Internetleitung. Kann nicht testen, E-Mail wurde zurückgehalten" >> $data/email ...
	# wenn wieder geht, dann schicke Email

	#beginne mit 1 bei den Geräten, deren Anzahl mit einer Pause abgeschlossen wird
	dev_now="1"

	while [ -f "$data/.work" ]; do

		ping_ext=$(grep -w "Online-Ping-Prüfung" "$data/config.txt" | cut -d '=' -f 2 | cut -d '#' -f 1 | tr -d ' ')
		benachrichtigung=$(grep -w "Benachrichtigung" "$data/config.txt" | cut -d '=' -f 2 | cut -d '#' -f 1 | tr -d ' ')
		email=$(grep -w "E-Mail-Adresse" "$data/config.txt" | cut -d '=' -f 2 | cut -d '#' -f 1 | tr -d ' ')
		telegram_bottoken=$(grep -w "Telegram-Bot:Token" "$data/config.txt" | cut -d '=' -f 2 | cut -d '#' -f 1 | tr -d ' ')
		telegram_chatid=$(grep -w "Telegram Chat-ID" "$data/config.txt" | cut -d '=' -f 2 | cut -d '#' -f 1 | tr -d ' ')
	
		clear
		echo "Testsektor - Prüfung der Geräte - im Fehlerfall Störungsbenachrichtigung per $benachrichtigung."
		echo ""
	
		# Schleife durch alle Zeilen der Konfigurationsdatei
		while IFS= read -r line; do

			# Überprüfen, ob die Zeile mit "ID" beginnt
			if [[ "$line" == ID* ]]; then

				# Extrahieren von Geräte-Namen und IP-Adresse
				dev_id=$(echo "$line" | cut -d '=' -f 1 | cut -d ' ' -f 2)
				dev_name=$(echo "$line" | cut -d '=' -f 2 | cut -d '#' -f 1 | sed 's/^[ \t]*//;s/[ \t]*$//')
				dev_ip=$(echo "$line" | cut -d '=' -f 3 | cut -d '#' -f 1 | tr -d ' ')
				dev_port=$(echo "$line" | cut -d '=' -f 4 | cut -d ' ' -f 2 | cut -d '#' -f 1 | tr -d ' ')
				dev_protocol=$(echo "$line" | cut -d '=' -f 4 | cut -d ' ' -f 3 | cut -d '#' -f 1 | tr -d ' ')
				dev_anz=$(grep -c '^ID ' "$data/config.txt")

				if [ -n "$dev_port" ]; then
					if [ -n "$dev_protocol" ]; then
						dev_protocol="(udp)"
					else
						dev_protocol=""
					fi
				fi



#				██       ██████  ██ ███    ██  ██████  
#				 ██      ██   ██ ██ ████   ██ ██       
#				  ██     ██████  ██ ██ ██  ██ ██   ███ 
#				 ██      ██      ██ ██  ██ ██ ██    ██ 
#				██       ██      ██ ██   ████  ██████  



				if [ -z "$dev_port" ]; then #wenn kein Port,
					if [ ! -f "$data/jail/ID$dev_id-R1" ] && [ ! -f "$data/jail/ID$dev_id-R2" ]; then #und wenn keine jail-Merkung
						if ping -w 8 -c 1 $dev_ip > /dev/null; then
							echo "✓ ONLINE: Gerät $dev_name ($dev_ip) ist online."
						else
							echo "Runde 2: Gerät $dev_name ($dev_ip)"
	#						continue
							if ping -w 8 -c 5 $dev_ip > /dev/null; then
								echo "✓! ONLINE: Gerät $dev_name ($dev_ip) ist online."
							else
								echo "✘ AUSFALL / STÖRUNG: Gerät $dev_name ($dev_ip) ist nicht mehr erreichbar."
								touch "$data/jail/ID$dev_id-R1"

								echo "$(date +"%d.%m.%Y;%H:%M:%S");$1;$dev_ip;;;$dev_name;1. offline" >> "$data/logs/events.csv"

								if [ "$benachrichtigung" = "telegram" ]; then
									curl -s --data "text=✘ AUSFALL / STÖRUNG: Gerät $dev_name ($dev_ip) ist nicht mehr erreichbar." --data "chat_id=$telegram_chatid" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
								else
									echo "✘ AUSFALL / STÖRUNG: Gerät $dev_name ($dev_ip) ist nicht mehr erreichbar." >> "$data/email.txt"
								fi
							fi
						fi
					else
						if ping -w 8 -c 1 $dev_ip > /dev/null; then
							echo "✓ WIEDER ONLINE: Gerät $dev_name ($dev_ip) wieder erreichbar."

							echo "$(date +"%d.%m.%Y;%H:%M:%S");$1;$dev_ip;;;$dev_name;wieder erreichbar" >> "$data/logs/events.csv"

							if [ "$benachrichtigung" = "telegram" ]; then
								curl -s --data "text=✓ WIEDER ONLINE: Gerät $dev_name ($dev_ip) ist wieder online." --data "chat_id=$telegram_chatid" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
							else
								echo "✓ WIEDER ONLINE: Gerät $dev_name ($dev_ip) wieder erreichbar." >> "$data/email.txt"
							fi

							if [ -f "$data/jail/ID$dev_id-R2" ]; then
								rm "$data/jail/ID$dev_id-R2"
							else
								rm "$data/jail/ID$dev_id-R1"
							fi
						else
							if ping -w 8 -c 5 $dev_ip > /dev/null; then
								echo "✓! WIEDER ONLINE: Gerät $dev_name ($dev_ip) wieder erreichbar."

								echo "$(date +"%d.%m.%Y;%H:%M:%S");$1;$dev_ip;;;$dev_name;wieder erreichbar" >> "$data/logs/events.csv"

								if [ "$benachrichtigung" = "telegram" ]; then
									curl -s --data "text=✓! WIEDER ONLINE: Gerät $dev_name ($dev_ip) ist wieder online." --data "chat_id=$telegram_chatid" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
								else
									echo "✓! WIEDER ONLINE: Gerät $dev_name ($dev_ip) wieder erreichbar." >> "$data/email.txt"
								fi

								if [ -f "$data/jail/ID$dev_id-R2" ]; then
									rm "$data/jail/ID$dev_id-R2"
								else
									rm "$data/jail/ID$dev_id-R1"
								fi
							else
								echo "✘ OFFLINE: Gerät $dev_name ($dev_ip) ist weiterhin offline."
								if [ -f "$data/jail/ID$dev_id-R1" ]; then
									mv "$data/jail/ID$dev_id-R1" "$data/jail/ID$dev_id-R2"
								fi
							fi
						fi
					fi



#				██       ███    ██ ███████ ████████  ██████  █████  ████████ 
#				 ██      ████   ██ ██         ██    ██      ██   ██    ██    
#				  ██     ██ ██  ██ █████      ██    ██      ███████    ██    
#				 ██      ██  ██ ██ ██         ██    ██      ██   ██    ██    
#				██       ██   ████ ███████    ██     ██████ ██   ██    ██    



				elif [ -n "$dev_port" ]; then
					if [ ! -f "$data/jail/ID$dev_id-R1" ] && [ ! -f "$data/jail/ID$dev_id-R2" ]; then
						if [ -n "$dev_protocol" ]; then
							if nc -z -w 1 -u "$dev_ip" "$dev_port" 2>/dev/null; then
								echo "✓ ONLINE: Dienst $dev_name ($dev_ip:$dev_port/udp) ist online."
							else
								if nc -z -w 2 -u "$dev_ip" "$dev_port" 2>/dev/null; then
									echo "✓! ONLINE: Dienst $dev_name ($dev_ip:$dev_port/udp) ist online."
								else
									echo "✘ AUSFALL / STÖRUNG: Dienst $dev_name ($dev_ip:$dev_port/udp) ist nicht mehr erreichbar."
									touch "$data/jail/ID$dev_id-R1"

									echo "$(date +"%d.%m.%Y;%H:%M:%S");$1;$dev_ip;$dev_port;UDP;$dev_name;1. offline" >> "$data/logs/events.csv"

									if [ "$benachrichtigung" = "telegram" ]; then
										curl -s --data "text=✘ AUSFALL / STÖRUNG: Dienst $dev_name ($dev_ip:$dev_port/udp) ist nicht mehr erreichbar." --data "chat_id=$telegram_chatid" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
									else
										echo "✘ AUSFALL / STÖRUNG: Dienst $dev_name ($dev_ip:$dev_port/udp) ist nicht mehr erreichbar." >> "$data/email.txt"
									fi
								fi
							fi
						else
							if nc -z -w 1 "$dev_ip" "$dev_port" 2>/dev/null; then
								echo "✓ ONLINE: Dienst $dev_name ($dev_ip:$dev_port) ist online."
							else
								if nc -z -w 1 "$dev_ip" "$dev_port" 2>/dev/null; then
									echo "✓! ONLINE: Dienst $dev_name ($dev_ip:$dev_port) ist online."
								else
									echo "✘ AUSFALL / STÖRUNG: Dienst $dev_name ($dev_ip:$dev_port) ist nicht mehr erreichbar."
									touch "$data/jail/ID$dev_id-R1"

									echo "$(date +"%d.%m.%Y;%H:%M:%S");$1;$dev_ip;$dev_port;TCP;$dev_name;1. offline" >> "$data/logs/events.csv"

									if [ "$benachrichtigung" = "telegram" ]; then
										curl -s --data "text=✘ AUSFALL / STÖRUNG: Dienst $dev_name ($dev_ip:$dev_port) ist nicht mehr erreichbar." --data "chat_id=$telegram_chatid" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
									else
										echo "✘ AUSFALL / STÖRUNG: Dienst $dev_name ($dev_ip:$dev_port) ist nicht mehr erreichbar." >> "$data/email.txt"
									fi
								fi
							fi
						fi
					else
						if [ -n "$dev_protocol" ]; then
							if nc -z -w 2 -u "$dev_ip" "$dev_port" 2>/dev/null; then
								echo "✓ WIEDER ONLINE: Dienst $dev_name ($dev_ip:$dev_port/udp) wieder erreichbar."

								echo "$(date +"%d.%m.%Y;%H:%M:%S");$1;$dev_ip;$dev_port;UDP;$dev_name;wieder online" >> "$data/logs/events.csv"

								if [ "$benachrichtigung" = "telegram" ]; then
									curl -s --data "text=✓ WIEDER ONLINE: Dienst $dev_name ($dev_ip:$dev_port/udp) ist wieder online." --data "chat_id=$telegram_chatid" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
								else
									echo "✓ WIEDER ONLINE: Dienst $dev_name ($dev_ip:$dev_port/udp) wieder erreichbar." >> "$data/email.txt"
								fi

								if [ -f "$data/jail/ID$dev_id-R2" ]; then
									rm "$data/jail/ID$dev_id-R2"
								else
									rm "$data/jail/ID$dev_id-R1"
								fi
							else
								echo "✘ OFFLINE: Dienst $dev_name ($dev_ip:$dev_port/udp) ist weiterhin offline."

								if [ -f "$data/jail/ID$dev_id-R1" ]; then
									mv "$data/jail/ID$dev_id-R1" "$data/jail/ID$dev_id-R2"
								fi
							fi
						else				
							if nc -z -w 2 "$dev_ip" "$dev_port" 2>/dev/null; then
								echo "✓ WIEDER ONLINE: Dienst $dev_name ($dev_ip:$dev_port) wieder erreichbar."

								echo "$(date +"%d.%m.%Y;%H:%M:%S");$1;$dev_ip;$dev_port;TCP;$dev_name;wieder online" >> "$data/logs/events.csv"

								if [ "$benachrichtigung" = "telegram" ]; then
									curl -s --data "text=✓ WIEDER ONLINE: Dienst $dev_name ($dev_ip:$dev_port) ist wieder online." --data "chat_id=$telegram_chatid" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
								else
									echo "✓ WIEDER ONLINE: Dienst $dev_name ($dev_ip:$dev_port) wieder erreichbar." >> "$data/email.txt"
								fi

								if [ -f "$data/jail/ID$dev_id-R2" ]; then
									rm "$data/jail/ID$dev_id-R2"
								else
									rm "$data/jail/ID$dev_id-R1"
								fi
							else
								echo "✘ OFFLINE: Dienst $dev_name ($dev_ip:$dev_port) ist weiterhin offline."

								if [ -f "$data/jail/ID$dev_id-R1" ]; then
									mv "$data/jail/ID$dev_id-R1" "$data/jail/ID$dev_id-R2"
								fi
							fi
						fi
					fi
				fi

				if ! [ "$temp" = "ja" ]; then
					if [ "$dev_now" = "$dev_anz" ]; then
						dev_now="1"

						if [ -f "$data/email.txt" ]; then
							echo "> Sende E-Mail..."
							cat "$data/email.txt" | mail -s "Faultnotify - Zusammenfassung" "$email"
							rm "$data/email.txt"
						fi

						echo "- Beginne Prüfung von vorne - warte 5 Sekunden..."
						sleep 5
					else
						dev_now=$((dev_now + 1))
					fi
				fi
			fi

		done < "$data/config.txt"

		if [ -f "$data/email.txt" ]; then
			echo "> Sende E-Mail..."
			cat "$data/email.txt" | mail -s "Faultnotify - Zusammenfassung" "$email"
			rm "$data/email.txt"
		fi

		if [ "$temp" = "ja" ]; then
			rm "$data/.work"
		fi

	done

	exit 0

elif [ ! -f "$data/.installed" ]; then
	echo "Programm nicht installiert, bitte erst mit \"$0 install\" installieren."
	exit 1

elif [ ! -f "$data/.added" ]; then
	echo "Keine Geräte hinzugefügt. Bitte zuerst mit \"$0 add\" Geräte aufnehmen, die getestet werden sollen."
	exit 1
fi

if [ "$1" = "on" ]; then
	touch "$data/.work"
	echo "Automatik eingeschaltet."
	exit 0
fi

if [ "$1" = "off" ]; then
	rm "$data/.work"
	echo "Automatik ausgeschaltet."
	exit 0
fi

exit 0
