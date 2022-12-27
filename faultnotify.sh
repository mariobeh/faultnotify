#!/bin/bash

user=$(whoami)
data="/home/$user/script-data/faultnotify"
zeitstempel=$(date +"%d.%m.%Y %H:%M")
crontab_datum=$(date +"%y-%m-%d")

if [ ! -d "$data" ]; then
	mkdir -p "$data"
fi

# Updater & Reverse Updater BEGINN
scriptversion=2212262349
scriptname=faultnotify.sh
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

if [ ! -d "$data/ipfail" ]; then
	mkdir "$data/ipfail"
fi

if [ ! -f "$data/config.txt" ]; then
	clear
	echo "Dieses Script wird zum ersten Mal ausgeführt."
	echo "Nun beginnt der Einrichtungsprozess."
	echo "Diese Installation ist geführt, das heißt, Du kannst jederzeit die Installation unterbrechen und fortsetzen."
	sleep 5
	echo ""
	echo "Es werden nun die Programme installiert, die für den störungsfreien Betrieb dieses Scripts benötigt werden."
	echo "Dafür sind root-Rechte (sudo) erforderlich. Wenn diese bereits installiert sind, wird dieser Schritt übersprungen."
	# ggf. wenn Programmdateien da sind, überspringen
	sleep 5
	sudo apt-get install ssmtp mailutils curl -y
	echo "[Allgemein]" > "$data/config.txt"
	echo "IPping = 8.8.8.8 # Ping-Ziel zur Prüfung des Hosts" >> "$data/config.txt"
	echo "ping_main = 6 1 # sek/count" >> "$data/config.txt"
	echo "ping_dev = 3 1 # sek/count" >> "$data/config.txt"
	echo "Fertig."
	sleep 3
	echo "A01" > "$data/install.txt"
fi
if [ -f "$data/install.txt" ]; then
	prozess=$(cat "$data/install.txt" | head -n1 | tail -n1)
fi
if [ "$prozess" = "A01" ]; then
	clear
	echo "Wie willst Du benachrichtigt werden? Du hast die Auswahl über Telegram oder klassisch per Mail."
	echo "Je nachdem, was Du wählst, wirst Du aufgefordert, Einstellungen und Eingaben zu treffen."
	echo ""
	read -p "E-Mail ( 1 ) oder Telegram ( 2 ) ? " benachrichtigung
	echo ""
	# ggf. bei Falscheingabe ebenfalls Abbruch.
	if [ -z "$benachrichtigung" ]; then
		echo "Bitte nicht leer lassen, Abbruch."
		sleep 3
		$0
		exit
	fi
fi
# E-MAIL BEGINN
if [ "$benachrichtigung" = "1" ]; then
	echo ""
	echo "Okay, E-Mail."
	sleep 2
	echo "Die Einstellungen können jetzt hier im Script eingegeben werden."
	echo "So entsteht eine E-Mail-Konfigurationsdatei, die dann nur händisch im System eingepflegt werden muss."
	echo "Du findest sie dann hier: $data/ssmtp.conf,"
	echo "diese muss dann als root (sudo) nach /etc/ssmtp/ssmtp.conf verschoben werden."
	echo "A02a" > "$data/install.txt"
fi
if [ -f "$data/install.txt" ]; then
	prozess=$(cat "$data/install.txt" | head -n1 | tail -n1)
fi
if [ "$prozess" = "A02a" ]; then
	clear
	echo "benachrichtigung = email # Schalter: 'email' oder 'telegram'" >> "$data/config.txt"
	echo "" >> "$data/config.txt"
	echo "[E-Mail]" >> "$data/config.txt"
	read -p "E-Mail-Absendername: " absendername
	echo "Okay."
	sleep 1
	read -p "Postausgangsserver (smtp-Adresse): " smtpsrv
	read -p "...und SMTP-Port: " smtpport
	echo "Okay."
	sleep 1
	echo "Und nun Angaben zum E-Mail-Account selbst."
	read -p "Benutzername (E-Mail-Adresse): " emailacc
	read -p "Passwort: " emailpw
	echo "Hinweis: Hier wird das TLS-Verschlüsselungsverfahren verwendet. Sollte dies nicht nötig sein, bitte manuell in der ssmtp.conf nachtragen."
	echo "Okay, Danke, erster Schritt geschafft."
	sleep 2
	echo ""
	echo "ssmtp.conf wird erstellt..."
	# erstelle ssmtp.conf BEGINN
	echo "root=$absendername" >> "$data/ssmtp.conf"
	echo "mailhub=$smtpsrv:$smtpport" >> "$data/ssmtp.conf"
	echo "AuthUser=$emailacc" >> "$data/ssmtp.conf"
	echo "AuthPass=$emailpw" >> "$data/ssmtp.conf"
	echo "UseTLS=YES" >> "$data/ssmtp.conf"
	echo "UseSTARTTLS=YES" >> "$data/ssmtp.conf"
	# erstelle ssmtp.conf ENDE
	sleep 2
	echo ""
	echo "Bitte gib jetzt die E-Mail-Adresse ein, die bei Ausfall benachrichtigt werden soll."
	read -p "E-Mail-Adresse: " emailmaster
	echo "email_master = $emailmaster" >> "$data/config.txt"
	# Gegeneingabe im Script für spätere Änderung email>telegram BEGINN
	echo "" >> "$data/config.txt"
	echo "[Telegram]" >> "$data/config.txt"
	echo "bottoken = " >> "$data/config.txt"
	echo "master_chat_id = " >> "$data/config.txt"
	# Gegeneingabe im Script für spätere Änderung email>telegram ENDE
	echo "" >> "$data/config.txt"
	echo "[Geräte]" >> "$data/config.txt"
	echo "A03" > "$data/install.txt"
	echo "Fertig."
	sleep 2
fi
# E-MAIL ENDE
# TELEGRAM BEGINN
if [ "$benachrichtigung" = "2" ]; then
	echo ""
	echo "Okay, Telegram."
	sleep 2
	echo "Die Einstellungen können jetzt hier im Script eingegeben werden."
	echo "Telegram ist um ein vielfaches schwieriger, hast Du schon einen Bot?"
	echo "Falls nein, bekommst Du hier nur eine Anleitung, die Schritte musst Du selbst machen."
	echo "Falls ja, gehen wir einfach die Konfigurationen durch."
	echo "A02b" > "$data/install.txt"
fi
if [ -f "$data/install.txt" ]; then
	prozess=$(cat "$data/install.txt" | head -n1 | tail -n1)
fi
if [ "$prozess" = "A02b" ]; then
	clear
	read -p "Bot vorhanden? ja ( 1 ) oder nein ( 2 ): " telegrambot
	if [ -z "$telegrambot" ]; then
		echo "Bitte nicht leer lassen, Abbruch."
		sleep 3
		$0
		exit
	fi
	if [ "$telegrambot" = "1" ]; then
		echo ""
		echo "Okay, vorhanden, super!"
		echo "Bitte gib den Bot:Token ein, bestehend aus Zahlen und Buchstaben, mit Doppelpunkt getrennt."
		echo "Die Daten entnimmst du nach Erstellen des Bots hier:"
		echo "https://api.telegram.org/botBOTTOKEN/getUpdates - ersetze BOTTOKEN mit deinen Daten."
		echo ""
		read -p "Bot:Token: " bottoken
		echo "Okay."
		sleep 2
		echo "Gib nun die Telegram-Chat-ID vom Master ein, welcher benachrichtigt werden soll."
		echo ""
		read -p "Telegram-Chat-ID vom Master: " master_chat_id
		echo ""
		echo "Okay, Danke. Nun wird der Telegram-Bot getestet."
		echo "Zur Verifizierung bitte den Bestätigungscode eingeben, der soeben per Telegram gesendet wurde."
		echo ""
		verifizierungscode=$(shuf -i 1000-9999 -n1)
		curl -s --data "text=Dein Verifizierungscode: $verifizierungscode" --data "chat_id=$master_chat_id" 'https://api.telegram.org/bot'$bottoken'/sendMessage' > /dev/null
		echo ""
		read -p "Verifizierungs-Code: " telegram_verifizierung
		if [ "$verifizierungscode" = "$telegram_verifizierung" ]; then
			echo "benachrichtigung = telegram # Schalter für 'email' oder 'telegram'" >> "$data/config.txt"
			echo "" >> "$data/config.txt"
			echo "[Telegram]" >> "$data/config.txt"
			echo "bottoken = $bottoken" >> "$data/config.txt"
			echo "master_chat_id = $master_chat_id" >> "$data/config.txt"
			# Gegeneingabe im Script für spätere Änderung telegram>email BEGINN
			echo "" >> "$data/config.txt"
			echo "[E-Mail]" >> "$data/config.txt"
			echo "email_master = " >> "$data/config.txt"
			# Gegeneingabe im Script für spätere Änderung telegram>email ENDE
			echo "" >> "$data/config.txt"
			echo "[Geräte]" >> "$data/config.txt"
			echo "A03" > "$data/install.txt"
			echo ""
			echo "Das wars erstmal hier. Vielen Dank!"
			sleep 3
		else
			echo ""
			echo "Das hat nicht geklappt, bitte noch einmal die Daten eingeben."
			sleep 3
			$0
			exit
		fi
	else
		echo ""
		echo "Okay, nicht vorhanden - kein Problem."
		echo "Ich zeige Dir die Anleitung."
		echo ""
		echo "https://www.christian-luetgens.de/homematic/telegram/botfather/Chat-Bot.htm"
		echo ""
		echo "Die Daten entnimmst du nach Erstellen des Bots hier:"
		echo "https://api.telegram.org/botBOTTOKEN/getUpdates - ersetze BOTTOKEN mit deinen Daten."
		echo ""
		echo "Erstelle nach dieser Anleitung den Bot und starte dann mit dem Teilabschnitt neu."
		echo "Alternativ kannst Du auch in der Konfigurationsdatei den Schalter auf E-Mail legen,"
		echo "wenn du auf die Prozedur keine Lust hast."
		echo ""
		echo "Hierfür aber bitte die Konfigurationsdatei löschen und neu beginnen."
		echo "Diese findest du hier: $data/config.txt."
		echo ""
		echo "Script wird einstweilen beendet."
		sleep 3
		exit
	fi
fi
# TELEGRAM ENDE
if [ -f "$data/install.txt" ]; then
	prozess=$(cat "$data/install.txt" | head -n1 | tail -n1)
fi
if [ "$prozess" = "A03" ]; then
	clear
	echo "Der erste Part ist geschafft."
	echo "Nun werden Informationen zu den IP-Adressen benötigt."
	echo "Dies ist nur eine kleine Starthilfe, Du kannst später in der Config bis zu 25 Adressen festlegen."
	echo "Dasselbe, wenn Du dich vertippst o. ä., sieh dann einfach in die Config."
	echo ""
	echo "HINWEIS: Du kannst die IP-Adressen-Sammlung jederzeit beenden,"
	echo "indem Du ohne Eingabe des Namens enterst (ENTER)."
	echo ""
	echo "DRINGENDE INFO: Bitte breche das Script nicht vorzeitig ab mit STRG+C!"
	echo "Es werden erst Daten durch die Eingabe gesammelt,"
	echo "und dann erst in die Konfigurationsdatei geschrieben. Sonst besteht möglicherweise Datenverlust!"
	echo "Solltest du hier einen Fehler verursachen, wirkt sich das auf das ganze Script aus."
	echo "Demnach musst du die Config-Datei löschen und von vorne beginnen!"
	sleep 5
	echo ""
	read -p "Gib zuerst den Namen des erstens Geräts (1/25) ein: " IP01_name
	if [ -z "$IP01_name" ]; then
# 01-25 Gerätedefinition: Namen und IP Bestimmung
		echo ""
		echo "Assistent wird beendet."
		echo "IP01 = " >> "$data/config.txt"
		echo "IP02 = " >> "$data/config.txt"
		echo "IP03 = " >> "$data/config.txt"
		echo "IP04 = " >> "$data/config.txt"
		echo "IP05 = " >> "$data/config.txt"
		echo "IP06 = " >> "$data/config.txt"
		echo "IP07 = " >> "$data/config.txt"
		echo "IP08 = " >> "$data/config.txt"
		echo "IP09 = " >> "$data/config.txt"
		echo "IP10 = " >> "$data/config.txt"
		echo "IP11 = " >> "$data/config.txt"
		echo "IP12 = " >> "$data/config.txt"
		echo "IP13 = " >> "$data/config.txt"
		echo "IP14 = " >> "$data/config.txt"
		echo "IP15 = " >> "$data/config.txt"
		echo "IP16 = " >> "$data/config.txt"
		echo "IP17 = " >> "$data/config.txt"
		echo "IP18 = " >> "$data/config.txt"
		echo "IP19 = " >> "$data/config.txt"
		echo "IP20 = " >> "$data/config.txt"
		echo "IP21 = " >> "$data/config.txt"
		echo "IP22 = " >> "$data/config.txt"
		echo "IP23 = " >> "$data/config.txt"
		echo "IP24 = " >> "$data/config.txt"
		echo "IP25 = " >> "$data/config.txt"
		echo "Okay, Du kannst später jederzeit über die Konfigurationsdatei Änderungen vornehmen."
		sleep 2
		echo "A04" > "$data/install.txt"
		$0
		exit
	fi
	read -p "IP-Adresse des Geräts: " IP01_ip
	echo "Okay, $IP01_name ($IP01_ip) fertig."
	echo "IP01 = $IP01_ip $IP01_name" >> "$data/config.txt"
	sleep 2
	echo ""
# Gerätedefinierung
	read -p "Nächstes Gerät (2/25) - Name: " IP02_name
	if [ -z "$IP02_name" ]; then
		echo ""
		echo "Assistent wird beendet."
		echo "IP02 = " >> "$data/config.txt"
		echo "IP03 = " >> "$data/config.txt"
		echo "IP04 = " >> "$data/config.txt"
		echo "IP05 = " >> "$data/config.txt"
		echo "IP06 = " >> "$data/config.txt"
		echo "IP07 = " >> "$data/config.txt"
		echo "IP08 = " >> "$data/config.txt"
		echo "IP09 = " >> "$data/config.txt"
		echo "IP10 = " >> "$data/config.txt"
		echo "IP11 = " >> "$data/config.txt"
		echo "IP12 = " >> "$data/config.txt"
		echo "IP13 = " >> "$data/config.txt"
		echo "IP14 = " >> "$data/config.txt"
		echo "IP15 = " >> "$data/config.txt"
		echo "IP16 = " >> "$data/config.txt"
		echo "IP17 = " >> "$data/config.txt"
		echo "IP18 = " >> "$data/config.txt"
		echo "IP19 = " >> "$data/config.txt"
		echo "IP20 = " >> "$data/config.txt"
		echo "IP21 = " >> "$data/config.txt"
		echo "IP22 = " >> "$data/config.txt"
		echo "IP23 = " >> "$data/config.txt"
		echo "IP24 = " >> "$data/config.txt"
		echo "IP25 = " >> "$data/config.txt"
		echo "Okay, Du kannst später jederzeit über die Konfigurationsdatei Änderungen vornehmen."
		sleep 2
		echo "A04" > "$data/install.txt"
		$0
		exit
	fi
	read -p "IP-Adresse: " IP02_ip
	echo "Okay, $IP02_name ($IP02_ip) fertig."
	echo "IP02 = $IP02_ip $IP02_name" >> "$data/config.txt"
	sleep 2
	echo ""
# Gerätedefinierung
	read -p "Nächstes Gerät (3/25) - Name: " IP03_name
	if [ -z "$IP03_name" ]; then
		echo ""
		echo "Assistent wird beendet."
		echo "IP03 = " >> "$data/config.txt"
		echo "IP04 = " >> "$data/config.txt"
		echo "IP05 = " >> "$data/config.txt"
		echo "IP06 = " >> "$data/config.txt"
		echo "IP07 = " >> "$data/config.txt"
		echo "IP08 = " >> "$data/config.txt"
		echo "IP09 = " >> "$data/config.txt"
		echo "IP10 = " >> "$data/config.txt"
		echo "IP11 = " >> "$data/config.txt"
		echo "IP12 = " >> "$data/config.txt"
		echo "IP13 = " >> "$data/config.txt"
		echo "IP14 = " >> "$data/config.txt"
		echo "IP15 = " >> "$data/config.txt"
		echo "IP16 = " >> "$data/config.txt"
		echo "IP17 = " >> "$data/config.txt"
		echo "IP18 = " >> "$data/config.txt"
		echo "IP19 = " >> "$data/config.txt"
		echo "IP20 = " >> "$data/config.txt"
		echo "IP21 = " >> "$data/config.txt"
		echo "IP22 = " >> "$data/config.txt"
		echo "IP23 = " >> "$data/config.txt"
		echo "IP24 = " >> "$data/config.txt"
		echo "IP25 = " >> "$data/config.txt"
		echo "Okay, Du kannst später jederzeit über die Konfigurationsdatei Änderungen vornehmen."
		sleep 2
		echo "A04" > "$data/install.txt"
		$0
		exit
	fi
	read -p "IP-Adresse: " IP03_ip
	echo "Okay, $IP03_name ($IP03_ip) fertig."
	echo "IP03 = $IP03_ip $IP03_name" >> "$data/config.txt"
	sleep 2
	echo ""
# Gerätedefinierung
	read -p "Nächstes Gerät (4/25) - Name: " IP04_name
	if [ -z "$IP04_name" ]; then
		echo ""
		echo "Assistent wird beendet."
		echo "IP04 = " >> "$data/config.txt"
		echo "IP05 = " >> "$data/config.txt"
		echo "IP06 = " >> "$data/config.txt"
		echo "IP07 = " >> "$data/config.txt"
		echo "IP08 = " >> "$data/config.txt"
		echo "IP09 = " >> "$data/config.txt"
		echo "IP10 = " >> "$data/config.txt"
		echo "IP11 = " >> "$data/config.txt"
		echo "IP12 = " >> "$data/config.txt"
		echo "IP13 = " >> "$data/config.txt"
		echo "IP14 = " >> "$data/config.txt"
		echo "IP15 = " >> "$data/config.txt"
		echo "IP16 = " >> "$data/config.txt"
		echo "IP17 = " >> "$data/config.txt"
		echo "IP18 = " >> "$data/config.txt"
		echo "IP19 = " >> "$data/config.txt"
		echo "IP20 = " >> "$data/config.txt"
		echo "IP21 = " >> "$data/config.txt"
		echo "IP22 = " >> "$data/config.txt"
		echo "IP23 = " >> "$data/config.txt"
		echo "IP24 = " >> "$data/config.txt"
		echo "IP25 = " >> "$data/config.txt"
		echo "Okay, Du kannst später jederzeit über die Konfigurationsdatei Änderungen vornehmen."
		sleep 2
		echo "A04" > "$data/install.txt"
		$0
		exit
	fi
	read -p "IP-Adresse: " IP04_ip
	echo "Okay, $IP04_name ($IP04_ip) fertig."
	echo "IP04 = $IP04_ip $IP04_name" >> "$data/config.txt"
	sleep 2
	echo ""
# Gerätedefinierung
	read -p "Nächstes Gerät (5/25) - Name: " IP05_name
	if [ -z "$IP05_name" ]; then
		echo ""
		echo "Assistent wird beendet."
		echo "IP05 = " >> "$data/config.txt"
		echo "IP06 = " >> "$data/config.txt"
		echo "IP07 = " >> "$data/config.txt"
		echo "IP08 = " >> "$data/config.txt"
		echo "IP09 = " >> "$data/config.txt"
		echo "IP10 = " >> "$data/config.txt"
		echo "IP11 = " >> "$data/config.txt"
		echo "IP12 = " >> "$data/config.txt"
		echo "IP13 = " >> "$data/config.txt"
		echo "IP14 = " >> "$data/config.txt"
		echo "IP15 = " >> "$data/config.txt"
		echo "IP16 = " >> "$data/config.txt"
		echo "IP17 = " >> "$data/config.txt"
		echo "IP18 = " >> "$data/config.txt"
		echo "IP19 = " >> "$data/config.txt"
		echo "IP20 = " >> "$data/config.txt"
		echo "IP21 = " >> "$data/config.txt"
		echo "IP22 = " >> "$data/config.txt"
		echo "IP23 = " >> "$data/config.txt"
		echo "IP24 = " >> "$data/config.txt"
		echo "IP25 = " >> "$data/config.txt"
		echo "Okay, Du kannst später jederzeit über die Konfigurationsdatei Änderungen vornehmen."
		sleep 2
		echo "A04" > "$data/install.txt"
		$0
		exit
	fi
	read -p "IP-Adresse: " IP05_ip
	echo "Okay, $IP05_name ($IP05_ip) fertig."
	echo "IP05 = $IP05_ip $IP05_name" >> "$data/config.txt"
	sleep 2
	echo ""
# Gerätedefinierung
	read -p "Nächstes Gerät (6/25) - Name: " IP06_name
	if [ -z "$IP06_name" ]; then
		echo ""
		echo "Assistent wird beendet."
		echo "IP06 = " >> "$data/config.txt"
		echo "IP07 = " >> "$data/config.txt"
		echo "IP08 = " >> "$data/config.txt"
		echo "IP09 = " >> "$data/config.txt"
		echo "IP10 = " >> "$data/config.txt"
		echo "IP11 = " >> "$data/config.txt"
		echo "IP12 = " >> "$data/config.txt"
		echo "IP13 = " >> "$data/config.txt"
		echo "IP14 = " >> "$data/config.txt"
		echo "IP15 = " >> "$data/config.txt"
		echo "IP16 = " >> "$data/config.txt"
		echo "IP17 = " >> "$data/config.txt"
		echo "IP18 = " >> "$data/config.txt"
		echo "IP19 = " >> "$data/config.txt"
		echo "IP20 = " >> "$data/config.txt"
		echo "IP21 = " >> "$data/config.txt"
		echo "IP22 = " >> "$data/config.txt"
		echo "IP23 = " >> "$data/config.txt"
		echo "IP24 = " >> "$data/config.txt"
		echo "IP25 = " >> "$data/config.txt"
		echo "Okay, Du kannst später jederzeit über die Konfigurationsdatei Änderungen vornehmen."
		sleep 2
		echo "A04" > "$data/install.txt"
		$0
		exit
	fi
	read -p "IP-Adresse: " IP06_ip
	echo "Okay, $IP06_name ($IP06_ip) fertig."
	echo "IP06 = $IP06_ip $IP06_name" >> "$data/config.txt"
	sleep 2
	echo ""
# Gerätedefinierung
	read -p "Nächstes Gerät (7/25) - Name: " IP07_name
	if [ -z "$IP07_name" ]; then
		echo ""
		echo "Assistent wird beendet."
		echo "IP07 = " >> "$data/config.txt"
		echo "IP08 = " >> "$data/config.txt"
		echo "IP09 = " >> "$data/config.txt"
		echo "IP10 = " >> "$data/config.txt"
		echo "IP11 = " >> "$data/config.txt"
		echo "IP12 = " >> "$data/config.txt"
		echo "IP13 = " >> "$data/config.txt"
		echo "IP14 = " >> "$data/config.txt"
		echo "IP15 = " >> "$data/config.txt"
		echo "IP16 = " >> "$data/config.txt"
		echo "IP17 = " >> "$data/config.txt"
		echo "IP18 = " >> "$data/config.txt"
		echo "IP19 = " >> "$data/config.txt"
		echo "IP20 = " >> "$data/config.txt"
		echo "IP21 = " >> "$data/config.txt"
		echo "IP22 = " >> "$data/config.txt"
		echo "IP23 = " >> "$data/config.txt"
		echo "IP24 = " >> "$data/config.txt"
		echo "IP25 = " >> "$data/config.txt"
		echo "Okay, Du kannst später jederzeit über die Konfigurationsdatei Änderungen vornehmen."
		sleep 2
		echo "A04" > "$data/install.txt"
		$0
		exit
	fi
	read -p "IP-Adresse: " IP07_ip
	echo "Okay, $IP07_name ($IP07_ip) fertig."
	echo "IP07 = $IP07_ip $IP07_name" >> "$data/config.txt"
	sleep 2
	echo ""
# Gerätedefinierung
	read -p "Nächstes Gerät (8/25) - Name: " IP08_name
	if [ -z "$IP08_name" ]; then
		echo ""
		echo "Assistent wird beendet."
		echo "IP08 = " >> "$data/config.txt"
		echo "IP09 = " >> "$data/config.txt"
		echo "IP10 = " >> "$data/config.txt"
		echo "IP11 = " >> "$data/config.txt"
		echo "IP12 = " >> "$data/config.txt"
		echo "IP13 = " >> "$data/config.txt"
		echo "IP14 = " >> "$data/config.txt"
		echo "IP15 = " >> "$data/config.txt"
		echo "IP16 = " >> "$data/config.txt"
		echo "IP17 = " >> "$data/config.txt"
		echo "IP18 = " >> "$data/config.txt"
		echo "IP19 = " >> "$data/config.txt"
		echo "IP20 = " >> "$data/config.txt"
		echo "IP21 = " >> "$data/config.txt"
		echo "IP22 = " >> "$data/config.txt"
		echo "IP23 = " >> "$data/config.txt"
		echo "IP24 = " >> "$data/config.txt"
		echo "IP25 = " >> "$data/config.txt"
		echo "Okay, Du kannst später jederzeit über die Konfigurationsdatei Änderungen vornehmen."
		sleep 2
		echo "A04" > "$data/install.txt"
		$0
		exit
	fi
	read -p "IP-Adresse: " IP08_ip
	echo "Okay, $IP08_name ($IP08_ip) fertig."
	echo "IP08 = $IP08_ip $IP08_name" >> "$data/config.txt"
	sleep 2
	echo ""
# Gerätedefinierung
	read -p "Nächstes Gerät (9/25) - Name: " IP09_name
	if [ -z "$IP09_name" ]; then
		echo ""
		echo "Assistent wird beendet."
		echo "IP09 = " >> "$data/config.txt"
		echo "IP10 = " >> "$data/config.txt"
		echo "IP11 = " >> "$data/config.txt"
		echo "IP12 = " >> "$data/config.txt"
		echo "IP13 = " >> "$data/config.txt"
		echo "IP14 = " >> "$data/config.txt"
		echo "IP15 = " >> "$data/config.txt"
		echo "IP16 = " >> "$data/config.txt"
		echo "IP17 = " >> "$data/config.txt"
		echo "IP18 = " >> "$data/config.txt"
		echo "IP19 = " >> "$data/config.txt"
		echo "IP20 = " >> "$data/config.txt"
		echo "IP21 = " >> "$data/config.txt"
		echo "IP22 = " >> "$data/config.txt"
		echo "IP23 = " >> "$data/config.txt"
		echo "IP24 = " >> "$data/config.txt"
		echo "IP25 = " >> "$data/config.txt"
		echo "Okay, Du kannst später jederzeit über die Konfigurationsdatei Änderungen vornehmen."
		sleep 2
		echo "A04" > "$data/install.txt"
		$0
		exit
	fi
	read -p "IP-Adresse: " IP09_ip
	echo "Okay, $IP09_name ($IP09_ip) fertig."
	echo "IP09 = $IP09_ip $IP09_name" >> "$data/config.txt"
	sleep 2
	echo ""
# Gerätedefinierung
	read -p "Nächstes Gerät (10/25) - Name: " IP10_name
	if [ -z "$IP10_name" ]; then
		echo ""
		echo "Assistent wird beendet."
		echo "IP10 = " >> "$data/config.txt"
		echo "IP11 = " >> "$data/config.txt"
		echo "IP12 = " >> "$data/config.txt"
		echo "IP13 = " >> "$data/config.txt"
		echo "IP14 = " >> "$data/config.txt"
		echo "IP15 = " >> "$data/config.txt"
		echo "IP16 = " >> "$data/config.txt"
		echo "IP17 = " >> "$data/config.txt"
		echo "IP18 = " >> "$data/config.txt"
		echo "IP19 = " >> "$data/config.txt"
		echo "IP20 = " >> "$data/config.txt"
		echo "IP21 = " >> "$data/config.txt"
		echo "IP22 = " >> "$data/config.txt"
		echo "IP23 = " >> "$data/config.txt"
		echo "IP24 = " >> "$data/config.txt"
		echo "IP25 = " >> "$data/config.txt"
		echo "Okay, Du kannst später jederzeit über die Konfigurationsdatei Änderungen vornehmen."
		sleep 2
		echo "A04" > "$data/install.txt"
		$0
		exit
	fi
	read -p "IP-Adresse: " IP10_ip
	echo "Okay, $IP10_name ($IP10_ip) fertig."
	echo "IP10 = $IP10_ip $IP10_name" >> "$data/config.txt"
	sleep 2
	echo ""
# Gerätedefinierung
	read -p "Nächstes Gerät (11/25) - Name: " IP11_name
	if [ -z "$IP11_name" ]; then
		echo ""
		echo "Assistent wird beendet."
		echo "IP11 = " >> "$data/config.txt"
		echo "IP12 = " >> "$data/config.txt"
		echo "IP13 = " >> "$data/config.txt"
		echo "IP14 = " >> "$data/config.txt"
		echo "IP15 = " >> "$data/config.txt"
		echo "IP16 = " >> "$data/config.txt"
		echo "IP17 = " >> "$data/config.txt"
		echo "IP18 = " >> "$data/config.txt"
		echo "IP19 = " >> "$data/config.txt"
		echo "IP20 = " >> "$data/config.txt"
		echo "IP21 = " >> "$data/config.txt"
		echo "IP22 = " >> "$data/config.txt"
		echo "IP23 = " >> "$data/config.txt"
		echo "IP24 = " >> "$data/config.txt"
		echo "IP25 = " >> "$data/config.txt"
		echo "Okay, Du kannst später jederzeit über die Konfigurationsdatei Änderungen vornehmen."
		sleep 2
		echo "A04" > "$data/install.txt"
		$0
		exit
	fi
	read -p "IP-Adresse: " IP11_ip
	echo "Okay, $IP11_name ($IP11_ip) fertig."
	echo "IP11 = $IP11_ip $IP11_name" >> "$data/config.txt"
	sleep 2
	echo ""
# Gerätedefinierung
	read -p "Nächstes Gerät (12/25) - Name: " IP12_name
	if [ -z "$IP12_name" ]; then
		echo ""
		echo "Assistent wird beendet."
		echo "IP12 = " >> "$data/config.txt"
		echo "IP13 = " >> "$data/config.txt"
		echo "IP14 = " >> "$data/config.txt"
		echo "IP15 = " >> "$data/config.txt"
		echo "IP16 = " >> "$data/config.txt"
		echo "IP17 = " >> "$data/config.txt"
		echo "IP18 = " >> "$data/config.txt"
		echo "IP19 = " >> "$data/config.txt"
		echo "IP20 = " >> "$data/config.txt"
		echo "IP21 = " >> "$data/config.txt"
		echo "IP22 = " >> "$data/config.txt"
		echo "IP23 = " >> "$data/config.txt"
		echo "IP24 = " >> "$data/config.txt"
		echo "IP25 = " >> "$data/config.txt"
		echo "Okay, Du kannst später jederzeit über die Konfigurationsdatei Änderungen vornehmen."
		sleep 2
		echo "A04" > "$data/install.txt"
		$0
		exit
	fi
	read -p "IP-Adresse: " IP12_ip
	echo "Okay, $IP12_name ($IP12_ip) fertig."
	echo "IP12 = $IP12_ip $IP12_name" >> "$data/config.txt"
	sleep 2
	echo ""
# Gerätedefinierung
	read -p "Nächstes Gerät (13/25) - Name: " IP13_name
	if [ -z "$IP13_name" ]; then
		echo ""
		echo "Assistent wird beendet."
		echo "IP13 = " >> "$data/config.txt"
		echo "IP14 = " >> "$data/config.txt"
		echo "IP15 = " >> "$data/config.txt"
		echo "IP16 = " >> "$data/config.txt"
		echo "IP17 = " >> "$data/config.txt"
		echo "IP18 = " >> "$data/config.txt"
		echo "IP19 = " >> "$data/config.txt"
		echo "IP20 = " >> "$data/config.txt"
		echo "IP21 = " >> "$data/config.txt"
		echo "IP22 = " >> "$data/config.txt"
		echo "IP23 = " >> "$data/config.txt"
		echo "IP24 = " >> "$data/config.txt"
		echo "IP25 = " >> "$data/config.txt"
		echo "Okay, Du kannst später jederzeit über die Konfigurationsdatei Änderungen vornehmen."
		sleep 2
		echo "A04" > "$data/install.txt"
		$0
		exit
	fi
	read -p "IP-Adresse: " IP13_ip
	echo "Okay, $IP13_name ($IP13_ip) fertig."
	echo "IP13 = $IP13_ip $IP13_name" >> "$data/config.txt"
	sleep 2
	echo ""
# Gerätedefinierung
	read -p "Nächstes Gerät (14/25) - Name: " IP14_name
	if [ -z "$IP14_name" ]; then
		echo ""
		echo "Assistent wird beendet."
		echo "IP14 = " >> "$data/config.txt"
		echo "IP15 = " >> "$data/config.txt"
		echo "IP16 = " >> "$data/config.txt"
		echo "IP17 = " >> "$data/config.txt"
		echo "IP18 = " >> "$data/config.txt"
		echo "IP19 = " >> "$data/config.txt"
		echo "IP20 = " >> "$data/config.txt"
		echo "IP21 = " >> "$data/config.txt"
		echo "IP22 = " >> "$data/config.txt"
		echo "IP23 = " >> "$data/config.txt"
		echo "IP24 = " >> "$data/config.txt"
		echo "IP25 = " >> "$data/config.txt"
		echo "Okay, Du kannst später jederzeit über die Konfigurationsdatei Änderungen vornehmen."
		sleep 2
		echo "A04" > "$data/install.txt"
		$0
		exit
	fi
	read -p "IP-Adresse: " IP14_ip
	echo "Okay, $IP14_name ($IP14_ip) fertig."
	echo "IP14 = $IP14_ip $IP14_name" >> "$data/config.txt"
	sleep 2
	echo ""
# Gerätedefinierung
	read -p "Nächstes Gerät (15/25) - Name: " IP15_name
	if [ -z "$IP15_name" ]; then
		echo ""
		echo "Assistent wird beendet."
		echo "IP15 = " >> "$data/config.txt"
		echo "IP16 = " >> "$data/config.txt"
		echo "IP17 = " >> "$data/config.txt"
		echo "IP18 = " >> "$data/config.txt"
		echo "IP19 = " >> "$data/config.txt"
		echo "IP20 = " >> "$data/config.txt"
		echo "IP21 = " >> "$data/config.txt"
		echo "IP22 = " >> "$data/config.txt"
		echo "IP23 = " >> "$data/config.txt"
		echo "IP24 = " >> "$data/config.txt"
		echo "IP25 = " >> "$data/config.txt"
		echo "Okay, Du kannst später jederzeit über die Konfigurationsdatei Änderungen vornehmen."
		sleep 2
		echo "A04" > "$data/install.txt"
		$0
		exit
	fi
	read -p "IP-Adresse: " IP15_ip
	echo "Okay, $IP15_name ($IP15_ip) fertig."
	echo "IP15 = $IP15_ip $IP15_name" >> "$data/config.txt"
	sleep 2
	echo ""
# Gerätedefinierung
	read -p "Nächstes Gerät (16/25) - Name: " IP16_name
	if [ -z "$IP16_name" ]; then
		echo ""
		echo "Assistent wird beendet."
		echo "IP16 = " >> "$data/config.txt"
		echo "IP17 = " >> "$data/config.txt"
		echo "IP18 = " >> "$data/config.txt"
		echo "IP19 = " >> "$data/config.txt"
		echo "IP20 = " >> "$data/config.txt"
		echo "IP21 = " >> "$data/config.txt"
		echo "IP22 = " >> "$data/config.txt"
		echo "IP23 = " >> "$data/config.txt"
		echo "IP24 = " >> "$data/config.txt"
		echo "IP25 = " >> "$data/config.txt"
		echo "Okay, Du kannst später jederzeit über die Konfigurationsdatei Änderungen vornehmen."
		sleep 2
		echo "A04" > "$data/install.txt"
		$0
		exit
	fi
	read -p "IP-Adresse: " IP16_ip
	echo "Okay, $IP16_name ($IP16_ip) fertig."
	echo "IP16 = $IP16_ip $IP16_name" >> "$data/config.txt"
	sleep 2
	echo ""
# Gerätedefinierung
	read -p "Nächstes Gerät (17/25) - Name: " IP17_name
	if [ -z "$IP17_name" ]; then
		echo ""
		echo "Assistent wird beendet."
		echo "IP17 = " >> "$data/config.txt"
		echo "IP18 = " >> "$data/config.txt"
		echo "IP19 = " >> "$data/config.txt"
		echo "IP20 = " >> "$data/config.txt"
		echo "IP21 = " >> "$data/config.txt"
		echo "IP22 = " >> "$data/config.txt"
		echo "IP23 = " >> "$data/config.txt"
		echo "IP24 = " >> "$data/config.txt"
		echo "IP25 = " >> "$data/config.txt"
		echo "Okay, Du kannst später jederzeit über die Konfigurationsdatei Änderungen vornehmen."
		sleep 2
		echo "A04" > "$data/install.txt"
		$0
		exit
	fi
	read -p "IP-Adresse: " IP17_ip
	echo "Okay, $IP17_name ($IP17_ip) fertig."
	echo "IP17 = $IP17_ip $IP17_name" >> "$data/config.txt"
	sleep 2
	echo ""
# Gerätedefinierung
	read -p "Nächstes Gerät (18/25) - Name: " IP18_name
	if [ -z "$IP18_name" ]; then
		echo ""
		echo "Assistent wird beendet."
		echo "IP18 = " >> "$data/config.txt"
		echo "IP19 = " >> "$data/config.txt"
		echo "IP20 = " >> "$data/config.txt"
		echo "IP21 = " >> "$data/config.txt"
		echo "IP22 = " >> "$data/config.txt"
		echo "IP23 = " >> "$data/config.txt"
		echo "IP24 = " >> "$data/config.txt"
		echo "IP25 = " >> "$data/config.txt"
		echo "Okay, Du kannst später jederzeit über die Konfigurationsdatei Änderungen vornehmen."
		sleep 2
		echo "A04" > "$data/install.txt"
		$0
		exit
	fi
	read -p "IP-Adresse: " IP18_ip
	echo "Okay, $IP18_name ($IP18_ip) fertig."
	echo "IP18 = $IP18_ip $IP18_name" >> "$data/config.txt"
	sleep 2
	echo ""
# Gerätedefinierung
	read -p "Nächstes Gerät (19/25) - Name: " IP19_name
	if [ -z "$IP19_name" ]; then
		echo ""
		echo "Assistent wird beendet."
		echo "IP19 = " >> "$data/config.txt"
		echo "IP20 = " >> "$data/config.txt"
		echo "IP21 = " >> "$data/config.txt"
		echo "IP22 = " >> "$data/config.txt"
		echo "IP23 = " >> "$data/config.txt"
		echo "IP24 = " >> "$data/config.txt"
		echo "IP25 = " >> "$data/config.txt"
		echo "Okay, Du kannst später jederzeit über die Konfigurationsdatei Änderungen vornehmen."
		sleep 2
		echo "A04" > "$data/install.txt"
		$0
		exit
	fi
	read -p "IP-Adresse: " IP19_ip
	echo "Okay, $IP19_name ($IP19_ip) fertig."
	echo "IP19 = $IP19_ip $IP19_name" >> "$data/config.txt"
	sleep 2
	echo ""
# Gerätedefinierung
	read -p "Nächstes Gerät (20/25) - Name: " IP20_name
	if [ -z "$IP20_name" ]; then
		echo ""
		echo "Assistent wird beendet."
		echo "IP20 = " >> "$data/config.txt"
		echo "IP21 = " >> "$data/config.txt"
		echo "IP22 = " >> "$data/config.txt"
		echo "IP23 = " >> "$data/config.txt"
		echo "IP24 = " >> "$data/config.txt"
		echo "IP25 = " >> "$data/config.txt"
		echo "Okay, Du kannst später jederzeit über die Konfigurationsdatei Änderungen vornehmen."
		sleep 2
		echo "A04" > "$data/install.txt"
		$0
		exit
	fi
	read -p "IP-Adresse: " IP20_ip
	echo "Okay, $IP20_name ($IP20_ip) fertig."
	echo "IP20 = $IP20_ip $IP20_name" >> "$data/config.txt"
	sleep 2
	echo ""
# Gerätedefinierung
	read -p "Nächstes Gerät (21/25) - Name: " IP21_name
	if [ -z "$IP21_name" ]; then
		echo ""
		echo "Assistent wird beendet."
		echo "IP21 = " >> "$data/config.txt"
		echo "IP22 = " >> "$data/config.txt"
		echo "IP23 = " >> "$data/config.txt"
		echo "IP24 = " >> "$data/config.txt"
		echo "IP25 = " >> "$data/config.txt"
		echo "Okay, Du kannst später jederzeit über die Konfigurationsdatei Änderungen vornehmen."
		sleep 2
		echo "A04" > "$data/install.txt"
		$0
		exit
	fi
	read -p "IP-Adresse: " IP21_ip
	echo "Okay, $IP21_name ($IP21_ip) fertig."
	echo "IP21 = $IP21_ip $IP21_name" >> "$data/config.txt"
	sleep 2
	echo ""
# Gerätedefinierung
	read -p "Nächstes Gerät (22/25) - Name: " IP22_name
	if [ -z "$IP22_name" ]; then
		echo ""
		echo "Assistent wird beendet."
		echo "IP22 = " >> "$data/config.txt"
		echo "IP23 = " >> "$data/config.txt"
		echo "IP24 = " >> "$data/config.txt"
		echo "IP25 = " >> "$data/config.txt"
		echo "Okay, Du kannst später jederzeit über die Konfigurationsdatei Änderungen vornehmen."
		sleep 2
		echo "A04" > "$data/install.txt"
		$0
		exit
	fi
	read -p "IP-Adresse: " IP22_ip
	echo "Okay, $IP22_name ($IP22_ip) fertig."
	echo "IP22 = $IP22_ip $IP22_name" >> "$data/config.txt"
	sleep 2
	echo ""
# Gerätedefinierung
	read -p "Nächstes Gerät (23/25) - Name: " IP23_name
	if [ -z "$IP23_name" ]; then
		echo ""
		echo "Assistent wird beendet."
		echo "IP23 = " >> "$data/config.txt"
		echo "IP24 = " >> "$data/config.txt"
		echo "IP25 = " >> "$data/config.txt"
		echo "Okay, Du kannst später jederzeit über die Konfigurationsdatei Änderungen vornehmen."
		sleep 2
		echo "A04" > "$data/install.txt"
		$0
		exit
	fi
	read -p "IP-Adresse: " IP23_ip
	echo "Okay, $IP23_name ($IP23_ip) fertig."
	echo "IP23 = $IP23_ip $IP23_name" >> "$data/config.txt"
	sleep 2
	echo ""
# Gerätedefinierung
	read -p "Nächstes Gerät (24/25) - Name: " IP24_name
	if [ -z "$IP24_name" ]; then
		echo ""
		echo "Assistent wird beendet."
		echo "IP24 = " >> "$data/config.txt"
		echo "IP25 = " >> "$data/config.txt"
		echo "Okay, Du kannst später jederzeit über die Konfigurationsdatei Änderungen vornehmen."
		sleep 2
		echo "A04" > "$data/install.txt"
		$0
		exit
	fi
	read -p "IP-Adresse: " IP24_ip
	echo "Okay, $IP24_name ($IP24_ip) fertig."
	echo "IP24 = $IP24_ip $IP24_name" >> "$data/config.txt"
	sleep 2
	echo ""
# Gerätedefinierung
	read -p "Letztes Gerät (25/25) - Name: " IP25_name
	if [ -z "$IP25_name" ]; then
		echo ""
		echo "Assistent wird beendet."
		echo "IP25 = " >> "$data/config.txt"
		echo "Okay, Du kannst später jederzeit über die Konfigurationsdatei Änderungen vornehmen."
		sleep 2
		echo "A04" > "$data/install.txt"
		$0
		exit
	fi
	read -p "IP-Adresse: " IP25_ip
	echo "Okay, $IP25_name ($IP25_ip) fertig."
	echo "IP25 = $IP25_ip $IP25_name" >> "$data/config.txt"
	echo ""
	echo "Fertig, alle IP-Adressen belegt, Assistent wird beendet."
	sleep 2
	echo "A04" > "$data/install.txt"
# Gerätedefinierung
fi
if [ -f "$data/install.txt" ]; then
	prozess=$(cat "$data/install.txt" | head -n1 | tail -n1)
fi
if [ "$prozess" = "A04" ]; then
	clear
	echo "Nun wird der Stundenplan eingerichtet."
	echo "Dieser bestimmt, wann Du benachrichtigt wirst, damit nachts ggf. Ruhe ist."
	echo ""
	echo "Es wird eine Crontab-Datei erzeugt, die das Script automatisch jede Minute in einem vordefiniertem Zeitraum aufruft."
	echo "Dieser Stundenplan wird in der Konfigurationsdatei gespeichert und jedes Mal exportiert,"
	echo "damit Änderungen berücksichtigt werden können."
	echo ""
	echo "Wann willst du benachrichtigt werden?"
	echo "Wähle die Wochentage wie folgt:"
	echo "MO, DI, MI, DO, FR, SA, SO, MO-FR, SA-SO, MO, MI ... - für täglich wähle MO-SO oder einfach 'täglich'."
	echo "HINWEIS: Bitte beachte, dass du nur MO-FR und SA-SO, sowie täglich mit MO-SO schreiben kannst."
	echo "Für bestimmte Tage wähle mit Kommata."
	echo ""
	read -p "Deine Eingabe: " tage_eingabe
	echo "$tage_eingabe" | sed "s/\(.\)/\L\1/g ; s:mo:1:g ; s:di:2:g ; s:mi:3:g ; s:do:4:g ; s:fr:5:g ; s:sa:6:g ; s:so:0:g ; s: ::g ; s:1-0:*:g ; s:6-0:6,0:g; s:täglich:*:g" >> "$data/temp-crontab.txt"
	echo ""
	echo "Okay."
	sleep 2
	echo "A04a" > "$data/install.txt"
fi

if [ -f "$data/install.txt" ]; then
	prozess=$(cat "$data/install.txt" | head -n1 | tail -n1)
fi

if [ "$prozess" = "A04a" ]; then
	clear
	echo "Bitte gib die Stunde an, an der Du benachrichtigt werden willst, als Beispiel 6-22."
	echo "HINWEIS: Willst du Zeiten wie 20-02 Uhr oder andere tagesübergreifende Zeiten eingeben,"
	echo "kannst du dies auch mit Kommata machen, Beispiel 20, 21, 22, 23, 00, 01 (effektiv 20:00-01:59)."
	echo "D. h., dass die eingegebene Stunde immer die Stunde der Benachrichtigung ist."
	echo "Beispiel: 21, 22, 23 besagt, dass von 21:00 bis 23:59 benachrichtigt wird."
	echo "INFO: Willst du rund um die Uhr Benachrichtigungen erhalten, so gib nur einmal '24' ein."
	echo ""
	read -p "Deine Zeit: " zeit_eingabe

	if [ ! "$zeit_eingabe" = "24" ]; then
		if [ $(echo $zeit_eingabe | grep "[-]") ]; then
			zeit_sed=$(echo "$zeit_eingabe" | sed "s:-: :g")
			zeit_sed_h1=$(echo "$zeit_sed" | cut -d ' ' -f 1)
			zeit_sed_h2=$(echo "$zeit_sed" | cut -d ' ' -f 2)
			zeit_sed_h3=$(echo $(($zeit_sed_h2 - 1)))
			if [ "$zeit_sed_h1" -gt "$zeit_sed_h2" ]; then
			echo ""
			echo "Fehler. Bitte gib die Zeit richtig an."
			sleep 2
			$0
			exit
			fi
			echo ""
			echo "Okay, Benachrichtigung in der Zeit von $zeit_sed_h1 bis $zeit_sed_h2 Uhr."
			sleep 3
			echo "$zeit_sed_h1-$zeit_sed_h3" >> "$data/temp-crontab.txt"
		else
			zeit_sed=$(echo "$zeit_eingabe" | sed "s: ::g")
			echo "$zeit_sed" >> "$data/temp-crontab.txt"
		fi
	else
		echo ""
		echo "Okay, Du wirst rund um die Uhr benachrichtigt."
		sleep 3
		echo "*" >> "$data/temp-crontab.txt"
	fi

	tage=$(cat "$data/temp-crontab.txt" | head -n1 | tail -n1)
	stunden=$(cat "$data/temp-crontab.txt" | head -n2 | tail -n1)
	echo "An folgenden Tagen: $tage_eingabe und Stunden: $zeit_eingabe"

	echo "" >> "$data/config.txt"
	echo "[Zeitplan]" >> "$data/config.txt"

	if [ "$tage" = "*" ] && [ "$stunden" = "*" ]; then
		echo ""
		echo "Du wirst täglich rund um die Uhr benachrichtigt, willst Du das Script"
		echo "nicht nur minütlich prüfen lassen, sondern permanent?"
		echo "Hierbei wird der Crontab-Job außer Kraft gesetzt. Der Schalter in der Config"
		echo "wird dabei auf '2' gesetzt."
		echo "HINWEIS: Diese Maßnahme wird allerdings nicht empfohlen, da sie Ressourcen u. U. belegt."
		echo ""
		echo "Du kannst in der Config eine leichte Verzögerung bei dem permenenten Aufruf einbauen."
		echo "Standard sind hierbei 5 Sekunden. Diese findest Du in der Config unter 'verzögerung'."
		echo ""
		read -p "Wähle ja ( 1 ) oder nein ( 0 ): " perma

		if [ "$perma" = "1" ]; then
			echo ""
			echo "Okay, permanenter Modus."
			echo "aktiv = 2 # Schalter: 0=nur manuell, 1=automatisch (Crontab), 2=permanent" >> "$data/config.txt"
		elif [ "$perma" = "0" ]; then
			echo ""
			echo "Okay, normaler Zeitplan-Modus."
			echo "aktiv = 1 # Schalter: 0=nur manuell, 1=automatisch (Crontab), 2=permanent" >> "$data/config.txt"
		else
			echo ""
			echo "Fehler: keine Auswahl getroffen. Es wird kein Wert gesetzt,"
			echo "Du musst diese Option allerdings das später in der Config ändern."
			echo "aktiv = 0 # Schalter: 0=nur manuell, 1=automatisch (Crontab), 2=permanent" >> "$data/config.txt"
		fi
	fi

	clear
	echo "Sollte ein Gerät ausfallen und die Meldung registriert werden, wie lange soll eine erneute"
	echo "Meldung zurückgehalten werden?"
	echo ""
	read -p "x Tage lang: " tage
	echo ""
	echo "Okay, $tage Tage lang wird eine erneute Meldung zurückgehalten."
	echo "Sollte das Gerät oder die IP-Adresse geändert worden sein, wird einfach nur der Eintrag zurückgesetzt."
	echo "Sollte das Gerät aber Daueroffline sein, erscheint eine erneute Meldung."
	echo "Bitte die Geräteliste in der Config stets aktuell halten."
	echo "tage = $tage # x Tage wird eine erneute Meldung bei Daueroffline zurückgehalten" >> "$data/config.txt"

	clear
	echo "Bleibt das Script da gespeichert, wo es jetzt ist? Falls nicht, bitte ändere diesen Pfad"
	echo "in der Konfigurationsdatei unter Zeitplan."
	echo "INFO: Du kannst in der Konfigurationsdatei den Benachrichtigungs-Schalter auf 0 setzen."
	echo "Damit setzt Du den Zeitplan außer Kraft."
	echo "Du findest den Schalter unter 'Zeitplan' und 'aktiv'. Setze ggf. von 1 auf 0 und umgekehrt."
	echo ""
	echo "crontab = * $stunden * * $tage $(readlink -e "$0") >> $data/crontab-log.txt # siehe bei https://crontab.guru für Schreibweise." >> "$data/config.txt"
	echo "verzögerung = 5 # nur permanent-Modus: Pause zwischen Script-Ausführungen in Sekunden" >> "$data/config.txt"
	sleep 4
	echo ""
	read -p "Weiter mit Enter..." null
	echo ""
	echo "Okay. Zeit-Sektor abgeschlossen."
	sleep 3
	echo "A05" > "$data/install.txt"
fi

if [ -f "$data/install.txt" ]; then
	prozess=$(cat "$data/install.txt" | head -n1 | tail -n1)
fi

if [ "$prozess" = "A05" ]; then
	clear
	echo "Räume auf..."
	rm "$data/temp-crontab.txt"
	rm "$data/install.txt"
	echo "Fertig."
	sleep 2
	echo ""
	echo "Ab sofort, wenn Du das Script aufrufst, werden gleich die Geräte getestet."
	echo "Wenn Du Änderungen vornehmen willst, siehe in die Konfigurationsdatei."
	echo "Diese findest du unter $data/config.txt."
	echo ""
	read -p "Weiter mit Enter..." null
	echo ""
	echo "Viel Spaß!"
	sleep 3
fi

clear
echo "Lese Daten ein..."
echo "Scriptversion: $scriptversion"
ipping=$(grep -w IPping "$data/config.txt" | cut -d ' ' -f 3)
ping_main_w=$(grep -w ping_main "$data/config.txt" | cut -d ' ' -f 3)
ping_main_c=$(grep -w ping_main "$data/config.txt" | cut -d ' ' -f 4)
ping_dev_w=$(grep -w ping_dev "$data/config.txt" | cut -d ' ' -f 3)
ping_dev_c=$(grep -w ping_dev "$data/config.txt" | cut -d ' ' -f 4)
benachrichtigung=$(grep -w benachrichtigung "$data/config.txt" | cut -d ' ' -f 3)
telegram_bottoken=$(grep -w bottoken "$data/config.txt" | cut -d ' ' -f 3)
telegram_master=$(grep -w master_chat_id "$data/config.txt" | cut -d ' ' -f 3)
email_master=$(grep -w email_master "$data/config.txt" | cut -d ' ' -f 3)
IP01_name=$(grep -w IP01 "$data/config.txt" | cut -d ' ' -f 4-)
IP01_ip=$(grep -w IP01 "$data/config.txt" | cut -d ' ' -f 3)
IP02_name=$(grep -w IP02 "$data/config.txt" | cut -d ' ' -f 4-)
IP02_ip=$(grep -w IP02 "$data/config.txt" | cut -d ' ' -f 3)
IP03_name=$(grep -w IP03 "$data/config.txt" | cut -d ' ' -f 4-)
IP03_ip=$(grep -w IP03 "$data/config.txt" | cut -d ' ' -f 3)
IP04_name=$(grep -w IP04 "$data/config.txt" | cut -d ' ' -f 4-)
IP04_ip=$(grep -w IP04 "$data/config.txt" | cut -d ' ' -f 3)
IP05_name=$(grep -w IP05 "$data/config.txt" | cut -d ' ' -f 4-)
IP05_ip=$(grep -w IP05 "$data/config.txt" | cut -d ' ' -f 3)
IP06_name=$(grep -w IP06 "$data/config.txt" | cut -d ' ' -f 4-)
IP06_ip=$(grep -w IP06 "$data/config.txt" | cut -d ' ' -f 3)
IP07_name=$(grep -w IP07 "$data/config.txt" | cut -d ' ' -f 4-)
IP07_ip=$(grep -w IP07 "$data/config.txt" | cut -d ' ' -f 3)
IP08_name=$(grep -w IP08 "$data/config.txt" | cut -d ' ' -f 4-)
IP08_ip=$(grep -w IP08 "$data/config.txt" | cut -d ' ' -f 3)
IP09_name=$(grep -w IP09 "$data/config.txt" | cut -d ' ' -f 4-)
IP09_ip=$(grep -w IP09 "$data/config.txt" | cut -d ' ' -f 3)
IP10_name=$(grep -w IP10 "$data/config.txt" | cut -d ' ' -f 4-)
IP10_ip=$(grep -w IP10 "$data/config.txt" | cut -d ' ' -f 3)
IP11_name=$(grep -w IP11 "$data/config.txt" | cut -d ' ' -f 4-)
IP11_ip=$(grep -w IP11 "$data/config.txt" | cut -d ' ' -f 3)
IP12_name=$(grep -w IP12 "$data/config.txt" | cut -d ' ' -f 4-)
IP12_ip=$(grep -w IP12 "$data/config.txt" | cut -d ' ' -f 3)
IP13_name=$(grep -w IP13 "$data/config.txt" | cut -d ' ' -f 4-)
IP13_ip=$(grep -w IP13 "$data/config.txt" | cut -d ' ' -f 3)
IP14_name=$(grep -w IP14 "$data/config.txt" | cut -d ' ' -f 4-)
IP14_ip=$(grep -w IP14 "$data/config.txt" | cut -d ' ' -f 3)
IP15_name=$(grep -w IP15 "$data/config.txt" | cut -d ' ' -f 4-)
IP15_ip=$(grep -w IP15 "$data/config.txt" | cut -d ' ' -f 3)
IP16_name=$(grep -w IP16 "$data/config.txt" | cut -d ' ' -f 4-)
IP16_ip=$(grep -w IP16 "$data/config.txt" | cut -d ' ' -f 3)
IP17_name=$(grep -w IP17 "$data/config.txt" | cut -d ' ' -f 4-)
IP17_ip=$(grep -w IP17 "$data/config.txt" | cut -d ' ' -f 3)
IP18_name=$(grep -w IP18 "$data/config.txt" | cut -d ' ' -f 4-)
IP18_ip=$(grep -w IP18 "$data/config.txt" | cut -d ' ' -f 3)
IP19_name=$(grep -w IP19 "$data/config.txt" | cut -d ' ' -f 4-)
IP19_ip=$(grep -w IP19 "$data/config.txt" | cut -d ' ' -f 3)
IP20_name=$(grep -w IP20 "$data/config.txt" | cut -d ' ' -f 4-)
IP20_ip=$(grep -w IP20 "$data/config.txt" | cut -d ' ' -f 3)
IP21_name=$(grep -w IP21 "$data/config.txt" | cut -d ' ' -f 4-)
IP21_ip=$(grep -w IP21 "$data/config.txt" | cut -d ' ' -f 3)
IP22_name=$(grep -w IP22 "$data/config.txt" | cut -d ' ' -f 4-)
IP22_ip=$(grep -w IP22 "$data/config.txt" | cut -d ' ' -f 3)
IP23_name=$(grep -w IP23 "$data/config.txt" | cut -d ' ' -f 4-)
IP23_ip=$(grep -w IP23 "$data/config.txt" | cut -d ' ' -f 3)
IP24_name=$(grep -w IP24 "$data/config.txt" | cut -d ' ' -f 4-)
IP24_ip=$(grep -w IP24 "$data/config.txt" | cut -d ' ' -f 3)
IP25_name=$(grep -w IP25 "$data/config.txt" | cut -d ' ' -f 4-)
IP25_ip=$(grep -w IP25 "$data/config.txt" | cut -d ' ' -f 3)
crontab=$(grep -w crontab "$data/config.txt" | cut -d ' ' -f 3-)
aktiv=$(grep -w aktiv "$data/config.txt" | cut -d ' ' -f 3)
verzoegerung=$(grep -w verzögerung "$data/config.txt" | cut -d ' ' -f 3)
tage=$(grep -w tage "$data/config.txt" | cut -d ' ' -f 3)

if [ "$aktiv" = "1" ]; then
	echo "Zeitplan aktiviert, Aufrufen auch per Crontab möglich."
	crontab -l 2>/dev/null; echo "$crontab" | crontab -
else
	echo "Zeitplan deaktiviert, nur manuelles Aufrufen möglich."
	crontab -l 2>/dev/null; echo "" | crontab -
fi

if [ "$aktiv" = "2" ]; then
	echo "Permanent-Modus aktiviert, Zeitplan deaktiviert."
	echo "Zum Deaktivieren in der Config bei aktiv den Schalter setzen."
	crontab -l 2>/dev/null; echo "" | crontab -
fi

echo "Fertig."
echo ""
echo "----- $zeitstempel -----"
echo ""

if [ "$benachrichtigung" = "email" ] && [ -f "$data/ssmtp.conf" ]; then
	echo ""
	echo "Fehler! Du hast die E-Mail-Konfigurationsdatei vergessen zu verschieben."
	echo "Bitte nachholen - ansonsten kann keine E-Mail gesendet werden."
	echo "Du findest sie dann hier: $data/ssmtp.conf,"
	echo "diese muss dann als root (sudo) nach /etc/ssmtp/ssmtp.conf verschoben werden."
	sleep 3
	exit
fi

#
#	888888888888
#	     88                           ,d
#	     88                           88
#	     88   ,adPPYba,  ,adPPYba,  MM88MMM
#	     88  a8P_____88  I8[    ""    88
#	     88  8PP"""""""   `"Y8ba,     88
#	     88  "8b,   ,aa  aa    ]8I    88,
#	     88   `"Ybbd8"'  `"YbbdP"'    "Y888
#

if ping -w $ping_main_w -c $ping_main_c $ipping > /dev/null; then

	if [ -f "$data/offlog.txt" ]; then
		offlog=$(cat "$data/offlog.txt" | head -n1 | tail -n1)
		if [ "benachrichtigung" = "telegram" ]; then
			curl -s --data "text=$offlog" --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
		else
			cat "$data/offlog.txt" | mail -s "server: Neue Meldung: Hauptnetz" $email_master
		fi
		rm "$data/offlog.txt"
	fi
#01
	if [ ! -z "$IP01_ip" ]; then
		if [ ! -f "$data/ipfail/$IP01_ip-R1" ] && [ ! -f "$data/ipfail/$IP01_ip-R2" ]; then
			if ping -w $ping_dev_w -c $ping_dev_c $IP01_ip > /dev/null; then
				echo "✓ ONLINE: Gerät $IP01_name ($IP01_ip) ist online."
			else
				echo "✘ AUSFALL / STÖRUNG: Gerät $IP01_name ($IP01_ip) ist ausgefallen."
				touch "$data/ipfail/$IP01_ip-R1"
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✘ AUSFALL / STÖRUNG: $IP01_name ($IP01_ip) ist ausgefallen." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✘ AUSFALL / STÖRUNG: $IP01_name ($IP01_ip) ist ausgefallen." >> "$data/email.txt"
				fi
			fi
		else
			if ping -w $ping_dev_w -c $ping_dev_c $IP01_ip > /dev/null; then
				echo "✓ WIEDER ONLINE: Gerät $IP01_name ($IP01_ip) wieder erreichbar."
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✓ WIEDER ONLINE: $IP01_name ($IP01_ip) ist wieder online." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✓ WIEDER ONLINE: $IP01_name ($IP01_ip) wieder erreichbar." >> "$data/email.txt"
				fi
				if [ -f "$data/ipfail/$IP01_ip-R2" ]; then
					rm "$data/ipfail/$IP01_ip-R2"
				else
					rm "$data/ipfail/$IP01_ip-R1"
				fi
			else
				echo "✘ OFFLINE: Gerät $IP01_name ($IP01_ip) ist weiterhin offline."
				if [ -f "$data/ipfail/$IP01_ip-R1" ]; then
					mv "$data/ipfail/$IP01_ip-R1" "$data/ipfail/$IP01_ip-R2"
				fi
			fi
		fi
	fi
#02
	if [ ! -z "$IP02_ip" ]; then
		if [ ! -f "$data/ipfail/$IP02_ip-R1" ] && [ ! -f "$data/ipfail/$IP02_ip-R2" ]; then
			if ping -w $ping_dev_w -c $ping_dev_c $IP02_ip > /dev/null; then
				echo "✓ ONLINE: Gerät $IP02_name ($IP02_ip) ist online."
			else
				echo "✘ AUSFALL / STÖRUNG: Gerät $IP02_name ($IP02_ip) ist ausgefallen."
				touch "$data/ipfail/$IP02_ip-R1"
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✘ AUSFALL / STÖRUNG: $IP02_name ($IP02_ip) ist ausgefallen." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✘ AUSFALL / STÖRUNG: $IP02_name ($IP02_ip) ist ausgefallen." >> "$data/email.txt"
				fi
			fi
		else
			if ping -w $ping_dev_w -c $ping_dev_c $IP02_ip > /dev/null; then
				echo "✓ WIEDER ONLINE: Gerät $IP02_name ($IP02_ip) wieder erreichbar."
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✓ WIEDER ONLINE: $IP02_name ($IP02_ip) ist wieder online." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✓ WIEDER ONLINE: $IP02_name ($IP02_ip) wieder erreichbar." >> "$data/email.txt"
				fi
				if [ -f "$data/ipfail/$IP02_ip-R2" ]; then
					rm "$data/ipfail/$IP02_ip-R2"
				else
					rm "$data/ipfail/$IP02_ip-R1"
				fi
			else
				echo "✘ OFFLINE: Gerät $IP02_name ($IP02_ip) ist weiterhin offline."
				if [ -f "$data/ipfail/$IP02_ip-R1" ]; then
					mv "$data/ipfail/$IP02_ip-R1" "$data/ipfail/$IP02_ip-R2"
				fi
			fi
		fi
	fi
#03
	if [ ! -z "$IP03_ip" ]; then
		if [ ! -f "$data/ipfail/$IP03_ip-R1" ] && [ ! -f "$data/ipfail/$IP03_ip-R2" ]; then
			if ping -w $ping_dev_w -c $ping_dev_c $IP03_ip > /dev/null; then
				echo "✓ ONLINE: Gerät $IP03_name ($IP03_ip) ist online."
			else
				echo "✘ AUSFALL / STÖRUNG: Gerät $IP03_name ($IP03_ip) ist ausgefallen."
				touch "$data/ipfail/$IP03_ip-R1"
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✘ AUSFALL / STÖRUNG: $IP03_name ($IP03_ip) ist ausgefallen." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✘ AUSFALL / STÖRUNG: $IP03_name ($IP03_ip) ist ausgefallen." >> "$data/email.txt"
				fi
			fi
		else
			if ping -w $ping_dev_w -c $ping_dev_c $IP03_ip > /dev/null; then
				echo "✓ WIEDER ONLINE: Gerät $IP03_name ($IP03_ip) wieder erreichbar."
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✓ WIEDER ONLINE: $IP03_name ($IP03_ip) ist wieder online." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✓ WIEDER ONLINE: $IP03_name ($IP03_ip) wieder erreichbar." >> "$data/email.txt"
				fi
				if [ -f "$data/ipfail/$IP03_ip-R2" ]; then
					rm "$data/ipfail/$IP03_ip-R2"
				else
					rm "$data/ipfail/$IP03_ip-R1"
				fi
			else
				echo "✘ OFFLINE: Gerät $IP03_name ($IP03_ip) ist weiterhin offline."
				if [ -f "$data/ipfail/$IP03_ip-R1" ]; then
					mv "$data/ipfail/$IP03_ip-R1" "$data/ipfail/$IP03_ip-R2"
				fi
			fi
		fi
	fi
#04
	if [ ! -z "$IP04_ip" ]; then
		if [ ! -f "$data/ipfail/$IP04_ip-R1" ] && [ ! -f "$data/ipfail/$IP04_ip-R2" ]; then
			if ping -w $ping_dev_w -c $ping_dev_c $IP04_ip > /dev/null; then
				echo "✓ ONLINE: Gerät $IP04_name ($IP04_ip) ist online."
			else
				echo "✘ AUSFALL / STÖRUNG: Gerät $IP04_name ($IP04_ip) ist ausgefallen."
				touch "$data/ipfail/$IP04_ip-R1"
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✘ AUSFALL / STÖRUNG: $IP04_name ($IP04_ip) ist ausgefallen." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✘ AUSFALL / STÖRUNG: $IP04_name ($IP04_ip) ist ausgefallen." >> "$data/email.txt"
				fi
			fi
		else
			if ping -w $ping_dev_w -c $ping_dev_c $IP04_ip > /dev/null; then
				echo "✓ WIEDER ONLINE: Gerät $IP04_name ($IP04_ip) wieder erreichbar."
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✓ WIEDER ONLINE: $IP04_name ($IP04_ip) ist wieder online." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✓ WIEDER ONLINE: $IP04_name ($IP04_ip) wieder erreichbar." >> "$data/email.txt"
				fi
				if [ -f "$data/ipfail/$IP04_ip-R2" ]; then
					rm "$data/ipfail/$IP04_ip-R2"
				else
					rm "$data/ipfail/$IP04_ip-R1"
				fi
			else
				echo "✘ OFFLINE: Gerät $IP04_name ($IP04_ip) ist weiterhin offline."
				if [ -f "$data/ipfail/$IP04_ip-R1" ]; then
					mv "$data/ipfail/$IP04_ip-R1" "$data/ipfail/$IP04_ip-R2"
				fi
			fi
		fi
	fi
#05
	if [ ! -z "$IP05_ip" ]; then
		if [ ! -f "$data/ipfail/$IP05_ip-R1" ] && [ ! -f "$data/ipfail/$IP05_ip-R2" ]; then
			if ping -w $ping_dev_w -c $ping_dev_c $IP05_ip > /dev/null; then
				echo "✓ ONLINE: Gerät $IP05_name ($IP05_ip) ist online."
			else
				echo "✘ AUSFALL / STÖRUNG: Gerät $IP05_name ($IP05_ip) ist ausgefallen."
				touch "$data/ipfail/$IP05_ip-R1"
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✘ AUSFALL / STÖRUNG: $IP05_name ($IP05_ip) ist ausgefallen." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✘ AUSFALL / STÖRUNG: $IP05_name ($IP05_ip) ist ausgefallen." >> "$data/email.txt"
				fi
			fi
		else
			if ping -w $ping_dev_w -c $ping_dev_c $IP05_ip > /dev/null; then
				echo "✓ WIEDER ONLINE: Gerät $IP05_name ($IP05_ip) wieder erreichbar."
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✓ WIEDER ONLINE: $IP05_name ($IP05_ip) ist wieder online." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✓ WIEDER ONLINE: $IP05_name ($IP05_ip) wieder erreichbar." >> "$data/email.txt"
				fi
				if [ -f "$data/ipfail/$IP05_ip-R2" ]; then
					rm "$data/ipfail/$IP05_ip-R2"
				else
					rm "$data/ipfail/$IP05_ip-R1"
				fi
			else
				echo "✘ OFFLINE: Gerät $IP05_name ($IP05_ip) ist weiterhin offline."
				if [ -f "$data/ipfail/$IP05_ip-R1" ]; then
					mv "$data/ipfail/$IP05_ip-R1" "$data/ipfail/$IP05_ip-R2"
				fi
			fi
		fi
	fi
#06
	if [ ! -z "$IP06_ip" ]; then
		if [ ! -f "$data/ipfail/$IP06_ip-R1" ] && [ ! -f "$data/ipfail/$IP06_ip-R2" ]; then
			if ping -w $ping_dev_w -c $ping_dev_c $IP06_ip > /dev/null; then
				echo "✓ ONLINE: Gerät $IP06_name ($IP06_ip) ist online."
			else
				echo "✘ AUSFALL / STÖRUNG: Gerät $IP06_name ($IP06_ip) ist ausgefallen."
				touch "$data/ipfail/$IP06_ip-R1"
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✘ AUSFALL / STÖRUNG: $IP06_name ($IP06_ip) ist ausgefallen." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✘ AUSFALL / STÖRUNG: $IP06_name ($IP06_ip) ist ausgefallen." >> "$data/email.txt"
				fi
			fi
		else
			if ping -w $ping_dev_w -c $ping_dev_c $IP06_ip > /dev/null; then
				echo "✓ WIEDER ONLINE: Gerät $IP06_name ($IP06_ip) wieder erreichbar."
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✓ WIEDER ONLINE: $IP06_name ($IP06_ip) ist wieder online." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✓ WIEDER ONLINE: $IP06_name ($IP06_ip) wieder erreichbar." >> "$data/email.txt"
				fi
				if [ -f "$data/ipfail/$IP06_ip-R2" ]; then
					rm "$data/ipfail/$IP06_ip-R2"
				else
					rm "$data/ipfail/$IP06_ip-R1"
				fi
			else
				echo "✘ OFFLINE: Gerät $IP06_name ($IP06_ip) ist weiterhin offline."
				if [ -f "$data/ipfail/$IP06_ip-R1" ]; then
					mv "$data/ipfail/$IP06_ip-R1" "$data/ipfail/$IP06_ip-R2"
				fi
			fi
		fi
	fi
#07
	if [ ! -z "$IP07_ip" ]; then
		if [ ! -f "$data/ipfail/$IP07_ip-R1" ] && [ ! -f "$data/ipfail/$IP07_ip-R2" ]; then
			if ping -w $ping_dev_w -c $ping_dev_c $IP07_ip > /dev/null; then
				echo "✓ ONLINE: Gerät $IP07_name ($IP07_ip) ist online."
			else
				echo "✘ AUSFALL / STÖRUNG: Gerät $IP07_name ($IP07_ip) ist ausgefallen."
				touch "$data/ipfail/$IP07_ip-R1"
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✘ AUSFALL / STÖRUNG: $IP07_name ($IP07_ip) ist ausgefallen." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✘ AUSFALL / STÖRUNG: $IP07_name ($IP07_ip) ist ausgefallen." >> "$data/email.txt"
				fi
			fi
		else
			if ping -w $ping_dev_w -c $ping_dev_c $IP07_ip > /dev/null; then
				echo "✓ WIEDER ONLINE: Gerät $IP07_name ($IP07_ip) wieder erreichbar."
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✓ WIEDER ONLINE: $IP07_name ($IP07_ip) ist wieder online." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✓ WIEDER ONLINE: $IP07_name ($IP07_ip) wieder erreichbar." >> "$data/email.txt"
				fi
				if [ -f "$data/ipfail/$IP07_ip-R2" ]; then
					rm "$data/ipfail/$IP07_ip-R2"
				else
					rm "$data/ipfail/$IP07_ip-R1"
				fi
			else
				echo "✘ OFFLINE: Gerät $IP07_name ($IP07_ip) ist weiterhin offline."
				if [ -f "$data/ipfail/$IP07_ip-R1" ]; then
					mv "$data/ipfail/$IP07_ip-R1" "$data/ipfail/$IP07_ip-R2"
				fi
			fi
		fi
	fi
#08
	if [ ! -z "$IP08_ip" ]; then
		if [ ! -f "$data/ipfail/$IP08_ip-R1" ] && [ ! -f "$data/ipfail/$IP08_ip-R2" ]; then
			if ping -w $ping_dev_w -c $ping_dev_c $IP08_ip > /dev/null; then
				echo "✓ ONLINE: Gerät $IP08_name ($IP08_ip) ist online."
			else
				echo "✘ AUSFALL / STÖRUNG: Gerät $IP08_name ($IP08_ip) ist ausgefallen."
				touch "$data/ipfail/$IP08_ip-R1"
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✘ AUSFALL / STÖRUNG: $IP08_name ($IP08_ip) ist ausgefallen." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✘ AUSFALL / STÖRUNG: $IP08_name ($IP08_ip) ist ausgefallen." >> "$data/email.txt"
				fi
			fi
		else
			if ping -w $ping_dev_w -c $ping_dev_c $IP08_ip > /dev/null; then
				echo "✓ WIEDER ONLINE: Gerät $IP08_name ($IP08_ip) wieder erreichbar."
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✓ WIEDER ONLINE: $IP08_name ($IP08_ip) ist wieder online." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✓ WIEDER ONLINE: $IP08_name ($IP08_ip) wieder erreichbar." >> "$data/email.txt"
				fi
				if [ -f "$data/ipfail/$IP08_ip-R2" ]; then
					rm "$data/ipfail/$IP08_ip-R2"
				else
					rm "$data/ipfail/$IP08_ip-R1"
				fi
			else
				echo "✘ OFFLINE: Gerät $IP08_name ($IP08_ip) ist weiterhin offline."
				if [ -f "$data/ipfail/$IP08_ip-R1" ]; then
					mv "$data/ipfail/$IP08_ip-R1" "$data/ipfail/$IP08_ip-R2"
				fi
			fi
		fi
	fi
#09
	if [ ! -z "$IP09_ip" ]; then
		if [ ! -f "$data/ipfail/$IP09_ip-R1" ] && [ ! -f "$data/ipfail/$IP09_ip-R2" ]; then
			if ping -w $ping_dev_w -c $ping_dev_c $IP09_ip > /dev/null; then
				echo "✓ ONLINE: Gerät $IP09_name ($IP09_ip) ist online."
			else
				echo "✘ AUSFALL / STÖRUNG: Gerät $IP09_name ($IP09_ip) ist ausgefallen."
				touch "$data/ipfail/$IP09_ip-R1"
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✘ AUSFALL / STÖRUNG: $IP09_name ($IP09_ip) ist ausgefallen." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✘ AUSFALL / STÖRUNG: $IP09_name ($IP09_ip) ist ausgefallen." >> "$data/email.txt"
				fi
			fi
		else
			if ping -w $ping_dev_w -c $ping_dev_c $IP09_ip > /dev/null; then
				echo "✓ WIEDER ONLINE: Gerät $IP09_name ($IP09_ip) wieder erreichbar."
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✓ WIEDER ONLINE: $IP09_name ($IP09_ip) ist wieder online." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✓ WIEDER ONLINE: $IP09_name ($IP09_ip) wieder erreichbar." >> "$data/email.txt"
				fi
				if [ -f "$data/ipfail/$IP09_ip-R2" ]; then
					rm "$data/ipfail/$IP09_ip-R2"
				else
					rm "$data/ipfail/$IP09_ip-R1"
				fi
			else
				echo "✘ OFFLINE: Gerät $IP09_name ($IP09_ip) ist weiterhin offline."
				if [ -f "$data/ipfail/$IP09_ip-R1" ]; then
					mv "$data/ipfail/$IP09_ip-R1" "$data/ipfail/$IP09_ip-R2"
				fi
			fi
		fi
	fi
#10
	if [ ! -z "$IP10_ip" ]; then
		if [ ! -f "$data/ipfail/$IP10_ip-R1" ] && [ ! -f "$data/ipfail/$IP10_ip-R2" ]; then
			if ping -w $ping_dev_w -c $ping_dev_c $IP10_ip > /dev/null; then
				echo "✓ ONLINE: Gerät $IP10_name ($IP10_ip) ist online."
			else
				echo "✘ AUSFALL / STÖRUNG: Gerät $IP10_name ($IP10_ip) ist ausgefallen."
				touch "$data/ipfail/$IP10_ip-R1"
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✘ AUSFALL / STÖRUNG: $IP10_name ($IP10_ip) ist ausgefallen." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✘ AUSFALL / STÖRUNG: $IP10_name ($IP10_ip) ist ausgefallen." >> "$data/email.txt"
				fi
			fi
		else
			if ping -w $ping_dev_w -c $ping_dev_c $IP10_ip > /dev/null; then
				echo "✓ WIEDER ONLINE: Gerät $IP10_name ($IP10_ip) wieder erreichbar."
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✓ WIEDER ONLINE: $IP10_name ($IP10_ip) ist wieder online." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✓ WIEDER ONLINE: $IP10_name ($IP10_ip) wieder erreichbar." >> "$data/email.txt"
				fi
				if [ -f "$data/ipfail/$IP10_ip-R2" ]; then
					rm "$data/ipfail/$IP10_ip-R2"
				else
					rm "$data/ipfail/$IP10_ip-R1"
				fi
			else
				echo "✘ OFFLINE: Gerät $IP10_name ($IP10_ip) ist weiterhin offline."
				if [ -f "$data/ipfail/$IP10_ip-R1" ]; then
					mv "$data/ipfail/$IP10_ip-R1" "$data/ipfail/$IP10_ip-R2"
				fi
			fi
		fi
	fi
#11
	if [ ! -z "$IP11_ip" ]; then
		if [ ! -f "$data/ipfail/$IP11_ip-R1" ] && [ ! -f "$data/ipfail/$IP11_ip-R2" ]; then
			if ping -w $ping_dev_w -c $ping_dev_c $IP11_ip > /dev/null; then
				echo "✓ ONLINE: Gerät $IP11_name ($IP11_ip) ist online."
			else
				echo "✘ AUSFALL / STÖRUNG: Gerät $IP11_name ($IP11_ip) ist ausgefallen."
				touch "$data/ipfail/$IP11_ip-R1"
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✘ AUSFALL / STÖRUNG: $IP11_name ($IP11_ip) ist ausgefallen." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✘ AUSFALL / STÖRUNG: $IP11_name ($IP11_ip) ist ausgefallen." >> "$data/email.txt"
				fi
			fi
		else
			if ping -w $ping_dev_w -c $ping_dev_c $IP11_ip > /dev/null; then
				echo "✓ WIEDER ONLINE: Gerät $IP11_name ($IP11_ip) wieder erreichbar."
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✓ WIEDER ONLINE: $IP11_name ($IP11_ip) ist wieder online." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✓ WIEDER ONLINE: $IP11_name ($IP11_ip) wieder erreichbar." >> "$data/email.txt"
				fi
				if [ -f "$data/ipfail/$IP11_ip-R2" ]; then
					rm "$data/ipfail/$IP11_ip-R2"
				else
					rm "$data/ipfail/$IP11_ip-R1"
				fi
			else
				echo "✘ OFFLINE: Gerät $IP11_name ($IP11_ip) ist weiterhin offline."
				if [ -f "$data/ipfail/$IP11_ip-R1" ]; then
					mv "$data/ipfail/$IP11_ip-R1" "$data/ipfail/$IP11_ip-R2"
				fi
			fi
		fi
	fi
#12
	if [ ! -z "$IP12_ip" ]; then
		if [ ! -f "$data/ipfail/$IP12_ip-R1" ] && [ ! -f "$data/ipfail/$IP12_ip-R2" ]; then
			if ping -w $ping_dev_w -c $ping_dev_c $IP12_ip > /dev/null; then
				echo "✓ ONLINE: Gerät $IP12_name ($IP12_ip) ist online."
			else
				echo "✘ AUSFALL / STÖRUNG: Gerät $IP12_name ($IP12_ip) ist ausgefallen."
				touch "$data/ipfail/$IP12_ip-R1"
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✘ AUSFALL / STÖRUNG: $IP12_name ($IP12_ip) ist ausgefallen." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✘ AUSFALL / STÖRUNG: $IP12_name ($IP12_ip) ist ausgefallen." >> "$data/email.txt"
				fi
			fi
		else
			if ping -w $ping_dev_w -c $ping_dev_c $IP12_ip > /dev/null; then
				echo "✓ WIEDER ONLINE: Gerät $IP12_name ($IP12_ip) wieder erreichbar."
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✓ WIEDER ONLINE: $IP12_name ($IP12_ip) ist wieder online." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✓ WIEDER ONLINE: $IP12_name ($IP12_ip) wieder erreichbar." >> "$data/email.txt"
				fi
				if [ -f "$data/ipfail/$IP12_ip-R2" ]; then
					rm "$data/ipfail/$IP12_ip-R2"
				else
					rm "$data/ipfail/$IP12_ip-R1"
				fi
			else
				echo "✘ OFFLINE: Gerät $IP12_name ($IP12_ip) ist weiterhin offline."
				if [ -f "$data/ipfail/$IP12_ip-R1" ]; then
					mv "$data/ipfail/$IP12_ip-R1" "$data/ipfail/$IP12_ip-R2"
				fi
			fi
		fi
	fi
#13
	if [ ! -z "$IP13_ip" ]; then
		if [ ! -f "$data/ipfail/$IP13_ip-R1" ] && [ ! -f "$data/ipfail/$IP13_ip-R2" ]; then
			if ping -w $ping_dev_w -c $ping_dev_c $IP13_ip > /dev/null; then
				echo "✓ ONLINE: Gerät $IP13_name ($IP13_ip) ist online."
			else
				echo "✘ AUSFALL / STÖRUNG: Gerät $IP13_name ($IP13_ip) ist ausgefallen."
				touch "$data/ipfail/$IP13_ip-R1"
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✘ AUSFALL / STÖRUNG: $IP13_name ($IP13_ip) ist ausgefallen." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✘ AUSFALL / STÖRUNG: $IP13_name ($IP13_ip) ist ausgefallen." >> "$data/email.txt"
				fi
			fi
		else
			if ping -w $ping_dev_w -c $ping_dev_c $IP13_ip > /dev/null; then
				echo "✓ WIEDER ONLINE: Gerät $IP13_name ($IP13_ip) wieder erreichbar."
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✓ WIEDER ONLINE: $IP13_name ($IP13_ip) ist wieder online." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✓ WIEDER ONLINE: $IP13_name ($IP13_ip) wieder erreichbar." >> "$data/email.txt"
				fi
				if [ -f "$data/ipfail/$IP13_ip-R2" ]; then
					rm "$data/ipfail/$IP13_ip-R2"
				else
					rm "$data/ipfail/$IP13_ip-R1"
				fi
			else
				echo "✘ OFFLINE: Gerät $IP13_name ($IP13_ip) ist weiterhin offline."
				if [ -f "$data/ipfail/$IP13_ip-R1" ]; then
					mv "$data/ipfail/$IP13_ip-R1" "$data/ipfail/$IP13_ip-R2"
				fi
			fi
		fi
	fi
#14
	if [ ! -z "$IP14_ip" ]; then
		if [ ! -f "$data/ipfail/$IP14_ip-R1" ] && [ ! -f "$data/ipfail/$IP14_ip-R2" ]; then
			if ping -w $ping_dev_w -c $ping_dev_c $IP14_ip > /dev/null; then
				echo "✓ ONLINE: Gerät $IP14_name ($IP14_ip) ist online."
			else
				echo "✘ AUSFALL / STÖRUNG: Gerät $IP14_name ($IP14_ip) ist ausgefallen."
				touch "$data/ipfail/$IP14_ip-R1"
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✘ AUSFALL / STÖRUNG: $IP14_name ($IP14_ip) ist ausgefallen." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✘ AUSFALL / STÖRUNG: $IP14_name ($IP14_ip) ist ausgefallen." >> "$data/email.txt"
				fi
			fi
		else
			if ping -w $ping_dev_w -c $ping_dev_c $IP14_ip > /dev/null; then
				echo "✓ WIEDER ONLINE: Gerät $IP14_name ($IP14_ip) wieder erreichbar."
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✓ WIEDER ONLINE: $IP14_name ($IP14_ip) ist wieder online." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✓ WIEDER ONLINE: $IP14_name ($IP14_ip) wieder erreichbar." >> "$data/email.txt"
				fi
				if [ -f "$data/ipfail/$IP14_ip-R2" ]; then
					rm "$data/ipfail/$IP14_ip-R2"
				else
					rm "$data/ipfail/$IP14_ip-R1"
				fi
			else
				echo "✘ OFFLINE: Gerät $IP14_name ($IP14_ip) ist weiterhin offline."
				if [ -f "$data/ipfail/$IP14_ip-R1" ]; then
					mv "$data/ipfail/$IP14_ip-R1" "$data/ipfail/$IP14_ip-R2"
				fi
			fi
		fi
	fi
#15
	if [ ! -z "$IP15_ip" ]; then
		if [ ! -f "$data/ipfail/$IP15_ip-R1" ] && [ ! -f "$data/ipfail/$IP15_ip-R2" ]; then
			if ping -w $ping_dev_w -c $ping_dev_c $IP15_ip > /dev/null; then
				echo "✓ ONLINE: Gerät $IP15_name ($IP15_ip) ist online."
			else
				echo "✘ AUSFALL / STÖRUNG: Gerät $IP15_name ($IP15_ip) ist ausgefallen."
				touch "$data/ipfail/$IP15_ip-R1"
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✘ AUSFALL / STÖRUNG: $IP15_name ($IP15_ip) ist ausgefallen." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✘ AUSFALL / STÖRUNG: $IP15_name ($IP15_ip) ist ausgefallen." >> "$data/email.txt"
				fi
			fi
		else
			if ping -w $ping_dev_w -c $ping_dev_c $IP15_ip > /dev/null; then
				echo "✓ WIEDER ONLINE: Gerät $IP15_name ($IP15_ip) wieder erreichbar."
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✓ WIEDER ONLINE: $IP15_name ($IP15_ip) ist wieder online." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✓ WIEDER ONLINE: $IP15_name ($IP15_ip) wieder erreichbar." >> "$data/email.txt"
				fi
				if [ -f "$data/ipfail/$IP15_ip-R2" ]; then
					rm "$data/ipfail/$IP15_ip-R2"
				else
					rm "$data/ipfail/$IP15_ip-R1"
				fi
			else
				echo "✘ OFFLINE: Gerät $IP15_name ($IP15_ip) ist weiterhin offline."
				if [ -f "$data/ipfail/$IP15_ip-R1" ]; then
					mv "$data/ipfail/$IP15_ip-R1" "$data/ipfail/$IP15_ip-R2"
				fi
			fi
		fi
	fi
#16
	if [ ! -z "$IP16_ip" ]; then
		if [ ! -f "$data/ipfail/$IP16_ip-R1" ] && [ ! -f "$data/ipfail/$IP16_ip-R2" ]; then
			if ping -w $ping_dev_w -c $ping_dev_c $IP16_ip > /dev/null; then
				echo "✓ ONLINE: Gerät $IP16_name ($IP16_ip) ist online."
			else
				echo "✘ AUSFALL / STÖRUNG: Gerät $IP16_name ($IP16_ip) ist ausgefallen."
				touch "$data/ipfail/$IP16_ip-R1"
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✘ AUSFALL / STÖRUNG: $IP16_name ($IP16_ip) ist ausgefallen." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✘ AUSFALL / STÖRUNG: $IP16_name ($IP16_ip) ist ausgefallen." >> "$data/email.txt"
				fi
			fi
		else
			if ping -w $ping_dev_w -c $ping_dev_c $IP16_ip > /dev/null; then
				echo "✓ WIEDER ONLINE: Gerät $IP16_name ($IP16_ip) wieder erreichbar."
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✓ WIEDER ONLINE: $IP16_name ($IP16_ip) ist wieder online." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✓ WIEDER ONLINE: $IP16_name ($IP16_ip) wieder erreichbar." >> "$data/email.txt"
				fi
				if [ -f "$data/ipfail/$IP16_ip-R2" ]; then
					rm "$data/ipfail/$IP16_ip-R2"
				else
					rm "$data/ipfail/$IP16_ip-R1"
				fi
			else
				echo "✘ OFFLINE: Gerät $IP16_name ($IP16_ip) ist weiterhin offline."
				if [ -f "$data/ipfail/$IP16_ip-R1" ]; then
					mv "$data/ipfail/$IP16_ip-R1" "$data/ipfail/$IP16_ip-R2"
				fi
			fi
		fi
	fi
#17
	if [ ! -z "$IP17_ip" ]; then
		if [ ! -f "$data/ipfail/$IP17_ip-R1" ] && [ ! -f "$data/ipfail/$IP17_ip-R2" ]; then
			if ping -w $ping_dev_w -c $ping_dev_c $IP17_ip > /dev/null; then
				echo "✓ ONLINE: Gerät $IP17_name ($IP17_ip) ist online."
			else
				echo "✘ AUSFALL / STÖRUNG: Gerät $IP17_name ($IP17_ip) ist ausgefallen."
				touch "$data/ipfail/$IP17_ip-R1"
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✘ AUSFALL / STÖRUNG: $IP17_name ($IP17_ip) ist ausgefallen." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✘ AUSFALL / STÖRUNG: $IP17_name ($IP17_ip) ist ausgefallen." >> "$data/email.txt"
				fi
			fi
		else
			if ping -w $ping_dev_w -c $ping_dev_c $IP17_ip > /dev/null; then
				echo "✓ WIEDER ONLINE: Gerät $IP17_name ($IP17_ip) wieder erreichbar."
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✓ WIEDER ONLINE: $IP17_name ($IP17_ip) ist wieder online." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✓ WIEDER ONLINE: $IP17_name ($IP17_ip) wieder erreichbar." >> "$data/email.txt"
				fi
				if [ -f "$data/ipfail/$IP17_ip-R2" ]; then
					rm "$data/ipfail/$IP17_ip-R2"
				else
					rm "$data/ipfail/$IP17_ip-R1"
				fi
			else
				echo "✘ OFFLINE: Gerät $IP17_name ($IP17_ip) ist weiterhin offline."
				if [ -f "$data/ipfail/$IP17_ip-R1" ]; then
					mv "$data/ipfail/$IP17_ip-R1" "$data/ipfail/$IP17_ip-R2"
				fi
			fi
		fi
	fi
#18
	if [ ! -z "$IP18_ip" ]; then
		if [ ! -f "$data/ipfail/$IP18_ip-R1" ] && [ ! -f "$data/ipfail/$IP18_ip-R2" ]; then
			if ping -w $ping_dev_w -c $ping_dev_c $IP18_ip > /dev/null; then
				echo "✓ ONLINE: Gerät $IP18_name ($IP18_ip) ist online."
			else
				echo "✘ AUSFALL / STÖRUNG: Gerät $IP18_name ($IP18_ip) ist ausgefallen."
				touch "$data/ipfail/$IP18_ip-R1"
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✘ AUSFALL / STÖRUNG: $IP18_name ($IP18_ip) ist ausgefallen." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✘ AUSFALL / STÖRUNG: $IP18_name ($IP18_ip) ist ausgefallen." >> "$data/email.txt"
				fi
			fi
		else
			if ping -w $ping_dev_w -c $ping_dev_c $IP18_ip > /dev/null; then
				echo "✓ WIEDER ONLINE: Gerät $IP18_name ($IP18_ip) wieder erreichbar."
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✓ WIEDER ONLINE: $IP18_name ($IP18_ip) ist wieder online." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✓ WIEDER ONLINE: $IP18_name ($IP18_ip) wieder erreichbar." >> "$data/email.txt"
				fi
				if [ -f "$data/ipfail/$IP18_ip-R2" ]; then
					rm "$data/ipfail/$IP18_ip-R2"
				else
					rm "$data/ipfail/$IP18_ip-R1"
				fi
			else
				echo "✘ OFFLINE: Gerät $IP18_name ($IP18_ip) ist weiterhin offline."
				if [ -f "$data/ipfail/$IP18_ip-R1" ]; then
					mv "$data/ipfail/$IP18_ip-R1" "$data/ipfail/$IP18_ip-R2"
				fi
			fi
		fi
	fi
#19
	if [ ! -z "$IP19_ip" ]; then
		if [ ! -f "$data/ipfail/$IP19_ip-R1" ] && [ ! -f "$data/ipfail/$IP19_ip-R2" ]; then
			if ping -w $ping_dev_w -c $ping_dev_c $IP19_ip > /dev/null; then
				echo "✓ ONLINE: Gerät $IP19_name ($IP19_ip) ist online."
			else
				echo "✘ AUSFALL / STÖRUNG: Gerät $IP19_name ($IP19_ip) ist ausgefallen."
				touch "$data/ipfail/$IP19_ip-R1"
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✘ AUSFALL / STÖRUNG: $IP19_name ($IP19_ip) ist ausgefallen." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✘ AUSFALL / STÖRUNG: $IP19_name ($IP19_ip) ist ausgefallen." >> "$data/email.txt"
				fi
			fi
		else
			if ping -w $ping_dev_w -c $ping_dev_c $IP19_ip > /dev/null; then
				echo "✓ WIEDER ONLINE: Gerät $IP19_name ($IP19_ip) wieder erreichbar."
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✓ WIEDER ONLINE: $IP19_name ($IP19_ip) ist wieder online." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✓ WIEDER ONLINE: $IP19_name ($IP19_ip) wieder erreichbar." >> "$data/email.txt"
				fi
				if [ -f "$data/ipfail/$IP19_ip-R2" ]; then
					rm "$data/ipfail/$IP19_ip-R2"
				else
					rm "$data/ipfail/$IP19_ip-R1"
				fi
			else
				echo "✘ OFFLINE: Gerät $IP19_name ($IP19_ip) ist weiterhin offline."
				if [ -f "$data/ipfail/$IP19_ip-R1" ]; then
					mv "$data/ipfail/$IP19_ip-R1" "$data/ipfail/$IP19_ip-R2"
				fi
			fi
		fi
	fi
#20
	if [ ! -z "$IP20_ip" ]; then
		if [ ! -f "$data/ipfail/$IP20_ip-R1" ] && [ ! -f "$data/ipfail/$IP20_ip-R2" ]; then
			if ping -w $ping_dev_w -c $ping_dev_c $IP20_ip > /dev/null; then
				echo "✓ ONLINE: Gerät $IP20_name ($IP20_ip) ist online."
			else
				echo "✘ AUSFALL / STÖRUNG: Gerät $IP20_name ($IP20_ip) ist ausgefallen."
				touch "$data/ipfail/$IP20_ip-R1"
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✘ AUSFALL / STÖRUNG: $IP20_name ($IP20_ip) ist ausgefallen." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✘ AUSFALL / STÖRUNG: $IP20_name ($IP20_ip) ist ausgefallen." >> "$data/email.txt"
				fi
			fi
		else
			if ping -w $ping_dev_w -c $ping_dev_c $IP20_ip > /dev/null; then
				echo "✓ WIEDER ONLINE: Gerät $IP20_name ($IP20_ip) wieder erreichbar."
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✓ WIEDER ONLINE: $IP20_name ($IP20_ip) ist wieder online." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✓ WIEDER ONLINE: $IP20_name ($IP20_ip) wieder erreichbar." >> "$data/email.txt"
				fi
				if [ -f "$data/ipfail/$IP20_ip-R2" ]; then
					rm "$data/ipfail/$IP20_ip-R2"
				else
					rm "$data/ipfail/$IP20_ip-R1"
				fi
			else
				echo "✘ OFFLINE: Gerät $IP20_name ($IP20_ip) ist weiterhin offline."
				if [ -f "$data/ipfail/$IP20_ip-R1" ]; then
					mv "$data/ipfail/$IP20_ip-R1" "$data/ipfail/$IP20_ip-R2"
				fi
			fi
		fi
	fi
#21
	if [ ! -z "$IP21_ip" ]; then
		if [ ! -f "$data/ipfail/$IP21_ip-R1" ] && [ ! -f "$data/ipfail/$IP21_ip-R2" ]; then
			if ping -w $ping_dev_w -c $ping_dev_c $IP21_ip > /dev/null; then
				echo "✓ ONLINE: Gerät $IP21_name ($IP21_ip) ist online."
			else
				echo "✘ AUSFALL / STÖRUNG: Gerät $IP21_name ($IP21_ip) ist ausgefallen."
				touch "$data/ipfail/$IP21_ip-R1"
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✘ AUSFALL / STÖRUNG: $IP21_name ($IP21_ip) ist ausgefallen." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✘ AUSFALL / STÖRUNG: $IP21_name ($IP21_ip) ist ausgefallen." >> "$data/email.txt"
				fi
			fi
		else
			if ping -w $ping_dev_w -c $ping_dev_c $IP21_ip > /dev/null; then
				echo "✓ WIEDER ONLINE: Gerät $IP21_name ($IP21_ip) wieder erreichbar."
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✓ WIEDER ONLINE: $IP21_name ($IP21_ip) ist wieder online." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✓ WIEDER ONLINE: $IP21_name ($IP21_ip) wieder erreichbar." >> "$data/email.txt"
				fi
				if [ -f "$data/ipfail/$IP21_ip-R2" ]; then
					rm "$data/ipfail/$IP21_ip-R2"
				else
					rm "$data/ipfail/$IP21_ip-R1"
				fi
			else
				echo "✘ OFFLINE: Gerät $IP21_name ($IP21_ip) ist weiterhin offline."
				if [ -f "$data/ipfail/$IP21_ip-R1" ]; then
					mv "$data/ipfail/$IP21_ip-R1" "$data/ipfail/$IP21_ip-R2"
				fi
			fi
		fi
	fi
#22
	if [ ! -z "$IP22_ip" ]; then
		if [ ! -f "$data/ipfail/$IP22_ip-R1" ] && [ ! -f "$data/ipfail/$IP22_ip-R2" ]; then
			if ping -w $ping_dev_w -c $ping_dev_c $IP22_ip > /dev/null; then
				echo "✓ ONLINE: Gerät $IP22_name ($IP22_ip) ist online."
			else
				echo "✘ AUSFALL / STÖRUNG: Gerät $IP22_name ($IP22_ip) ist ausgefallen."
				touch "$data/ipfail/$IP22_ip-R1"
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✘ AUSFALL / STÖRUNG: $IP22_name ($IP22_ip) ist ausgefallen." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✘ AUSFALL / STÖRUNG: $IP22_name ($IP22_ip) ist ausgefallen." >> "$data/email.txt"
				fi
			fi
		else
			if ping -w $ping_dev_w -c $ping_dev_c $IP22_ip > /dev/null; then
				echo "✓ WIEDER ONLINE: Gerät $IP22_name ($IP22_ip) wieder erreichbar."
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✓ WIEDER ONLINE: $IP22_name ($IP22_ip) ist wieder online." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✓ WIEDER ONLINE: $IP22_name ($IP22_ip) wieder erreichbar." >> "$data/email.txt"
				fi
				if [ -f "$data/ipfail/$IP22_ip-R2" ]; then
					rm "$data/ipfail/$IP22_ip-R2"
				else
					rm "$data/ipfail/$IP22_ip-R1"
				fi
			else
				echo "✘ OFFLINE: Gerät $IP22_name ($IP22_ip) ist weiterhin offline."
				if [ -f "$data/ipfail/$IP22_ip-R1" ]; then
					mv "$data/ipfail/$IP22_ip-R1" "$data/ipfail/$IP22_ip-R2"
				fi
			fi
		fi
	fi
#23
	if [ ! -z "$IP23_ip" ]; then
		if [ ! -f "$data/ipfail/$IP23_ip-R1" ] && [ ! -f "$data/ipfail/$IP23_ip-R2" ]; then
			if ping -w $ping_dev_w -c $ping_dev_c $IP23_ip > /dev/null; then
				echo "✓ ONLINE: Gerät $IP23_name ($IP23_ip) ist online."
			else
				echo "✘ AUSFALL / STÖRUNG: Gerät $IP23_name ($IP23_ip) ist ausgefallen."
				touch "$data/ipfail/$IP23_ip-R1"
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✘ AUSFALL / STÖRUNG: $IP23_name ($IP23_ip) ist ausgefallen." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✘ AUSFALL / STÖRUNG: $IP23_name ($IP23_ip) ist ausgefallen." >> "$data/email.txt"
				fi
			fi
		else
			if ping -w $ping_dev_w -c $ping_dev_c $IP23_ip > /dev/null; then
				echo "✓ WIEDER ONLINE: Gerät $IP23_name ($IP23_ip) wieder erreichbar."
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✓ WIEDER ONLINE: $IP23_name ($IP23_ip) ist wieder online." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✓ WIEDER ONLINE: $IP23_name ($IP23_ip) wieder erreichbar." >> "$data/email.txt"
				fi
				if [ -f "$data/ipfail/$IP23_ip-R2" ]; then
					rm "$data/ipfail/$IP23_ip-R2"
				else
					rm "$data/ipfail/$IP23_ip-R1"
				fi
			else
				echo "✘ OFFLINE: Gerät $IP23_name ($IP23_ip) ist weiterhin offline."
				if [ -f "$data/ipfail/$IP23_ip-R1" ]; then
					mv "$data/ipfail/$IP23_ip-R1" "$data/ipfail/$IP23_ip-R2"
				fi
			fi
		fi
	fi
#24
	if [ ! -z "$IP24_ip" ]; then
		if [ ! -f "$data/ipfail/$IP24_ip-R1" ] && [ ! -f "$data/ipfail/$IP24_ip-R2" ]; then
			if ping -w $ping_dev_w -c $ping_dev_c $IP24_ip > /dev/null; then
				echo "✓ ONLINE: Gerät $IP24_name ($IP24_ip) ist online."
			else
				echo "✘ AUSFALL / STÖRUNG: Gerät $IP24_name ($IP24_ip) ist ausgefallen."
				touch "$data/ipfail/$IP24_ip-R1"
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✘ AUSFALL / STÖRUNG: $IP24_name ($IP24_ip) ist ausgefallen." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✘ AUSFALL / STÖRUNG: $IP24_name ($IP24_ip) ist ausgefallen." >> "$data/email.txt"
				fi
			fi
		else
			if ping -w $ping_dev_w -c $ping_dev_c $IP24_ip > /dev/null; then
				echo "✓ WIEDER ONLINE: Gerät $IP24_name ($IP24_ip) wieder erreichbar."
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✓ WIEDER ONLINE: $IP24_name ($IP24_ip) ist wieder online." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✓ WIEDER ONLINE: $IP24_name ($IP24_ip) wieder erreichbar." >> "$data/email.txt"
				fi
				if [ -f "$data/ipfail/$IP24_ip-R2" ]; then
					rm "$data/ipfail/$IP24_ip-R2"
				else
					rm "$data/ipfail/$IP24_ip-R1"
				fi
			else
				echo "✘ OFFLINE: Gerät $IP24_name ($IP24_ip) ist weiterhin offline."
				if [ -f "$data/ipfail/$IP24_ip-R1" ]; then
					mv "$data/ipfail/$IP24_ip-R1" "$data/ipfail/$IP24_ip-R2"
				fi
			fi
		fi
	fi
#25
	if [ ! -z "$IP25_ip" ]; then
		if [ ! -f "$data/ipfail/$IP25_ip-R1" ] && [ ! -f "$data/ipfail/$IP25_ip-R2" ]; then
			if ping -w $ping_dev_w -c $ping_dev_c $IP25_ip > /dev/null; then
				echo "✓ ONLINE: Gerät $IP25_name ($IP25_ip) ist online."
			else
				echo "✘ AUSFALL / STÖRUNG: Gerät $IP25_name ($IP25_ip) ist ausgefallen."
				touch "$data/ipfail/$IP25_ip-R1"
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✘ AUSFALL / STÖRUNG: $IP25_name ($IP25_ip) ist ausgefallen." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✘ AUSFALL / STÖRUNG: $IP25_name ($IP25_ip) ist ausgefallen." >> "$data/email.txt"
				fi
			fi
		else
			if ping -w $ping_dev_w -c $ping_dev_c $IP25_ip > /dev/null; then
				echo "✓ WIEDER ONLINE: Gerät $IP25_name ($IP25_ip) wieder erreichbar."
				if [ "$benachrichtigung" = "telegram" ]; then
					curl -s --data "text=✓ WIEDER ONLINE: $IP25_name ($IP25_ip) ist wieder online." --data "chat_id=$telegram_master" 'https://api.telegram.org/bot'$telegram_bottoken'/sendMessage' > /dev/null
				else
					echo "✓ WIEDER ONLINE: $IP25_name ($IP25_ip) wieder erreichbar." >> "$data/email.txt"
				fi
				if [ -f "$data/ipfail/$IP25_ip-R2" ]; then
					rm "$data/ipfail/$IP25_ip-R2"
				else
					rm "$data/ipfail/$IP25_ip-R1"
				fi
			else
				echo "✘ OFFLINE: Gerät $IP25_name ($IP25_ip) ist weiterhin offline."
				if [ -f "$data/ipfail/$IP25_ip-R1" ]; then
					mv "$data/ipfail/$IP25_ip-R1" "$data/ipfail/$IP25_ip-R2"
				fi
			fi
		fi
	fi
#
	if [ "$benachrichtigung" = "email" ]; then
		if [ -f "$data/email.txt" ]; then
			cat "$data/email.txt" | mail -s "server: Neue Meldung: $zeitstempel" $email_master
			rm "$data/email.txt"
		fi
	fi
else
	echo "Hauptnetz offline. Notiz wird erstellt und bei Wiedererreichbarkeit gesendet."
	echo "Hauptnetz war offline. Meldung erstellt: $zeitstempel. Geht also wieder." > "$data/offlog.txt"
fi

echo ""
echo "----------------------------"

if [ "$aktiv" = "2" ]; then
	sleep "$verzoegerung"
	$0
	exit
fi

find $data/ipfail/* -mtime +$tage -type f -exec rm {} \;